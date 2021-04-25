package main

import (
	"log"
	"fmt"
	"flag"
	"time"
	"net/http"
	"github.com/pexip/lazychat/pkg/lazychat"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
	addr = flag.String("addr", ":8080", "http service address")
	httpDuration = promauto.NewHistogramVec(prometheus.HistogramOpts{
		Name: "lazychat_http_duration_seconds",
		Help: "Duration of HTTP requests.",
	}, []string{"path"})
)


func httpFuncTimer(path string, f func( http.ResponseWriter, *http.Request)){
	// track the time it takes to run functions
	startTime := time.Now()
	http.HandleFunc( path, f)
	httpDuration.WithLabelValues(path).Observe(time.Now().Sub(startTime).Seconds())
}

func serveHome(w http.ResponseWriter, r *http.Request) {
	log.Println(r.URL)
	if r.URL.Path == "/healthz" {
		fmt.Fprintf( w, "OK\n" )
		return
	}
	if r.URL.Path != "/" {
		http.Error(w, "Not found", 404)
		return
	}
	if r.Method != "GET" {
		http.Error(w, "Method not allowed", 405)
		return
	}
	http.ServeFile(w, r, "web/index.html")

}

func main() {
	flag.Parse()
	hub := lazychat.NewHub()
	go hub.Run()
	httpFuncTimer("/", serveHome)

	httpFuncTimer("/ws", func(w http.ResponseWriter, r *http.Request) {
		lazychat.ServeWs(hub, w, r)
	})
	fmt.Printf("Listening on http://localhost%s/\n", *addr)
	http.Handle("/metrics", promhttp.Handler())

	err := http.ListenAndServe(*addr, nil)
	if err != nil {
		log.Fatal("ListenAndServe: ", err)
	}
}

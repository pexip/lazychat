package lazychat

import (
	"bytes"
	"errors"
	"log"
	"math/rand"
	"net/http"
	"time"

	"github.com/gorilla/websocket"
)

const (
	writeWait      = 10 * time.Second
	pongWait       = 60 * time.Second
	pingPeriod     = (pongWait * 9) / 10
	maxMessageSize = 512

	minDelayMs       = 100
	maxDelayMs       = 1500
	pstChanceOfDelay = 25
	pstChanceOfError = 10
)

var (
	newline = []byte{'\n'}
	space   = []byte{' '}
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
}

type Client struct {
	hub  *Hub
	conn *websocket.Conn
	send chan []byte
}

func (this *Client) readPump() {
	defer func() {
		this.hub.unregister <- this
		this.conn.Close()
	}()
	this.conn.SetReadLimit(maxMessageSize)
	this.conn.SetReadDeadline(time.Now().Add(pongWait))
	this.conn.SetPongHandler(func(string) error { this.conn.SetReadDeadline(time.Now().Add(pongWait)); return nil })
	for {
		// Inject random errors and delay
		this.injectRandomDelay(minDelayMs, maxDelayMs, pstChanceOfDelay)
		err := this.injectRandomError(pstChanceOfError)
		if err != nil {
			break
		}

		_, message, err := this.conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway) {
				log.Printf("error: %v", err)
			}
			break
		}

		message = bytes.TrimSpace(bytes.Replace(message, newline, space, -1))
		this.hub.broadcast <- message
	}
}

func (this *Client) writePump() {
	ticker := time.NewTicker(pingPeriod)
	defer func() {
		ticker.Stop()
		this.conn.Close()
	}()
	for {
		select {
		case message, ok := <-this.send:
			this.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				// The hub closed the channel.
				this.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			// Inject random errors and delay
			this.injectRandomDelay(minDelayMs, maxDelayMs, pstChanceOfDelay)
			err := this.injectRandomError(pstChanceOfError)
			if err != nil {
				return
			}

			w, err := this.conn.NextWriter(websocket.TextMessage)
			if err != nil {
				return
			}
			w.Write(message)

			// Add queued chat messages to the current websocket message.
			n := len(this.send)
			for i := 0; i < n; i++ {
				w.Write(newline)
				w.Write(<-this.send)
			}

			if err := w.Close(); err != nil {
				return
			}
		case <-ticker.C:
			this.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := this.conn.WriteMessage(websocket.PingMessage, []byte{}); err != nil {
				return
			}
		}
	}
}

func (this *Client) injectRandomDelay(minDelayMs int, maxDelayMs int, pstChanceOfDelay int) {
	rand.Seed(time.Now().UnixNano())
	if rand.Intn(100) <= pstChanceOfDelay {
		delay := rand.Int31n(int32(maxDelayMs-minDelayMs)) + int32(minDelayMs)
		time.Sleep(time.Duration(delay) * time.Millisecond)
	}
}

func (this *Client) injectRandomError(pstChanceOfError int) error {
	rand.Seed(time.Now().UnixNano())
	if rand.Intn(100) <= pstChanceOfError {
		return errors.New("random error")
	}
	return nil
}

func ServeWs(hub *Hub, w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println(err)
		return
	}
	client := &Client{hub: hub, conn: conn, send: make(chan []byte, 256)}
	client.hub.register <- client

	go client.writePump()
	go client.readPump()
}

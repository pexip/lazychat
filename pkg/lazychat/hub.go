package lazychat

type Hub struct {
	clients    map[*Client]bool
	broadcast  chan []byte
	register   chan *Client
	unregister chan *Client
}

func NewHub() *Hub {
	return &Hub{
		broadcast:  make(chan []byte),
		register:   make(chan *Client),
		unregister: make(chan *Client),
		clients:    make(map[*Client]bool),
	}
}

func (this *Hub) Run() {
	for {
		select {
		case client := <-this.register:
			this.clients[client] = true
		case client := <-this.unregister:
			if _, ok := this.clients[client]; ok {
				delete(this.clients, client)
				close(client.send)
			}
		case message := <-this.broadcast:
			for client := range this.clients {
				select {
				case client.send <- message:
				default:
					close(client.send)
					delete(this.clients, client)
				}
			}
		}
	}
}

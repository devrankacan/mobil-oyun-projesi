package main

import (
	"encoding/json"
	"log"
	"net/http"

	"github.com/gorilla/websocket"

	"mobiloyun/server/game"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin:     func(r *http.Request) bool { return true },
}

func main() {
	room := game.NewRoom()
	go room.Run()

	http.HandleFunc("/ws", func(w http.ResponseWriter, r *http.Request) {
		handleWS(room, w, r)
	})

	addr := ":8080"
	log.Println("server listening on", addr)
	if err := http.ListenAndServe(addr, nil); err != nil {
		log.Fatal(err)
	}
}

func handleWS(room *game.Room, w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println("upgrade error:", err)
		return
	}
	defer conn.Close()

	name := r.URL.Query().Get("name")
	if name == "" {
		name = "Player"
	}
	id := game.NewID()
	p := game.NewPlayer(id, name)
	room.AddPlayer(p)
	defer room.RemovePlayer(id)

	welcome, _ := json.Marshal(map[string]string{"type": "welcome", "your_id": id})
	if err := conn.WriteMessage(websocket.TextMessage, welcome); err != nil {
		return
	}

	done := make(chan struct{})

	go func() {
		defer close(done)
		for {
			_, msg, err := conn.ReadMessage()
			if err != nil {
				return
			}
			var in struct {
				Type string  `json:"type"`
				DX   float64 `json:"dx"`
				DY   float64 `json:"dy"`
			}
			if err := json.Unmarshal(msg, &in); err != nil {
				continue
			}
			if in.Type == "input" {
				room.SetInput(id, in.DX, in.DY)
			}
		}
	}()

	for {
		select {
		case payload := <-p.SendChan():
			if err := conn.WriteMessage(websocket.TextMessage, payload); err != nil {
				return
			}
		case <-done:
			return
		}
	}
}

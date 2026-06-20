package game

import (
	"encoding/json"
	"log"
	"math"
	"math/rand"
	"sync"
	"time"
)

const TickRate = 30 // ticks per second

type inputMsg struct {
	Type string  `json:"type"`
	DX   float64 `json:"dx"`
	DY   float64 `json:"dy"`
}

type stateMsg struct {
	Type    string        `json:"type"`
	Players []PlayerState `json:"players"`
	Food    []Food        `json:"food"`
	YourID  string        `json:"your_id,omitempty"`
}

type Room struct {
	mu      sync.Mutex
	players map[string]*Player
	food    map[int]*Food
	nextFoodID int
}

func NewRoom() *Room {
	r := &Room{
		players: make(map[string]*Player),
		food:    make(map[int]*Food),
	}
	for i := 0; i < FoodCount; i++ {
		r.spawnFood()
	}
	return r
}

func (r *Room) spawnFood() {
	f := &Food{
		ID:  r.nextFoodID,
		Pos: Vec2{X: rand.Float64() * ArenaWidth, Y: rand.Float64() * ArenaHeight},
	}
	r.nextFoodID++
	r.food[f.ID] = f
}

func (r *Room) AddPlayer(p *Player) {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.players[p.ID] = p
}

func (r *Room) RemovePlayer(id string) {
	r.mu.Lock()
	defer r.mu.Unlock()
	delete(r.players, id)
}

func (r *Room) SetInput(id string, dx, dy float64) {
	r.mu.Lock()
	defer r.mu.Unlock()
	if p, ok := r.players[id]; ok {
		p.InputDir = Vec2{X: dx, Y: dy}
	}
}

func (r *Room) Run() {
	ticker := time.NewTicker(time.Second / TickRate)
	defer ticker.Stop()
	for range ticker.C {
		r.tick(1.0 / TickRate)
		r.broadcastState()
	}
}

func (r *Room) tick(dt float64) {
	r.mu.Lock()
	defer r.mu.Unlock()

	for _, p := range r.players {
		if !p.Alive {
			continue
		}
		d := p.InputDir
		mag := math.Hypot(d.X, d.Y)
		if mag > 0.001 {
			speed := p.Speed()
			p.Pos.X += (d.X / mag) * speed * dt
			p.Pos.Y += (d.Y / mag) * speed * dt
		}
		p.Pos.X = clamp(p.Pos.X, 0, ArenaWidth)
		p.Pos.Y = clamp(p.Pos.Y, 0, ArenaHeight)
	}

	// player vs food
	for _, p := range r.players {
		if !p.Alive {
			continue
		}
		for fid, f := range r.food {
			if dist(p.Pos, f.Pos) < p.Size {
				p.Size += GrowthPerFood
				delete(r.food, fid)
				r.spawnFood()
			}
		}
	}

	// player vs player
	for _, a := range r.players {
		if !a.Alive {
			continue
		}
		for _, b := range r.players {
			if a.ID == b.ID || !b.Alive {
				continue
			}
			if a.Size > b.Size*EatSizeRatio && dist(a.Pos, b.Pos) < a.Size {
				a.Size += b.Size * 0.5
				b.Alive = false
				go func(pl *Player) {
					time.Sleep(1 * time.Second)
					pl.Respawn()
				}(b)
			}
		}
	}
}

func (r *Room) broadcastState() {
	r.mu.Lock()
	players := make([]PlayerState, 0, len(r.players))
	for _, p := range r.players {
		players = append(players, p.State())
	}
	foods := make([]Food, 0, len(r.food))
	for _, f := range r.food {
		foods = append(foods, *f)
	}
	targets := make([]*Player, 0, len(r.players))
	for _, p := range r.players {
		targets = append(targets, p)
	}
	r.mu.Unlock()

	base := stateMsg{Type: "state", Players: players, Food: foods}
	payload, err := json.Marshal(base)
	if err != nil {
		log.Println("marshal error:", err)
		return
	}
	for _, p := range targets {
		select {
		case p.send <- payload:
		default:
			// drop if client is slow, avoid blocking the game loop
		}
	}
}

func clamp(v, min, max float64) float64 {
	if v < min {
		return min
	}
	if v > max {
		return max
	}
	return v
}

func dist(a, b Vec2) float64 {
	return math.Hypot(a.X-b.X, a.Y-b.Y)
}

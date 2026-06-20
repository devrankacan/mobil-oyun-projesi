package game

import "math/rand"

type Player struct {
	ID    string
	Name  string
	Pos   Vec2
	Size  float64
	Alive bool

	// last input direction received from client, normalized -1..1
	InputDir Vec2

	send chan []byte
}

func NewPlayer(id, name string) *Player {
	return &Player{
		ID:    id,
		Name:  name,
		Pos:   Vec2{X: rand.Float64() * ArenaWidth, Y: rand.Float64() * ArenaHeight},
		Size:  PlayerBaseSize,
		Alive: true,
		send:  make(chan []byte, 32),
	}
}

func (p *Player) State() PlayerState {
	return PlayerState{ID: p.ID, Name: p.Name, Pos: p.Pos, Size: p.Size, Alive: p.Alive}
}

func (p *Player) Respawn() {
	p.Pos = Vec2{X: rand.Float64() * ArenaWidth, Y: rand.Float64() * ArenaHeight}
	p.Size = PlayerBaseSize
	p.Alive = true
}

// speed decreases slightly as the player grows, to keep gameplay balanced.
func (p *Player) Speed() float64 {
	return PlayerBaseSpeed*(PlayerBaseSize/p.Size)*0.5 + PlayerBaseSpeed*0.5
}

func (p *Player) SendChan() <-chan []byte {
	return p.send
}

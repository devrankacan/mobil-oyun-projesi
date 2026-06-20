package game

const (
	ArenaWidth  = 2000
	ArenaHeight = 2000

	FoodCount      = 150
	FoodSize       = 5
	PlayerBaseSize = 20
	PlayerBaseSpeed = 220 // units/sec at base size

	EatSizeRatio = 1.15 // must be at least 15% bigger to eat another player
	GrowthPerFood = 2
)

type Vec2 struct {
	X float64 `json:"x"`
	Y float64 `json:"y"`
}

type Food struct {
	ID int   `json:"id"`
	Pos Vec2 `json:"pos"`
}

type PlayerState struct {
	ID    string `json:"id"`
	Name  string `json:"name"`
	Pos   Vec2   `json:"pos"`
	Size  float64 `json:"size"`
	Alive bool   `json:"alive"`
}

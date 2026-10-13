extends RefCounted
## Canonical rows: down, left, right, up. Frame zero is standing idle.
const DIRECTIONS = ["down", "left", "right", "up"]
const WALK = preload("res://assets/art/living/anami_swimwear.png")
const SWIM = preload("res://assets/art/living/anami_swimming.png")
const SWIM_ROWS = {"swim_down":0,"swim_left":1,"swim_right":2,"swim_up":3,"swim_idle":4,"enter_pool":5,"exit_pool":5}

static func swim_state(direction: int, moving: bool) -> String:
	return "swim_"+DIRECTIONS[clampi(direction,0,3)] if moving else "swim_idle"

static func walk_frame(elapsed: float, moving: bool, rate: float=8.0) -> int:
	return int(elapsed*rate)%4 if moving else 0

static func swim_frame(value: String, elapsed: float) -> int:
	if value=="enter_pool":return mini(3,int(elapsed*4.0/.85))
	if value=="exit_pool":return 3-mini(3,int(elapsed*4.0/.85))
	return int(elapsed*(2.0 if value=="swim_idle" else 6.0))%4

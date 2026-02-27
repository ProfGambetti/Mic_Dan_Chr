extends PathFollow2D


class_name OilDropper


const OIL = preload("uid://dh7hlequnhe22")


@export var speed: float = 100.0
@export var debug: bool = true
@export var oil_container: Node
@export var drop_time_var: Vector2 = Vector2(3.0, 8.0)
@export var drop_margin: float = 25.0


@onready var debug_dot: Sprite2D = $DebugDot
@onready var drop_timer: Timer = $DropTimer


func _enter_tree() -> void:
	EventHub.on_race_start.connect(start_timer)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	debug_dot.visible = debug
	progress_ratio = randf()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	progress += delta * speed
	
	
func start_timer() -> void:
	drop_timer.wait_time = randf_range(
		drop_time_var.x, drop_time_var.y
	)
	drop_timer.start()


func drop_oil() -> void:
	if !oil_container: 
		push_error("drop_oil oil_container not assigned")
	
	var oil_hazard: OilHazard = OIL.instantiate()
	oil_container.add_child(oil_hazard)
	oil_hazard.global_position = Vector2(
		global_position.x + randf_range(-drop_margin, drop_margin),
		global_position.y + randf_range(-drop_margin, drop_margin)
	)
	start_timer()
	

func _on_drop_timer_timeout() -> void:
	drop_oil()

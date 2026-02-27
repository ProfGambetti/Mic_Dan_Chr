extends Control


class_name Countdown


@export var wait_time: float = 1.0


@onready var label: Label = $Label
@onready var timer: Timer = $Timer
@onready var beep: AudioStreamPlayer = $Beep


var _started: bool = false
var _count: int = 3


func _unhandled_input(event: InputEvent) -> void:
	if !_started and event.is_action_pressed("Start"):
		start_race()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()
	timer.wait_time = wait_time


func update_label() -> void: label.text = "%d" % _count


func start_race() -> void:
	beep.play()
	show ()
	_started = true
	timer.start()


func _on_timer_timeout() -> void:
	_count -= 1
	if _count == 0:
		EventHub.emit_on_race_start() 
		queue_free()
	else: 
		beep.play()
		update_label()

extends Area2D


class_name Car


enum CarState { WAITING, DRIVING, BOUNCING, SLIPPING, RACEOVER }


@export var car_texture: Texture2D = preload("uid://b7wmt1hcagsow")
@export var car_name: String = "Maisy"
@export var car_number: int = 0
@export var bounce_time: float = 0.8
@export var bounce_force: float = 30.0
@export var slip_speed_range: Vector2 = Vector2(0.2, 0.5)
@export var spin_time: float = 0.6
@export var spin_slowdown: float = 0.4


@onready var crash_effect: CPUParticles2D = $CrashEffect
@onready var car_sprite: Sprite2D = $CarSprite
@onready var engine_sound: AudioStreamPlayer2D = $EngineSound
@onready var crash_sound: AudioStreamPlayer2D = $CrashSound
@onready var lap_sound: AudioStreamPlayer2D = $LapSound


var _velocity: float = 0.0
var _bounce_tween: Tween
var _bounce_target: Vector2 = Vector2.ZERO
var _slip_tween: Tween
var _state: CarState = CarState.WAITING
var _lap_time: float = 0.0
var _verifications_count: int = 0
var _verifications_passed: Array[int] = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventHub.on_race_start.connect(on_race_start)
	set_physics_process(false)
	car_sprite.texture = car_texture
	area_entered.connect(_on_area_entered)

func on_race_start() -> void:
	engine_sound.play()
	change_state(CarState.DRIVING)


func setup(vc: int) -> void:
	_verifications_count = vc

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_lap_time += delta


#region state

func change_state(new_state: CarState) -> void:
	if new_state == _state: return
	_state = new_state
	if _state == CarState.RACEOVER: return
	_state = new_state
	
	match new_state:
		CarState.BOUNCING:
			bounce()
		CarState.SLIPPING:
			slip_on_oil()
		CarState.DRIVING:
			set_physics_process(true)
		CarState.RACEOVER:
			engine_sound.stop()
			set_physics_process(false)

#endregion

#region Buonce

func bounce_done() -> void:
	_bounce_tween = null
	change_state(CarState.DRIVING)
	
	
func bounce() -> void:
	_velocity = 0.0
	
	kill_slip_tween()
	crash_sound.play()
	
	if _bounce_tween and _bounce_tween.is_running():
		_bounce_tween.kill()
	
	rotation_degrees = fmod(rotation_degrees, 360.0)
	_bounce_tween = create_tween()
	_bounce_tween.set_parallel()
	_bounce_tween.set_ease(Tween.EASE_IN_OUT)
	_bounce_tween.tween_property(self, "position", _bounce_target, bounce_time)
	_bounce_tween.tween_property(self, "rotation_degrees", rotation_degrees + 720.0, bounce_time)
	_bounce_tween.set_parallel(false)
	_bounce_tween.finished.connect(bounce_done)


func hit_boundary(dir_to_path: Vector2) -> void:
	crash_effect.restart()
	_bounce_target = position + (dir_to_path * bounce_force)
	change_state(CarState.BOUNCING)
	
#endregion


#region slipping


func kill_slip_tween() -> void:
	if _slip_tween and _slip_tween.is_running():
		_slip_tween.kill()


func slip_done() -> void:
	_velocity = 0.0
	_slip_tween = null
	change_state(CarState.DRIVING)


func slip_on_oil() -> void:
	
	kill_slip_tween()
	crash_sound.play()
	
	rotation_degrees = fmod(rotation_degrees, 360.0)
	_velocity *= randf_range(slip_speed_range.x, slip_speed_range.y)
	_slip_tween = create_tween()
	_slip_tween.set_parallel()
	_slip_tween.set_ease(Tween.EASE_IN_OUT)
	_slip_tween.tween_property(self, "position", position + _velocity * transform.x, bounce_time)
	_slip_tween.tween_property(self, "rotation_degrees", rotation_degrees + 720.0, bounce_time)
	_slip_tween.set_parallel(false)
	_slip_tween.finished.connect(slip_done)
	

func hit_oil() ->void:
	if _state == CarState.BOUNCING: return
	change_state(CarState.SLIPPING)

#endregion



func lap_completed() -> void:
	if _verifications_count == _verifications_passed.size():
		var lcd: LapCompleteData = LapCompleteData.new(self, _lap_time)
		print("lap_completed %s" % lcd)
		lap_sound.play()
		EventHub.emit_on_lap_completed(lcd)
	_verifications_passed.clear()
	_lap_time = 0.0

func hit_verification(verification_id: int ) -> void:
	if verification_id not in _verifications_passed:
		_verifications_passed.append(verification_id)
		

func _on_area_entered(other: Area2D) -> void:
	if not other is Car: return
	if _state == CarState.BOUNCING or _state == CarState.SLIPPING: return
	
	var other_car: Car = other as Car
	
	if _velocity >= other_car._velocity:
		other_car._receive_hit(self)
	else:
		_receive_hit(other_car)

func _receive_hit(hitter: Car) -> void:
	if _state == CarState.BOUNCING: return
	
	hitter._velocity *= 0.8
	_velocity *= 0.3
	
	crash_sound.play()
	crash_effect.restart()
	
	var push_dir: Vector2 = (global_position - hitter.global_position).normalized()
	var target_pos: Vector2 = global_position + push_dir * 35.0
	
	set_physics_process(false)
	
	var hit_tween = create_tween()
	hit_tween.set_ease(Tween.EASE_OUT)
	hit_tween.tween_property(self, "position", target_pos, 0.25)
	hit_tween.finished.connect(func(): 
		set_physics_process(true)
	)

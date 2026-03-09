extends Area2D
# La macchina è un Area2D: questo indica che le collisioni sono gestite tramite aree,
# non tramite fisica rigida (quindi movimento controllato via codice).

class_name Car
# Permette di usare "Car" come tipo globale (es. other is Car)

enum CarState { WAITING, DRIVING, BOUNCING, SLIPPING, RACEOVER }
# Stati possibili della macchina durante la gara:
# WAITING  -> prima della partenza
# DRIVING  -> guida normale
# BOUNCING -> rimbalzo dopo un urto
# SLIPPING -> scivolata su olio
# RACEOVER -> fine gara


@export var car_texture: Texture2D = preload("uid://b7wmt1hcagsow")
# Texture della macchina, configurabile dall’editor

@export var car_name: String = "Maisy"
# Nome della macchina (probabilmente usato per UI / classifica)

@export var car_number: int = 0
# Numero identificativo della macchina

@export var bounce_time: float = 0.8
# Durata del tween di rimbalzo

@export var bounce_force: float = 30.0
# Intensità dello spostamento durante il rimbalzo

@export var slip_speed_range: Vector2 = Vector2(0.2, 0.5)
# Moltiplicatore casuale della velocità durante lo scivolamento

@export var spin_time: float = 0.6
# NON usata in questo script (serve conferma se usata altrove)

@export var spin_slowdown: float = 0.4
# NON usata in questo script (serve conferma se usata altrove)


@onready var crash_effect: CPUParticles2D = $CrashEffect
# Effetto particellare visivo per gli urti

@onready var car_sprite: Sprite2D = $CarSprite
# Sprite grafico della macchina

@onready var engine_sound: AudioStreamPlayer2D = $EngineSound
@onready var crash_sound: AudioStreamPlayer2D = $CrashSound
@onready var lap_sound: AudioStreamPlayer2D = $LapSound
# Suoni associati alla macchina


var _velocity: float = 0.0
# Velocità scalare della macchina (direzione data da transform.x)

var _bounce_tween: Tween
var _bounce_target: Vector2 = Vector2.ZERO
# Tween e posizione di destinazione per il rimbalzo

var _slip_tween: Tween
# Tween usato durante lo scivolamento

var _state: CarState = CarState.WAITING
# Stato attuale della macchina

var _lap_time: float = 0.0
# Tempo del giro corrente

var _verifications_count: int = 0
# Numero totale di checkpoint richiesti per completare un giro

var _verifications_passed: Array[int] = []
# Lista degli ID dei checkpoint già attraversati


func _ready() -> void:
	# Si collega all’evento globale di inizio gara
	EventHub.on_race_start.connect(on_race_start)
	
	# La fisica viene attivata solo quando la gara parte
	set_physics_process(false)
	
	# Imposta la texture scelta dall’editor
	car_sprite.texture = car_texture
	
	# Rileva collisioni con altre Area2D
	area_entered.connect(_on_area_entered)


func on_race_start() -> void:
	# Avvio del motore e passaggio allo stato di guida
	engine_sound.play()
	change_state(CarState.DRIVING)


func setup(vc: int) -> void:
	# Imposta il numero di checkpoint richiesti
	_verifications_count = vc


func _process(delta: float) -> void:
	# Aggiorna il tempo del giro
	_lap_time += delta


#region state

func change_state(new_state: CarState) -> void:
	# Evita di rientrare nello stesso stato
	if new_state == _state: return
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
			_start_raceover_slowdown()

#endregion


#region Buonce

func bounce_done() -> void:
	# Fine del rimbalzo, ritorno alla guida
	_bounce_tween = null
	change_state(CarState.DRIVING)
	
	
func bounce() -> void:
	# Azzeramento velocità durante il rimbalzo
	_velocity = 0.0
	
	kill_slip_tween()
	crash_sound.play()
	
	# Interrompe eventuali tween già attivi
	if _bounce_tween and _bounce_tween.is_running():
		_bounce_tween.kill()
	
	# Normalizza l’angolo di rotazione
	rotation_degrees = fmod(rotation_degrees, 360.0)
	
	# Tween combinato: spostamento + rotazione
	_bounce_tween = create_tween()
	_bounce_tween.set_parallel()
	_bounce_tween.set_ease(Tween.EASE_IN_OUT)
	_bounce_tween.tween_property(self, "position", _bounce_target, bounce_time)
	_bounce_tween.tween_property(self, "rotation_degrees", rotation_degrees + 720.0, bounce_time)
	_bounce_tween.set_parallel(false)
	_bounce_tween.finished.connect(bounce_done)


func hit_boundary(dir_to_path: Vector2) -> void:
	# Chiamata quando la macchina colpisce il bordo pista
	crash_effect.restart()
	_bounce_target = position + (dir_to_path * bounce_force)
	change_state(CarState.BOUNCING)
	
#endregion


#region slipping

func kill_slip_tween() -> void:
	# Ferma lo scivolamento se attivo
	if _slip_tween and _slip_tween.is_running():
		_slip_tween.kill()


func slip_done() -> void:
	# Fine scivolamento
	_velocity = 0.0
	_slip_tween = null
	change_state(CarState.DRIVING)


func slip_on_oil() -> void:
	# Gestisce lo scivolamento su una macchia d’olio
	
	kill_slip_tween()
	crash_sound.play()
	
	rotation_degrees = fmod(rotation_degrees, 360.0)
	
	# Riduce la velocità con un fattore casuale
	_velocity *= randf_range(slip_speed_range.x, slip_speed_range.y)
	
	# Movimento e rotazione incontrollata
	_slip_tween = create_tween()
	_slip_tween.set_parallel()
	_slip_tween.set_ease(Tween.EASE_IN_OUT)
	_slip_tween.tween_property(self, "position", position + _velocity * transform.x, bounce_time)
	_slip_tween.tween_property(self, "rotation_degrees", rotation_degrees + 720.0, bounce_time)
	_slip_tween.set_parallel(false)
	_slip_tween.finished.connect(slip_done)
	

func hit_oil() ->void:
	# Evita lo scivolamento se sta già rimbalzando
	if _state == CarState.BOUNCING: return
	change_state(CarState.SLIPPING)

#endregion


func lap_completed() -> void:
	if _verifications_count == _verifications_passed.size():
		var lcd: LapCompleteData = LapCompleteData.new(self, _lap_time)
		print("lap_completed %s" % lcd)
		lap_sound.play()
		# Qui emette un segnale globale per notificare che un giro è completato
		# EventHub.on_lap_completed conterrà i dati della macchina e tempo
		EventHub.emit_on_lap_completed(lcd)
	
	# Reset per il giro successivo
	_verifications_passed.clear()
	_lap_time = 0.0


func hit_verification(verification_id: int ) -> void:
	# Registra il checkpoint se non già passato
	if verification_id not in _verifications_passed:
		_verifications_passed.append(verification_id)
		

func _on_area_entered(other: Area2D) -> void:
	# Gestione collisioni tra macchine
	if not other is Car: return
	if _state == CarState.BOUNCING or _state == CarState.SLIPPING: return
	
	var other_car: Car = other as Car
	
	# La macchina più veloce “vince” l’urto
	if _velocity >= other_car._velocity:
		other_car._receive_hit(self)
	else:
		_receive_hit(other_car)


func _receive_hit(hitter: Car) -> void:
	# Riduce le velocità dopo l’urto
	if _state == CarState.BOUNCING: return
	
	hitter._velocity *= 0.8
	_velocity *= 0.3
	
	crash_sound.play()
	crash_effect.restart()
	
	# Spinta nella direzione opposta all’altra macchina
	var push_dir: Vector2 = (global_position - hitter.global_position).normalized()
	var target_pos: Vector2 = global_position + push_dir * 35.0
	
	set_physics_process(false)
	
	# Spostamento breve post-urto
	var hit_tween = create_tween()
	hit_tween.set_ease(Tween.EASE_OUT)
	hit_tween.tween_property(self, "position", target_pos, 0.25)
	hit_tween.finished.connect(func(): 
		set_physics_process(true)
	)


func _start_raceover_slowdown() -> void:
	# Rallentamento graduale a fine gara
	var tween = create_tween()
	tween.tween_method(
		func(v: float): 
			_velocity = v
			position += transform.x * _velocity * get_physics_process_delta_time(),
		_velocity,
		0.0,
		2.0
	)
	tween.finished.connect(func(): set_physics_process(false))
	

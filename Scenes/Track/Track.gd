extends Node


class_name Track


@onready var track_path: Path2D = $TrackPath
@onready var verifications_holder: Node = $VerificationsHolder
@onready var cars_holder: Node = $CarsHolder
@onready var track_processor: TrackProcessor = $TrackPath/TrackProcessor
@onready var waypoint_holder: Node = $WaypointHolder
@onready var race_controller: RaceController = $RaceController
@onready var game_ui: GameUi = $UiCanvas/GameUi


var _track_curve: Curve2D


func _ready() -> void:
	await setup()
	

func setup() -> void:
	var cars: Array[Car] = []
	
	_track_curve = track_path.curve
	
	track_processor.build_waypoint_data(waypoint_holder)
	
	await track_processor.build_completed
	
	for car in cars_holder.get_children():
		cars.append(car)
		if car is Car:
			car.setup(verifications_holder.get_children().size())
		if car is CpuCar:
			car.set_next_waypoint(track_processor.first_waypoint)

	race_controller.setup(cars, _track_curve)
	game_ui.setup(cars)


func get_direction_to_path(from_pos: Vector2) -> Vector2:
	var closest_offset: float = _track_curve.get_closest_offset(from_pos)
	var nearest_point: Vector2 = _track_curve.sample_baked(closest_offset)
	return from_pos.direction_to(nearest_point)


func _on_track_collision_area_entered(area: Area2D) -> void:
	if area is Car: area.hit_boundary(get_direction_to_path(area.position))


func _on_start_line_area_entered(area: Area2D) -> void:
	if area is Car: area.lap_completed()
	
	

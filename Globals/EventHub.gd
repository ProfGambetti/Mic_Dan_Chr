extends Node


signal on_lap_completed(info: LapCompleteData)
signal on_race_start
signal on_lap_update(car: Car, lap_count: int, lap_time: float)
signal on_race_over(data: Array[CarRaceData])


func emit_on_race_over(data:Array[CarRaceData]) -> void:
	on_race_over.emit(data)


func emit_on_lap_completed(info: LapCompleteData) -> void:
	on_lap_completed.emit(info)



func emit_on_race_start() -> void:
	on_race_start.emit()
	
	
func emit_on_lap_update(car: Car, lap_count: int, lap_time: float) -> void:
	on_lap_update.emit(car, lap_count, lap_time)

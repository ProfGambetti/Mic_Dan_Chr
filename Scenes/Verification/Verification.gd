extends Area2D

# --- VERIFICA IL PASSAGGIO DELLA MACCHINA ---
# Questa Area2D serve come checkpoint intermedio nella pista.
# Quando un'auto passa sopra, chiama hit_verification() sulla macchina.
func _on_area_entered(area: Area2D) -> void:
	if area is Car:
		area.hit_verification(get_instance_id())

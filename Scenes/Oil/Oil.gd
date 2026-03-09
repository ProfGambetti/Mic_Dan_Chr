extends Area2D
# Nodo che rappresenta una macchia d'olio sulla pista (Area2D).
# Serve come ostacolo temporaneo per le macchine: quando una macchina entra,
# provoca l'effetto di slittamento tramite il metodo `hit_oil()` della macchina.

class_name OilHazard
# Permette di usare OilHazard come tipo globale in GDScript.

func _ready() -> void:
	# Attende un tempo casuale tra 3 e 5 secondi prima di rimuovere l'olio.
	# Questo simula un effetto temporaneo della macchia d'olio sulla pista.
	await get_tree().create_timer(
		randf_range(3.0, 5.0)
	).timeout
	# Dopo il timeout, l'olio si rimuove automaticamente dalla scena.
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	# Funzione chiamata quando un'altra Area2D entra nell'area dell'olio.
	if area is Car:
		# Se l'area è una macchina, attiva l'effetto slittamento
		# tramite il metodo `hit_oil()` definito nello script Car.gd.
		area.hit_oil()

extends VBoxContainer
# Nodo UI verticale che mostra le informazioni di una singola macchina.


class_name CarUi
# Permette di usare CarUi come tipo globale.


@export var label_alignment: HorizontalAlignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT
# Allineamento orizzontale dei testi, configurabile dall’editor.


@onready var name_label: Label = $HB/NameLabel 
# Label che mostra nome e numero della macchina.

@onready var lap_label: Label = $LapLabel
# Label che mostra il numero di giri completati.

@onready var last_lap_label: Label = $LastLapLabel
# Label che mostra il tempo dell’ultimo giro.

@onready var car_texture: TextureRect = $HB/CarTexture
# Immagine che rappresenta la macchina.


func _ready() -> void:
	# Imposta l’allineamento delle label in base al valore scelto dall’editor.
	name_label.horizontal_alignment = label_alignment
	lap_label.horizontal_alignment = label_alignment
	last_lap_label.horizontal_alignment = label_alignment
	
	
func update_values(car: Car, lap_count: int, lap_time: float) -> void:
	# Aggiorna i valori mostrati nella UI per una macchina specifica.
	
	# Mostra nome e numero della macchina.
	name_label.text = "%s (%02d)" % [car.car_name, car.car_number]
	
	# Mostra il numero di giri completati.
	lap_label.text = "Laps %d" % lap_count
	
	# Mostra il tempo dell’ultimo giro.
	last_lap_label.text = "Last: %.2fs" % lap_time
	
	# Imposta l’immagine della macchina.
	car_texture.texture = car.car_texture
	

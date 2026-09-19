extends HBoxContainer
class_name CoinsBag

@onready var coins_label: Label = $CoinsLabel

func _process(delta: float) -> void:
	coins_label.text = str(Global.coins)

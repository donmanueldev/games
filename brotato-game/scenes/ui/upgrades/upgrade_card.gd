extends Panel
class_name UpgradeCard

@export var item: ItemUpgrade: set = _set_data

@onready var item_icon: TextureRect = %ItemIcon
@onready var item_name: Label = %ItemName
@onready var item_description: Label = %ItemDescription

func _set_data(value: ItemUpgrade) -> void:
	item = value
	item_icon.texture = item.item_icon
	item_name.text = item.item_name
	item_description.text = item.description
	
	var style := Global.get_tier_style(item.item_tier)
	add_theme_stylebox_override("panel", style)


func _on_custom_button_pressed() -> void:
	if item:
		item.apply_upgrade()
		Global.on_upgrade_selected.emit()
		SoundManager.play_sound(SoundManager.Sound.UI_CLICK)

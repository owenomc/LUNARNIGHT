extends Node3D

var PressFScene := preload("res://ui/pressF.tscn")
var press_f_instance

func _ready() -> void:
	show_press_f()

func show_press_f() -> void:
	if press_f_instance == null:
		press_f_instance = PressFScene.instantiate()
		get_tree().current_scene.add_child(press_f_instance)

func hide_press_f() -> void:
	if press_f_instance != null:
		press_f_instance.queue_free()
		press_f_instance = null

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("flashlight_toggle"):  # Default key for "F" if using Input Map
		hide_press_f()

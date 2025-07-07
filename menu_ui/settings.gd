extends Control

@onready var fullscreen_dropdown = $Control/MarginContainer/VBoxContainer/HBoxContainer4/CHANGER/FullscreenDropdown
@onready var vsync_dropdown = $Control/MarginContainer/VBoxContainer/HBoxContainer4/CHANGER/VSyncDropdown
@onready var max_fps_dropdown = $Control/MarginContainer/VBoxContainer/HBoxContainer4/CHANGER/MaxFPSDropdown

const SETTINGS_FILE := "user://settings.cfg"
var fps_limits := [60, 120, 144, 240, 360]

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Populate Dropdowns
	fullscreen_dropdown.clear()
	fullscreen_dropdown.add_item("ON")
	fullscreen_dropdown.add_item("OFF")

	vsync_dropdown.clear()
	vsync_dropdown.add_item("ON")
	vsync_dropdown.add_item("OFF")

	max_fps_dropdown.clear()
	for fps in fps_limits:
		max_fps_dropdown.add_item(str(fps))

	# Load saved settings (or defaults)
	load_settings()

# === Dropdown Signal Handlers ===

func _on_fullscreen_dropdown_item_selected(index: int) -> void:
	apply_fullscreen_setting(index)
	save_settings()

func _on_v_sync_dropdown_item_selected(index: int) -> void:
	apply_vsync_setting(index)
	save_settings()

func _on_max_fps_dropdown_item_selected(index: int) -> void:
	apply_frame_cap_setting(index)
	save_settings()

# === Apply Functions ===

func apply_fullscreen_setting(index: int):
	if index == 0:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func apply_vsync_setting(index: int):
	var vsync_mode = DisplayServer.VSYNC_ENABLED if index == 0 else DisplayServer.VSYNC_DISABLED
	DisplayServer.window_set_vsync_mode(vsync_mode)

func apply_frame_cap_setting(index: int):
	if index >= 0 and index < fps_limits.size():
		Engine.max_fps = fps_limits[index]
	else:
		Engine.max_fps = 0  # Unlimited

# === Save Settings ===

func save_settings():
	var config = ConfigFile.new()
	config.set_value("display", "fullscreen", fullscreen_dropdown.get_selected_id())
	config.set_value("display", "vsync", vsync_dropdown.get_selected_id())
	config.set_value("display", "fps_index", max_fps_dropdown.get_selected_id())
	config.save(SETTINGS_FILE)

# === Load Settings ===

func load_settings():
	var config = ConfigFile.new()
	if config.load(SETTINGS_FILE) == OK:
		var fullscreen_index = config.get_value("display", "fullscreen", 0)
		var vsync_index = config.get_value("display", "vsync", 0)
		var fps_index = config.get_value("display", "fps_index", 0)

		fullscreen_dropdown.select(fullscreen_index)
		vsync_dropdown.select(vsync_index)
		max_fps_dropdown.select(fps_index)

		apply_fullscreen_setting(fullscreen_index)
		apply_vsync_setting(vsync_index)
		apply_frame_cap_setting(fps_index)
	else:
		# Defaults if no file
		fullscreen_dropdown.select(0)
		vsync_dropdown.select(0)
		max_fps_dropdown.select(0)
		apply_fullscreen_setting(0)
		apply_vsync_setting(0)
		apply_frame_cap_setting(0)

# === Back Button ===

func _on_back_button_pressed():
	$button_sound.play()
	get_tree().change_scene_to_file("res://menu_ui/main.tscn")

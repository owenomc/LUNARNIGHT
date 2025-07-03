extends CharacterBody3D

# === CONFIGURABLE STATS ===
@export var walk_speed := 3.0
@export var slow_speed := 1.0
@export var jump_velocity := 5.0
@export var gravity := 30.0
@export var mouse_sensitivity := 0.001

# === CAMERA & VISUALS ===
@onready var camera_fps: Camera3D = $Camera3Dfps
@onready var mesh: Node3D = $Skeleton_Rogue
@onready var anim_player: AnimationPlayer = $Skeleton_Rogue/AnimationPlayer

# === AUDIO & LIGHT ===
@onready var jump_sound: AudioStreamPlayer3D = $JumpSound
@onready var walk_sound: AudioStreamPlayer3D = $WalkSound
@onready var flashlight_spot = $Flashlight/SpotLight3D
# @onready var flashlight_omni = $Flashlight/OmniLight3D

# === STATE ===
var yaw := 0.0
var pitch := 0.0
const PITCH_MIN := deg_to_rad(-20)
const PITCH_MAX := deg_to_rad(20)
var is_first_person := true

var can_play_sound := true
var cooldown_running := false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var light_state = not flashlight_spot.visible
	flashlight_spot.visible = light_state
	randomize()
	_toggle_flashlight_timer()

func _toggle_flashlight_timer() -> void:
	while true:
		await get_tree().create_timer(randf_range(5.0, 30.0)).timeout
		flashlight_spot.visible = not flashlight_spot.visible

func _input(event):
	if event.is_action_pressed("flashlight_toggle"):
		var light_state = not flashlight_spot.visible
		flashlight_spot.visible = light_state
		# flashlight_omni.visible = light_state

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * mouse_sensitivity
		pitch = clamp(pitch - event.relative.y * mouse_sensitivity, PITCH_MIN, PITCH_MAX)

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _start_cooldown() -> void:
	if cooldown_running:
		return
	cooldown_running = true
	var duration = walk_sound.stream.get_length() if walk_sound.stream else .6
	await get_tree().create_timer(duration).timeout
	can_play_sound = true
	cooldown_running = false

func _physics_process(delta):
	handle_camera()
	
	if Input.is_action_pressed("move_right") or Input.is_action_pressed("move_left") or Input.is_action_pressed("move_up") or Input.is_action_pressed("move_down"):
		if not Input.is_action_pressed("slow_speed"):
			if can_play_sound:
				walk_sound.play()
				can_play_sound = false
				await _start_cooldown()
		else:
			# Optional: handle slow_speed behavior here, e.g., no sound or different sound
			pass
	else:
		can_play_sound = true  # Reset if no keys held
	
	var move_input = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_up") - Input.get_action_strength("move_down")
	)

	var move_dir = Vector3.ZERO
	if move_input.length() > 0:
		var cam_basis = camera_fps.global_transform.basis
		var forward = -cam_basis.z.normalized()
		var right = cam_basis.x.normalized()
		move_dir = (right * move_input.x + forward * move_input.y).normalized()

	var current_speed = slow_speed if Input.is_action_pressed("slow_speed") else walk_speed
	velocity.x = move_dir.x * current_speed
	velocity.z = move_dir.z * current_speed
	
	# Gravity & Jump
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
			var timer = Timer.new()
			timer.wait_time = 0.25
			timer.one_shot = true
			add_child(timer)
			timer.start()
			await timer.timeout
			jump_sound.play()

	# Apply movement
	move_and_slide()
	handle_animation(move_input)

func handle_camera():
	if is_first_person:
		camera_fps.rotation.x = pitch
		rotation.y = yaw

func handle_animation(move_input: Vector2):
	if not is_on_floor():
		play_anim("Jump_Full_Long")
	elif move_input.length() > 0.1:
		if Input.is_action_pressed("slow_speed"):
			play_anim("Running_A")
		else:
			play_anim("Walking_A")
	else:
		play_anim("Idle")

func play_anim(anim_name: String):
	if anim_player.current_animation != anim_name:
		anim_player.play(anim_name)

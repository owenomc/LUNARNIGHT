extends CharacterBody3D

@export var speed: float = 3.0
@export var vision_range: float = 20.0

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var ray: RayCast3D = $RayCast3D
@onready var target_node: Node3D = get_tree().current_scene.get_node("Player")  # MUST match name exactly

var can_see_player: bool = false

func _physics_process(_delta):
	if not target_node:
		return

	# Aim the Ray at the player
	var _to_target = target_node.global_position - global_position
	ray.target_position = ray.to_local(target_node.global_position)
	ray.force_raycast_update()

	var distance_to_target = global_position.distance_to(target_node.global_position)

	# Check if ray hits the player AND within vision range
	if ray.is_colliding() and ray.get_collider() == target_node and distance_to_target <= vision_range:
		can_see_player = true
	else:
		can_see_player = false

	if can_see_player:
		nav_agent.target_position = target_node.global_position

		if not nav_agent.is_navigation_finished():
			var next_point = nav_agent.get_next_path_position()
			var direction = (next_point - global_position).normalized()
			velocity = direction * speed
			move_and_slide()
			if direction.length() > 0.1:
				look_at(global_position + direction, Vector3.UP)
		else:
			velocity = Vector3.ZERO
			move_and_slide()
	else:
		velocity = Vector3.ZERO
		move_and_slide()

extends CharacterBody3D

# --- Movement Variables ---
@export var base_move_speed: float = 5.0
var target_speed: float = 0
@export var sprint_multiplier: float = 1.8
@export var crouch_multiplier: float = 0.5
@export var slide_boost: float = 2.0  # Increased slide speed
var can_move: bool = true
var is_moving: bool = false

var standing_height = 2.0  # Normal player height
var crouching_height = 0.5 # Half height when crouching
var sliding_height = 0.5  # Even shorter when sliding
var current_height = 2.0  # Track current collision height
var current_mesh_height = 2.0  # Track current mesh height

# Acceleration settings (Instant acceleration with limited air control)
@export var ground_acceleration: float = 20.0  # Faster response on ground
@export var ground_deceleration: float = 2.5
@export var air_acceleration: float = 8.0  # Limited air control
@export var air_deceleration: float = 0.5

# --- Rotation & Camera ---
@export var mouse_sensitivity: float = 0.002
@export var lean_angle: float = 10.0
var can_move_camera: bool = true

# --- Jumping & Gravity ---
@export var jump_velocity: float = 6.0
@export var gravity: float = 20.0
@export var jump_hold_time: float = 0.3  # Hold time to influence jump height
@export var coyote_time: float = 0.2  # Small window to jump after leaving ground
var jump_timer: float = 0.0
var coyote_timer: float = 0.0
var jump_slide_timer: float = 1

# --- Camera FOV for Sprint Effect ---
@export var default_fov: float = 70.0
@export var sprint_fov: float = 90.0
@export var fov_transition_speed: float = 5.0

# --- Camera Position Offsets ---
@export var camera_default_height: float = 0.5
@export var camera_crouch_height: float = 0.4  # Less extreme crouch height
@export var camera_slide_height: float = 0.4  # Same as crouch height for consistency
@export var camera_transition_speed: float = 5.0  # Faster transition to prevent dropping
var camera_default_offset: Vector3
var current_camera_height: float = 0.5  # Track current camera height
var current_camera_rotation: float = 0.0  # Track current camera rotation

# --- Slide Settings ---
var slide_duration: float = 0.5
var is_sliding: bool = false
var slide_timer: float = 0.0
var slide_direction: Vector3 = Vector3.ZERO
var is_crouching = false

# --- Internal Variables ---
var camera_rotation: Vector2 = Vector2.ZERO
@onready var camera: Camera3D = $Head/Camera3D
@onready var collision_shape = $CollisionShape3D
@onready var mesh = $MeshInstance3D

#Dashing
@export var dash_speed: float = 15.0
var dash_duration: float = 0.2
var dash_cooldown: float = 0.5  # Prevent spamming
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_direction: Vector3 = Vector3.ZERO
var last_tap_time = {}  # Stores last tap times for double-tap detection
var can_dash: bool = true
var last_tap_action = ""  # Stores the last movement key pressed
var max_dashes = 2  # Maximum dashes before touching the ground
var dash_count = 0   # Tracks used dashes

var mouse_captured: bool = true

#Gun variables
@onready var pistol = preload("res://Player/Guns/pistol.tscn")
@onready var shotgun = preload("res://Player/Guns/shotgun.tscn")
@onready var demon_claw = preload("res://Player/Guns/demon_claw.tscn")
@onready var bolt_rifle = preload("res://Player/Guns/bolt_rifle.tscn")
@onready var chainsaw = preload("res://Player/Guns/chainsaw.tscn")
var current_gun = 0
@onready var carried_guns = [pistol, shotgun, demon_claw, bolt_rifle, chainsaw]

#Hit Var
var hurt_timer = 0.0
var max_hurt_time = 1
var max_intensity = 0.12

# --- Ledge Detection Variables ---
@onready var ray_low: RayCast3D = $Head/LedgeRayLow
@onready var ray_high: RayCast3D = $Head/LedgeRayHigh
@onready var space_check_ray1: RayCast3D = $Head/space_check_ray1
@onready var space_check_ray2: RayCast3D = $Head/space_check_ray2
@onready var space_check_ray3: RayCast3D = $Head/space_check_ray3

# Ceiling Check Rays
@onready var ceiling_check_ray: RayCast3D = $Head/CeilingChecks/CeilingCheckRay
@onready var ceiling_check_ray1: RayCast3D = $Head/CeilingChecks/CeilingCheckRay2
@onready var ceiling_check_ray2: RayCast3D = $Head/CeilingChecks/CeilingCheckRay3
@onready var ceiling_check_ray3: RayCast3D = $Head/CeilingChecks/CeilingCheckRay4
@onready var ceiling_check_ray4: RayCast3D = $Head/CeilingChecks/CeilingCheckRay5

var can_stand_up: bool = true
var is_grabbing_ledge: bool = false
var can_grab_ledge: bool = true
var ledge_grab_cooldown: float = 0.5
var ledge_grab_timer: float = 0.0
var ledge_normal: Vector3
var ledge_point: Vector3
var initial_ledge_rotation: float
@export var max_ledge_look_angle: float = 180.0
@export var ledge_camera_tilt: float = -15.0
@export var camera_transition_duration: float = 0.2
var is_climbing: bool = false  # Track if we're in climbing animation

@onready var ray_left: RayCast3D = $Head/RayLeft
@onready var ray_right: RayCast3D = $Head/RayRight

var health = 100
var switchingGuns: bool = false
var switching_due_to_empty: bool = false

@onready var ray_step_up: RayCast3D = $RayCheckStairsUp
@onready var ray_step_down: RayCast3D = $RayCheckStairsDown
var is_climbing_stair = false
var current_ray_height = -0.8

@export var stair_bob_speed := 3.0
@export var stair_bob_amount := 0.1
var _stair_bob_progress := 0.0
var _target_camera_local_pos: Vector3
var _smooth_climb_velocity = 0.0

@export var step_climb_duration := 0.2
@export var step_climb_height := 0.3
var is_climbing_stair_anim := false

func _ready():
	_target_camera_local_pos = camera.position
	$CanvasLayer/ColorRect.material.set_shader_parameter("hurt_intensity", (hurt_timer / max_hurt_time) * 0)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera.fov = default_fov
	camera_default_offset = camera.transform.origin
	current_camera_height = camera_default_height
	PlayerStats.reset()
	#PlayerStats.current_gun = "Pistol"
	#PlayerStats.reloading = false
	
	# Setup ledge detection raycasts
	ray_low.target_position = Vector3(0, 0, 1.0)  # 1 meter forward
	ray_high.target_position = Vector3(0, 0, 2)  # 1 meter forward
	ray_low.position = Vector3(0, 0.9, 0)  # Below head level
	ray_high.position = Vector3(0, 1.3, 0)  # Above head level
	target_speed = base_move_speed

func _input(event):
	if event is InputEventMouseMotion and can_move_camera:
		camera_rotation.x -= event.relative.x * mouse_sensitivity
		camera_rotation.y -= event.relative.y * mouse_sensitivity
		camera_rotation.y = clamp(camera_rotation.y, -1.5, 1.5)
		
		if is_grabbing_ledge:
			# Limit horizontal rotation while on ledge
			var angle_diff = wrapf(camera_rotation.x - initial_ledge_rotation, -PI, PI)
			angle_diff = clamp(angle_diff, deg_to_rad(-max_ledge_look_angle), deg_to_rad(max_ledge_look_angle))
			camera_rotation.x = initial_ledge_rotation + angle_diff
	
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		if !mouse_captured:
			get_tree().quit()
		mouse_captured = false
		
	if Input.is_action_just_pressed("reset"):
		get_tree().reload_current_scene()
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		mouse_captured = true
	
	if event.is_action_pressed("toggle_fullscreen"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED else DisplayServer.WINDOW_MODE_WINDOWED)
	 
	if event.is_action_pressed("ui_up"):  # Press Up Arrow to increase FPS
		Engine.max_fps += 10
	elif event.is_action_pressed("ui_down"):  # Press Down Arrow to decrease FPS
		Engine.max_fps -= 10
		
		
	if PlayerStats.is_hit or PlayerStats.heal:
		hurt_timer = max_hurt_time 
	
	if PlayerStats.health == 0:
		death()
	

func death():
	PlayerStats.health = 100
	PlayerStats.is_hit = false
	get_tree().reload_current_scene()

func change_gun(gun):
	var gun_holder = $Head/Camera3D/Gun

	if gun_holder.get_child_count() > 0:
		gun_holder.get_child(0).queue_free()
		await get_tree().process_frame 
	if gun >= 0 and gun < len(carried_guns):
		var new_gun = carried_guns[gun].instantiate()
		gun_holder.add_child(new_gun)
		PlayerStats.current_gun = new_gun.name
		#if new_gun.name != "Demon_Claw":
			#PlayerStats.is_hit = false
			#PlayerStats.heal = false
			

# Switch to the next available gun that has ammo or the claw if none have ammo

func _process(delta):
	if hurt_timer > 0:
		hurt_timer -= delta
		$CanvasLayer/ColorRect.material.set_shader_parameter("hurt_intensity", (hurt_timer / max_hurt_time) * max_intensity)
	
	
	detect_double_tap()
	
	if Input.is_action_just_pressed("next_gun") and !PlayerStats.reloading and !switchingGuns:
		switchingGuns = true
		current_gun += 1
		if current_gun > len(carried_guns)-1:
			current_gun = 0 
		change_gun(current_gun)
	elif Input.is_action_just_pressed("previous_gun") and !PlayerStats.reloading and !switchingGuns:
		switchingGuns = true
		current_gun -= 1
		if current_gun < 0:
			current_gun = len(carried_guns)-1 
		change_gun(current_gun)
			
func _physics_process(delta):
	#if material:
		#material.set_shader_parameter("viewport_size", get_viewport().get_visible_rect().size)
	# Ledge grab cooldown
	if ledge_grab_timer > 0:
		ledge_grab_timer -= delta
		can_grab_ledge = false
	else:
		can_grab_ledge = true
	
	if is_grabbing_ledge:
		handle_ledge_movement()
	else:
		check_ledge_grab()
		# Normal movement code
		
		
		var input_dir: Vector3 = Vector3.ZERO
		input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
		input_dir.z = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
		var move_direction: Vector3 = Vector3.ZERO
		if input_dir.length() > 0 and !is_climbing_stair_anim:
			move_direction = (transform.basis * input_dir).normalized()
		#Running
		if input_dir.length() > 0 and can_move and !is_sliding and can_stand_up:
			target_speed += delta * 3
			if(target_speed > base_move_speed * sprint_multiplier):
				target_speed = base_move_speed * sprint_multiplier
		elif !is_sliding and can_stand_up:
			target_speed -= delta * 8
			if target_speed < base_move_speed:
				target_speed = base_move_speed
			
		var current_accel: float = ground_acceleration if is_on_floor() else air_acceleration
		var current_decel: float = ground_deceleration if is_on_floor() else air_deceleration
		
		var horizontal_velocity: Vector3 = velocity
		horizontal_velocity.y = 0
		# Modified physics
		if is_on_floor():
		# Ground movement with momentum
			if move_direction != Vector3.ZERO:
				# Accelerate in desired direction
				horizontal_velocity = horizontal_velocity.move_toward(move_direction * target_speed, current_accel * delta)
			else:
				# Gradual deceleration (Doom-style slide)
				horizontal_velocity = horizontal_velocity * (1.0 - current_decel * delta)
		else:
			# Air control
			if move_direction != Vector3.ZERO:
				# Limited air influence
				var air_velocity = horizontal_velocity.move_toward(move_direction * target_speed, current_accel * delta)
				horizontal_velocity = horizontal_velocity.lerp(air_velocity, 0.5)  # Adjust 0.5 for air control strength
				# No automatic air deceleration

		# Apply friction if moving against current velocity
		var velocity_dot = horizontal_velocity.dot(move_direction)
		if velocity_dot < 0:
			horizontal_velocity -= horizontal_velocity.normalized() * current_decel * delta


		
		velocity.x = horizontal_velocity.x
		velocity.z = horizontal_velocity.z
		
		if Input.is_action_just_pressed("dash") and can_dash and !is_dashing:
			if input_dir.length() > 0 and !ray_step_up.is_colliding():  # Only dash if moving
				if is_dashing:
					return
				else:
					var dash_direction = (transform.basis * input_dir.normalized()).normalized()
					dash(dash_direction)
		
		#Jumping
		jumping(delta)
		
		#Sliding
		sliding(delta)
		
		if is_dashing and dash_count <= 1:
			velocity = dash_direction * dash_speed
			dash_timer -= delta
			if dash_timer <= 0:
				is_dashing = false
				can_dash = false
				await get_tree().create_timer(dash_cooldown).timeout
				can_dash = true
		
		if is_on_floor():
			dash_count = 0
		
		#StairClimbing v2 sugoi works not it doesnt has problems when crouching dumbass
		#var ray_offset = Vector3.ZERO
		#if abs(input_dir.z) > 0:
			#ray_offset.z = 0.8 * input_dir.z
		#elif abs(input_dir.x) > 0:
			#ray_offset.x = 0.8 * input_dir.x
		
		var hor_off = Vector3.ZERO
		if input_dir.length() > 0.1:
			hor_off = input_dir.normalized() * 0.8
		#ray_step_up.position = ray_offset
		ray_step_up.position.x   = hor_off.x
		ray_step_up.position.z   = hor_off.z
		
		if Input.is_action_pressed("crouch") or !can_stand_up:
			is_crouching = true
			current_ray_height = lerp(current_ray_height,-0.2,camera_transition_speed * delta)
			ray_step_up.target_position.y = current_ray_height
		else:
			is_crouching = false
			current_ray_height = lerp(current_ray_height,-1.0,camera_transition_speed * delta*0.4)
			ray_step_up.target_position.y = current_ray_height
		if ray_step_up.is_colliding() and (input_dir.length() > 0.1 or is_dashing) and is_on_floor() and not is_climbing_stair_anim:
			var hit_point = ray_step_up.get_collision_point()
			if _is_real_stair(hit_point):
				var step_height = hit_point.y - (global_position.y - 1)
				if step_height > 0 and step_height <= 0.6:
					is_climbing_stair_anim = true
					
					#velocity.y += step_height * 11
					var target_pos = global_position + Vector3(move_direction.x * 0.4, step_height , move_direction.z * 0.4)

					# Create camera bob effect
					
					var camera_target = _target_camera_local_pos + Vector3(0, stair_bob_amount, 0)
					var tween_cam = create_tween().set_parallel(true)
					tween_cam.tween_property(camera, "position", camera_target, step_climb_duration * 0.5)\
					.set_ease(Tween.EASE_OUT)\
					.set_trans(Tween.TRANS_QUINT)
					tween_cam.tween_property(camera, "position", _target_camera_local_pos, step_climb_duration * 0.5)\
					.set_ease(Tween.EASE_IN)\
					.set_trans(Tween.TRANS_QUINT)\
					.set_delay(step_climb_duration * 0.5)

					# Animate player position
					var tween = create_tween().set_parallel(true)
					tween.tween_property(self, "global_position", target_pos, 0.06)\
					.set_ease(Tween.EASE_OUT)\
					.set_trans(Tween.TRANS_SINE)
					
					tween.tween_callback(func(): is_climbing_stair_anim = false)
		
		if is_climbing_stair_anim:
			if input_dir.length() > 0:
				target_speed = 6
		
		
	
		#Stair decending
		if ray_step_down.is_colliding() and !is_on_floor() and !is_climbing_stair_anim and velocity.y < 0:
			var hit_point = ray_step_down.get_collision_point()
			var drop_height = (global_position.y - 1) - hit_point.y  # Positive values
			if drop_height > 0 and drop_height <= 0.5:
				# Option 1: Smooth downward motion
				velocity.y = -6
		move_and_slide()
		
		# ------------- Camera Settings -------------
		var target_fov_val = default_fov
		var target_camera_y = camera_default_height
		var target_camera_rot_z = 0.0  # Always in radians!

		# FOV Changes (sprinting)
		if Input.is_action_pressed("move_up") or !is_on_floor() and !Input.is_action_pressed("crouch") and can_stand_up:
			target_fov_val = sprint_fov

		camera.fov = lerp(camera.fov, target_fov_val, fov_transition_speed * delta)

		# Height Changes (sliding/crouching)
		if is_sliding:
			target_camera_y = camera_slide_height
			target_camera_rot_z = deg_to_rad(-2)  # Slide tilt
		elif Input.is_action_pressed("crouch"):
			target_camera_y = camera_crouch_height

		# Lean (only when not sliding)
		if !is_sliding && input_dir.x != 0:
			target_camera_rot_z += -input_dir.x * deg_to_rad(10.0)

		# Apply all changes
		current_camera_height = lerp(current_camera_height, target_camera_y, camera_transition_speed * delta)
		camera.transform.origin.y = current_camera_height
		camera.rotation.z = lerp(camera.rotation.z, target_camera_rot_z, camera_transition_speed * delta)

		# Mesh scaling (unchanged)
		current_mesh_height = lerp(current_mesh_height, current_height, camera_transition_speed * delta)
		mesh.scale.y = current_mesh_height / standing_height
	
	# Always update camera rotation, whether grabbing ledge or not
	rotation.y = camera_rotation.x
	camera.rotation.x = camera_rotation.y

func _is_real_stair(collision_point: Vector3) -> bool:
	var collision_normal = ray_step_up.get_collision_normal()
	var floor_angle = rad_to_deg(collision_normal.angle_to(Vector3.UP))

	# Only count as stair if:
	# 1. The surface is nearly flat (not a slope)
	# 2. The step height is reasonable
	var step_height = collision_point.y - (global_position.y - 1)
	return (floor_angle < 0.1 and 
		step_height > 0 and
		step_height <= 0.6)


func sliding(delta):
	
	#ceiling_check_ray.force_raycast_update()
	#can_stand_up = !ceiling_check_ray.is_colliding()
	
	if ceiling_check_ray.is_colliding() or ceiling_check_ray1.is_colliding() or ceiling_check_ray2.is_colliding() or ceiling_check_ray3.is_colliding() or ceiling_check_ray4.is_colliding():
		can_stand_up = false
	else:
		can_stand_up = true

	if is_on_floor() and Input.is_action_just_pressed("crouch") and Input.is_action_pressed("move_up") and !is_sliding:
		is_sliding = true
		target_speed = target_speed * slide_boost
		slide_timer = slide_duration
		slide_direction = velocity.normalized()
		
	
	if is_sliding:
		if current_height > crouching_height:
			current_height = lerp(current_height, crouching_height, camera_transition_speed * delta)
			collision_shape.shape.height = current_height
			mesh.scale.y = current_mesh_height / standing_height
	
	#Crouching	
	if Input.is_action_pressed("crouch") and is_on_floor() and jump_slide_timer <= 0 and !is_sliding:
		target_speed = base_move_speed * crouch_multiplier
		# Smoothly adjust collision height
		
		if current_height > crouching_height:
			current_height = lerp(current_height, crouching_height, camera_transition_speed * delta)
			collision_shape.shape.height = current_height
	else :
		# Return to normal height if not crouching and not sliding
		if !is_sliding and current_height < standing_height and can_stand_up:
			current_height = lerp(current_height, standing_height, camera_transition_speed * delta)
			collision_shape.shape.height = current_height
	
	#Detect Landing
	if is_on_floor():
		jump_slide_timer -= delta
	else:
		jump_slide_timer = 0.1
	
	#Jump slide
	if is_on_floor() and Input.is_action_pressed("crouch") and jump_slide_timer>0:
		var horizontal_speed = Vector2(velocity.x, velocity.z).length()
		if(horizontal_speed > base_move_speed * sprint_multiplier * 0.8):
			is_sliding = true;
			slide_direction = velocity.normalized()
			
	#If sliding
	if is_sliding:
		if target_speed <= base_move_speed * crouch_multiplier || Input.is_action_just_released("crouch"):	
			is_sliding = false
			target_speed /= 1.5
		else:
			target_speed -= delta* 8
			velocity.x = slide_direction.x * target_speed
			velocity.z = slide_direction.z * target_speed
	else:
		slide_boost = 1.5

func jumping(delta):
	if is_on_floor():
		coyote_timer = coyote_time
		if Input.is_action_just_pressed("jump") and !is_crouching:
			velocity.y = jump_velocity
			jump_timer = jump_hold_time
	else:
		if coyote_timer > 0 and Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
			jump_timer = jump_hold_time
		coyote_timer -= delta
		velocity.y -= gravity * delta
	if jump_timer > 0 and Input.is_action_pressed("jump"):
		velocity.y += gravity * delta * 0.8
		jump_timer -= delta

func detect_double_tap():
	if not can_dash or is_dashing:  # Block input if dashing or in cooldown
		return
	
	var directions = {
		"move_up": Vector3.FORWARD,
		"move_down": Vector3.BACK,
		"move_left": Vector3.LEFT,
		"move_right": Vector3.RIGHT
	}
	for action in directions.keys():
		if Input.is_action_just_pressed(action) and !is_grabbing_ledge and !is_crouching and can_stand_up:
			var current_time = Time.get_ticks_msec()
			if action == last_tap_action and last_tap_time.has(action) and current_time - last_tap_time[action] < 250 and can_dash:
				#dash(directions[action])
				pass
			last_tap_action = action
			last_tap_time[action] = current_time
			
func dash(direction: Vector3):
	is_dashing = true
	dash_timer = dash_duration
	dash_direction = direction
	dash_count += 1
	can_dash = false
	
	if is_on_floor():
		dash_cooldown = 1
	else:
		dash_cooldown = 0.5
	
	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true

func check_ledge_grab():
	if !can_grab_ledge or is_on_floor() or is_grabbing_ledge:
		return
		
	# Only try to grab when falling
	if velocity.y > 0:
		return
	
	# Update ray rotations to match player view
	var forward = -transform.basis.z
	var right = transform.basis.x
	var up = transform.basis.y
	
	# Adjust ray directions based on player's look direction
	ray_low.global_transform.basis = Basis(right, up, forward)
	ray_high.global_transform.basis = Basis(right, up, forward)
	
	# Force raycast updates
	ray_low.force_raycast_update()
	ray_high.force_raycast_update()
	
	# Check for ledge
	if ray_low.is_colliding() and !ray_high.is_colliding():
		var hit_point = ray_low.get_collision_point()
		var wall_normal = ray_low.get_collision_normal()
		
		# Check if we're facing the wall
		var facing_dot = forward.dot(wall_normal)
		if facing_dot > -0.5:  # Not facing the wall enough
			return
			
		ledge_point = hit_point
		ledge_normal = wall_normal
		start_ledge_grab()

func start_ledge_grab():
	is_grabbing_ledge = true
	velocity = Vector3.ZERO
	
	# Calculate grab position
	var grab_pos = ledge_point + ledge_normal * 0.3  # Offset from wall
	grab_pos.y -= 0.5  # Hang below ledge
	
	# Move to grab position
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", grab_pos, camera_transition_duration)
	
	# Store current rotation as initial rotation
	initial_ledge_rotation = camera_rotation.x

func handle_ledge_movement():
	# Get the forward direction based on camera rotation
	var forward = -transform.basis.z
	var facing_wall = forward.dot(ledge_normal) < -0.8  # Are we facing the wall?
	
	if Input.is_action_just_pressed("jump"):
		if Input.is_action_pressed("move_up"):
			# If looking forward and pressing forward, do directional jump
			if !facing_wall:
				directional_ledge_jump()
	
	if Input.is_action_just_pressed("move_down"):
		ledge_drop()
	# Separate climbing check
	elif Input.is_action_pressed("move_up") and !space_check_ray1.is_colliding() and !space_check_ray2.is_colliding() and !space_check_ray3.is_colliding():
		# Can only climb when facing the wall
		if facing_wall and !is_climbing:
			climb_up()

func directional_ledge_jump():
	is_grabbing_ledge = false
	
	# Get the direction we're looking at
	var jump_dir = -transform.basis.z  # Forward vector
	
	# Adjust vertical component based on where we're looking
	var look_up = -camera.rotation.x  # Inverted from previous version
	var vertical_boost = clamp(-look_up, 0.2, 0.8)  # Negated to invert the effect
	jump_dir.y = vertical_boost  # More control over jump arc
	
	jump_dir = jump_dir.normalized()
	
	# Much more forward momentum for longer jumps
	velocity = jump_dir * (jump_velocity * 2.5)  # Increased from 1.5 to 2.5
	
	# Add a small initial upward boost for better arcs
	velocity.y += jump_velocity * 0.2  # Additional upward boost
	
	ledge_grab_timer = ledge_grab_cooldown

func ledge_jump():
	is_grabbing_ledge = false
	
	# Jump away from wall with more upward momentum
	var jump_dir = ledge_normal + Vector3.UP * 1.2  # More upward bias
	jump_dir = jump_dir.normalized()
	velocity = jump_dir * (jump_velocity * 1.2)
	
	ledge_grab_timer = ledge_grab_cooldown

func ledge_drop():
	is_grabbing_ledge = false
	velocity = Vector3.ZERO
	ledge_grab_timer = ledge_grab_cooldown

func climb_up():
	if is_climbing:  # Prevent starting another climb while already climbing
		return
		
	is_climbing = true
	target_speed = base_move_speed
	# Calculate positions for curved motion
	var start_pos = global_position
	var end_pos = ledge_point - ledge_normal * 0.8  # Final position away from wall
	end_pos.y += 1.0  # Standing height
	
	# Create control points for curved motion
	var control_point = ledge_point + ledge_normal * 0.2  # Closer to wall for tighter curve
	control_point.y += 1.5  # Higher peak for arc
	
	# Create a fluid climbing animation
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)  # Smooth sine curve
	tween.set_ease(Tween.EASE_IN_OUT)  # Smooth acceleration and deceleration
	
	# Animate along the curve using a callback
	var duration = 0.35  # Total animation time
	tween.tween_method(
		func(t: float):
			# Quadratic Bezier curve calculation
			var q0 = start_pos.lerp(control_point, t)
			var q1 = control_point.lerp(end_pos, t)
			var final_pos = q0.lerp(q1, t)
			global_position = final_pos,
		0.0,  # Start time
		1.0,  # End time
		duration
	)
	
	# Reset states after animation
	tween.tween_callback(func():
		is_climbing = false
		is_grabbing_ledge = false
		ledge_grab_timer = ledge_grab_cooldown
	)

func _on_timer_timeout():
	if switchingGuns:
		switchingGuns = false

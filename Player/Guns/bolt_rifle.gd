extends Node3D

@onready var gun_sprite = $CanvasLayer/Control/GunSprite
@onready var gun_rays = $GunRays
@onready var flash = preload("res://Player/Guns/muzzle_flash.tscn")
@onready var blood = preload("res://Particles/blood.tscn")
@onready var hit = preload("res://Particles/hit.tscn")
var damage = 8
var can_shoot: bool = true
var is_reloading: bool = false
var empty: bool = false
var magazine: int = 1

# Penetration settings
var max_penetration: int = 2  # How many enemies the bullet can go through
var damage_reduction: float = 1  # Damage multiplier after each penetration

func _ready():
	enable_rays()
	gun_sprite.play("idle")
	
func enable_rays():
	for ray in gun_rays.get_children():
		if ray is RayCast3D:
			ray.enabled = true 
			ray.force_raycast_update()  

func check_hit():
	for ray in gun_rays.get_children():
		if ray is RayCast3D and ray.enabled:
			# New penetration handling
			var current_damage = damage
			var remaining_penetration = max_penetration
			var current_ray = ray
			
			while remaining_penetration >= 0 and current_ray.is_colliding():
				var hit_object = current_ray.get_collider()
				if hit_object:
					print("Hit:", hit_object.name)  
					if hit_object.is_in_group("Enemy"):
						# Spawn blood effect
						var new_blood = blood.instantiate()
						get_tree().current_scene.add_child(new_blood)
						new_blood.global_transform.origin = current_ray.get_collision_point()
						new_blood.emitting = true

						# Apply damage
						hit_object.take_damage(current_damage)

						# Prepare for next penetration
						current_damage *= damage_reduction
						remaining_penetration -= 1

						# Create a new temporary ray to check beyond the current hit
						var new_ray = RayCast3D.new()
						add_child(new_ray)
						new_ray.global_transform.origin = current_ray.get_collision_point() + current_ray.global_transform.basis.z * -0.1
						new_ray.target_position = current_ray.target_position
						new_ray.force_raycast_update()

						# Update for next iteration
						current_ray = new_ray
					else:
						# Hit non-enemy object (wall, etc)
						var new_hit = hit.instantiate()
						get_tree().current_scene.add_child(new_hit)
						new_hit.global_transform.origin = current_ray.get_collision_point()
						new_hit.emitting = true
						break  # Bullet stops at walls
				# Clean up temporary rays
				if current_ray != ray:
					current_ray.queue_free()

	
func make_flash():
	var f = flash.instantiate()
	add_child(f)	
	
	

func _process(delta):
	
	if PlayerStats.ammo_bolt == 0 and PlayerStats.ammo_bolt_cur == 0:
		PlayerStats.bolt_empty = true
	else:
		PlayerStats.bolt_empty = false
	
	if PlayerStats.ammo_bolt_cur == 0 and PlayerStats.ammo_bolt >= 1 and !PlayerStats.reloading and !empty:
		empty = true
		gun_sprite.play("reload")
		await gun_sprite.animation_finished
		PlayerStats.ammo_bolt_cur = 1
		PlayerStats.ammo_bolt -= 1
		empty = false
	
	if Input.is_action_just_pressed("shoot") and can_shoot and PlayerStats.ammo_bolt_cur >= 1:
		if PlayerStats.ammo_bolt != 0:
			gun_sprite.play("shoot")
		else: 
			gun_sprite.play("just_shoot")
			
	
		
	
		make_flash()
		check_hit()
		can_shoot = false
		PlayerStats.reloading = true
		PlayerStats.change_bolt_ammo(-1)
		await gun_sprite.animation_finished
		if PlayerStats.ammo_bolt_cur <= 0:
			if PlayerStats.ammo_bolt > 1:
				PlayerStats.ammo_bolt_cur = 1
				PlayerStats.ammo_bolt -= 1
			elif PlayerStats.ammo_bolt == 1:
				PlayerStats.ammo_bolt_cur = PlayerStats.ammo_bolt
				PlayerStats.ammo_bolt -= 1
			
		can_shoot = true
		PlayerStats.reloading = false
		
	

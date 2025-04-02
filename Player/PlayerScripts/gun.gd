extends Node3D

@onready var gun_sprite = $CanvasLayer/Control/GunSprite
@onready var gun_rays = $GunRays
@onready var flash = preload("res://Player/Guns/muzzle_flash.tscn")
@onready var blood = preload("res://Particles/blood.tscn")
@onready var hit = preload("res://Particles/hit.tscn")
var damage = 3
var can_shoot: bool = true
var is_reloading: bool = false
var is_empty: bool = false
var magazine: int = 7

func _ready():
	enable_rays()
	if !is_empty:
		gun_sprite.play("idle")
	elif is_empty:
		gun_sprite.play("idle_empty")
	
func enable_rays():
	for ray in gun_rays.get_children():
		if ray is RayCast3D:
			ray.enabled = true 
			ray.force_raycast_update()  

func check_hit():
	for ray in gun_rays.get_children():
		if ray is RayCast3D and ray.enabled and ray.is_colliding():
			var hit_object = ray.get_collider()
			if hit_object:
				print("Hit:", hit_object.name)  
				if hit_object.is_in_group("Enemy"):
					var new_blood = blood.instantiate()
					get_tree().current_scene.add_child(new_blood)
					new_blood.global_transform.origin = ray.get_collision_point()
					new_blood.emitting = true
					hit_object.take_damage(damage)
					#print("Enemy hit!")
				else:
					var new_hit = hit.instantiate()
					get_tree().current_scene.add_child(new_hit)
					new_hit.global_transform.origin = ray.get_collision_point()
					new_hit.emitting = true
	
func make_flash():
	var f = flash.instantiate()
	add_child(f)
	
func _process(delta):
	
	if PlayerStats.ammo_pistol == 0 and PlayerStats.ammo_pistol_cur == 0:
		PlayerStats.pistol_empty = true
	else:
		PlayerStats.pistol_empty = false
	
	if Input.is_action_just_pressed("shoot") and can_shoot and !is_reloading:
		#print(magazine)
		if !is_empty:
			gun_sprite.play("shoot")
			PlayerStats.change_pistol_ammo(-1)
			make_flash()
			check_hit()		
		elif is_empty:
			gun_sprite.play("empty")		
		can_shoot = false
		await gun_sprite.animation_finished
		can_shoot = true
	
	if PlayerStats.ammo_pistol_cur <= 0:
		is_empty = true
	elif PlayerStats.ammo_pistol_cur > 0:
		is_empty = false
	
	if Input.is_action_just_pressed("reload") and !is_reloading and can_shoot and PlayerStats.ammo_pistol_cur != 7 and PlayerStats.ammo_pistol != 0:
		is_reloading = true
		PlayerStats.reloading = true;
		if !is_empty:
			gun_sprite.play("reload")
			var tmp = 7 - PlayerStats.ammo_pistol_cur
			if PlayerStats.ammo_pistol-tmp >= 0:
				PlayerStats.ammo_pistol_cur = 7
				PlayerStats.ammo_pistol -= tmp
			else:
				PlayerStats.ammo_pistol_cur += PlayerStats.ammo_pistol 
				PlayerStats.ammo_pistol = 0
	elif is_empty and PlayerStats.ammo_pistol_cur == 0 and PlayerStats.ammo_pistol > 0:
		is_reloading = true
		PlayerStats.reloading = true;
		gun_sprite.play("reload_empty")
		if PlayerStats.ammo_pistol_cur <= 0:
			if PlayerStats.ammo_pistol > 7:
				PlayerStats.ammo_pistol -= 7
				PlayerStats.ammo_pistol_cur = 7
			else:
				PlayerStats.ammo_pistol_cur = PlayerStats.ammo_pistol
				PlayerStats.ammo_pistol = 0
			
	if is_reloading:
		await gun_sprite.animation_finished
		is_reloading = false
		PlayerStats.reloading = false;
		
	

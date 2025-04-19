extends Node3D

var attacking = false
var hit_enemy = false
var timer = 0
var timer_val = 0.1
@onready var shape_cast: ShapeCast3D = $ShapeCast3D
var damage = 2
var fuel_cost = 1
@onready var gun_sprite = $CanvasLayer/Control/GunSprite
@onready var blood = preload("res://Particles/blood.tscn")
@onready var hit = preload("res://Particles/hit.tscn")
# Called when the node enters the scene tree for the first time.

func check_shape_hit():
	if shape_cast.enabled and shape_cast.is_colliding():
		for i in range(shape_cast.get_collision_count()):
			var hit_object = shape_cast.get_collider(i)  # Get each object collided
			if hit_object:
				print("Hit:", hit_object.name)  
				if hit_object.is_in_group("Enemy"):
					var new_blood = blood.instantiate()
					get_tree().current_scene.add_child(new_blood)
					new_blood.global_transform.origin = shape_cast.get_collision_point(0)
					new_blood.emitting = true
					hit_object.take_damage(damage)
				
					

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if Input.is_action_pressed("shoot") and PlayerStats.ammo_fuel > 0:
		gun_sprite.play("attack")
		fuel_cost = fuel_cost + delta
		if timer == timer_val:
			PlayerStats.change_fuel_ammo(-fuel_cost)
			attacking = true
			check_shape_hit()
		
		if attacking:
			timer -= delta
			
		if timer <= 0:
			attacking = false
			timer = timer_val
		
	else:
		fuel_cost = 1
		timer = timer_val
		attacking = false
		gun_sprite.play("idle")

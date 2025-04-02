extends Node3D

var can_shoot = true	
var can_attack = true
@onready var shape_cast: ShapeCast3D = $ShapeCast3D
@onready var hurt = preload("res://Player/Guns/muzzle_flash.tscn")
var damage = 15
@onready var gun_sprite = $CanvasLayer/Control/GunSprite
@onready var spawn_location = $Marker3D
@onready var projectile = preload("res://Player/Projectiles/demon_ball.tscn")
# Called when the node enters the scene tree for the first time.
func launch_projectile():
	var new_projectile = projectile.instantiate()
	get_tree().current_scene.add_child(new_projectile)
	new_projectile.global_transform = spawn_location.global_transform

func make_flash():
	var h = hurt.instantiate()
	add_child(h)

func check_shape_hit():
	if shape_cast.enabled and shape_cast.is_colliding():
		for i in range(shape_cast.get_collision_count()):
			var hit_object = shape_cast.get_collider(i)  # Get each object collided
			if hit_object and hit_object.is_in_group("Enemy"):
				var player = find_parent("Player")
				PlayerStats.heal = true
				PlayerStats.change_health(5)
				hit_object.take_damage(damage)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("shootRight") and can_shoot:
		gun_sprite.play("shoot")
		#make_flash()
		var player = find_parent("Player")
		PlayerStats.is_hit = true
		PlayerStats.reloading = true
		PlayerStats.take_damage(-10)
		launch_projectile()
		can_shoot = false
		can_attack = false
		await gun_sprite.animation_finished
		gun_sprite.play("idle")
		can_shoot = true
		can_attack = true
		PlayerStats.is_hit = false
		PlayerStats.reloading = false
	
	if Input.is_action_just_pressed("shoot") and can_attack:
		gun_sprite.play("attack")
		check_shape_hit()
		PlayerStats.reloading = true
		can_attack = false
		can_shoot = false
		await gun_sprite.animation_finished
		gun_sprite.play("idle")
		can_attack = true
		can_shoot = true
		PlayerStats.heal = false
		PlayerStats.reloading = false

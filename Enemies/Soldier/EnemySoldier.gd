extends CharacterBody3D

@onready var nav = get_tree().get_nodes_in_group("NavMesh")[0]
@onready var player = get_tree().get_nodes_in_group("Player")[0]
@onready var ray = $Visual

var path = []
var path_index = 0
var speed = 5
var health = 6	
var is_hit: bool = false
var shooting = false 
var is_aiming = false
var is_dead: bool = false
var searching = false
var damage = 5

var loot_table = [
	{"scene": preload("res://Player/Ammo/pistol_ammo.tscn"), "chance": 0.2},  
	{"scene": preload("res://Player/Potions/blood_vial.tscn"), "chance": 0.2},  
	{"scene": preload("res://Player/Ammo/shell.tscn"), "chance": 0.2},  
]


func _ready():
	is_dead = false
	set_collision_layer_value(2, false)  # Call this on CharacterBody3D
	$CollisionShape3D.get_parent().set_collision_layer_value(2, false)
	$AnimatedSprite3D.play("Idle")
	
func drop_loot():
	var loot_count = randi_range(1, 2)  # Adjust range for more/less drops
	for i in range(loot_count):
		var rand = randf()  # Get a random number between 0 and 1
		var cumulative_chance = 0
		for loot in loot_table:
			cumulative_chance += loot["chance"]
			if rand <= cumulative_chance:
				var dropped_item = loot["scene"].instantiate()  # Spawn the item`
				
				var drop_offset = Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0))
				dropped_item.global_transform.origin = global_transform.origin + drop_offset
				
				get_parent().add_child(dropped_item)
				
				#print("Dropping loot:", dropped_item, "Original name:", original_name, "Instance ID:", dropped_item.get_instance_id())
				break  # Stop after dropping one item



func _physics_process(delta):
	look_at_player()
	if searching and !shooting:
		if path_index < path.size():
			var direction = (path[path_index] - global_transform.origin)
			if direction.length() < 1:
				path_index += 1
			elif !is_hit:
				$AnimatedSprite3D.play("Walking")
				velocity = direction.normalized() * speed
				move_and_slide()
	else:
		if !shooting:
			$AnimatedSprite3D.play("Walking")
		
	if health <= 0 and !is_dead:
		death()
		is_dead = true

func look_at_player():
	ray.look_at(player.global_transform.origin)
	if ray.is_colliding():
		if ray.get_collider().is_in_group("Player"):
			searching =true
		else:
			searching = false
			var check_near = $Aural.get_overlapping_bodies()
			for body in check_near:
				if body.is_in_group("Player"):
					searching = true
	
func take_damage(damage):
	health -= damage
	#print("DMG: ", damage)
	if health > 0:
		is_hit = true
		searching = true
		$AnimatedSprite3D.play("Hit")
		await $AnimatedSprite3D.animation_finished
		is_hit = false
	
func find_path(target):
	var navigation_map = nav.get_navigation_map()
	path = NavigationServer3D.map_get_path(navigation_map, global_transform.origin, target, true)

	path_index = 0
	
func death():
	set_process(false)
	set_physics_process(false)
	$CollisionShape3D.disabled = true
	$ShootTimer.stop()
	shooting = false
	drop_loot()
	#print("HP: ",health)
	if health <= -6:
		$AnimatedSprite3D.play("Explode")
		#await $AnimatedSprite3D.animation_finished
		
	elif health > -6:
		$AnimatedSprite3D.play("Dead")
	
func shoot():
	if searching and !is_dead and !shooting and !is_hit:
		
		var miss_chance = 0  
		var will_hit = randf() > miss_chance
		
		$AnimatedSprite3D.play("Shoot")
		shooting = true
		await $AnimatedSprite3D.frame_changed
		var player_speed = player.velocity.length()  # Get player's current speed
		var base_hit_chance = 0.9  
		var speed_penalty = clamp(player_speed / 10.0, 0.0, 0.4)  # Reduce hit chance if moving fast
		print(base_hit_chance - speed_penalty)
		if ray.is_colliding() and randf() < (base_hit_chance - speed_penalty):
			if ray.get_collider().is_in_group("Player") and will_hit:	
				PlayerStats.change_health(-damage)
		if !is_dead:
			await $AnimatedSprite3D.animation_finished
		shooting = false


func _on_timer_timeout():
	find_path(player.global_transform.origin)


func _on_aural_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		searching = true


func _on_shoot_timer_timeout() -> void:
	shoot()

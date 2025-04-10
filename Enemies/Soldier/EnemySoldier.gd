extends CharacterBody3D

@onready var nav = get_tree().get_nodes_in_group("NavMesh")[0]
@onready var player = get_tree().get_nodes_in_group("Player")[0]

var path = []
var path_index = 0
var speed = 0
var health = 6	
var is_hit: bool = false
var is_dead: bool = false

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
	if path_index < path.size():
		var direction = (path[path_index] - global_transform.origin)
		if direction.length() < 1:
			path_index += 1
		elif !is_hit:
			$AnimatedSprite3D.play("Walking")
			velocity = direction.normalized() * speed
			move_and_slide()
		
	if health <= 0 and !is_dead:
		death()
		is_dead = true
	
func take_damage(damage):
	health -= damage
	print("DMG: ", damage)
	if health > 0:
		is_hit = true
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
	drop_loot()
	print("HP: ",health)
	if health <= -6:
		$AnimatedSprite3D.play("Explode")
		#await $AnimatedSprite3D.animation_finished
		
	elif health > -6:
		$AnimatedSprite3D.play("Dead")
	
func shoot(target):
	pass


func _on_timer_timeout():
	find_path(player.global_transform.origin)

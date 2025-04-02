extends Area3D

@onready var animated_sprite = $Ammo  # Reference to AnimatedSprite3D

func _ready():
	animated_sprite.play("idle")  # Play idle animation by default
	body_entered.connect(_on_body_entered)  # Detect when player enters area
	var expected_name = get_scene_file_path().get_file().get_basename()
	name = expected_name

func _on_body_entered(body):
	if body.is_in_group("Player"):
		var base_name = name.strip_edges()
		
		if PlayerStats.ammo_pistol != PlayerStats.ammo_max_pistol:
			if base_name.begins_with("pistol_ammo"):
				PlayerStats.change_pistol_ammo(7)
				queue_free()
			if base_name.begins_with("pistol_ammo_box"):
				PlayerStats.change_pistol_ammo(21)
				queue_free()
			
			
		if PlayerStats.ammo_shells != PlayerStats.ammo_max_shells:
			if base_name.begins_with("shell"):
				PlayerStats.change_shotgun_ammo(2)
				queue_free()
			if base_name.begins_with("shell_box"):
				PlayerStats.change_shotgun_ammo(10)
				queue_free()

			

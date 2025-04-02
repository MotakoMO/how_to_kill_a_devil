extends Area3D  # Allows collision-based detection

@onready var animated_sprite = $BloodVial  # Reference to AnimatedSprite3D

func _ready():
	animated_sprite.play("idle")  # Play idle animation by default
	body_entered.connect(_on_body_entered)  # Detect when player enters area
	var expected_name = get_scene_file_path().get_file().get_basename()
	name = expected_name
	

func _on_body_entered(body):
	if body.is_in_group("Player") and PlayerStats.health != PlayerStats.max_health:
		var base_name = name.strip_edges()
		if base_name.begins_with("blood_vial"):
			PlayerStats.change_health(5)
		if base_name.begins_with("blood_potion"):
			PlayerStats.change_health(10)
		if base_name.begins_with("blood_jar"):
			PlayerStats.change_health(20)
		if base_name.begins_with("blood_tank"):
			PlayerStats.change_health(40)
		queue_free()

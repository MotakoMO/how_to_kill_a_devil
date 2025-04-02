extends Area3D

var max_distance = 20
var start_position: Vector3
var projectile_speed = 15
var projectile_damage = 20
var projectile_splash_damage = 15

func _ready():
	await get_tree().process_frame
	start_position = global_transform.origin

func deal_damage():
	var enemies = get_overlapping_bodies()
	for body in enemies:
		if body.is_in_group("Enemy"):
			body.take_damage(projectile_damage)
	enemies = $Splash.get_overlapping_bodies()
	for body in enemies:
		if body.is_in_group("Enemy"):
			body.take_damage(projectile_splash_damage)

func _process(delta):
	translate(Vector3.FORWARD * projectile_speed * delta)
	var traveled_distance = global_transform.origin.distance_to(start_position)
	if traveled_distance > max_distance:
		explode()
	
func _on_body_entered(body):
	if body.is_in_group("Player"):
		return
	explode()

func _on_splash_body_entered(body):
	pass # Replace with function body.
	
func explode():	
	set_process(false)
	$AnimatedSprite3D.play("explode")
	deal_damage()
	await $AnimatedSprite3D.animation_finished
	queue_free()

extends Node
#Player variables
 
 
var health = 100
var max_health = 200
var armor = 0
var max_armor = 100
var guns_carried = []
var ammo_pistol = 7
var ammo_pistol_cur = 7
var ammo_shells = 20
var ammo_shells_cur = 2
var ammo_max_pistol = 49
var ammo_max_shells = 32
 
var red_key = false
var blue_key = false
var yellow_key = false
var current_gun = "Pistol"
var is_hit = false
var heal = false
var reloading = false
var shotgun_empty = false
var pistol_empty = false
 
func _ready():
	reloading = false

func reset():
	health = 100
	max_health = 200
	armor = 0
	max_armor = 100
	guns_carried = []
	ammo_pistol = 7
	ammo_pistol_cur = 7
	ammo_shells = 2
	ammo_shells_cur = 2
	ammo_max_pistol = 49
	ammo_max_shells = 32
	red_key = false
	blue_key = false
	yellow_key = false
	current_gun = "Pistol"
	is_hit = false
	heal = false
	reloading = false
	
func take_damage(amount):
	change_health(amount)
	
func change_health(amount):
	health += amount
	if health <= 0:
		pass
	health = clamp(health, 0, max_health)
	
func change_armor(amount):
	armor += amount
	armor = clamp(armor,0,max_armor)
	
func change_pistol_ammo(amount):
	if amount < 0:
		ammo_pistol_cur += amount
	else:
		ammo_pistol += amount
	ammo_pistol = clamp(ammo_pistol,0,ammo_max_pistol)
	
func change_shotgun_ammo(amount):
	if amount < 0:
		ammo_shells_cur+=amount
	else:
		ammo_shells+=amount
	ammo_shells = clamp(ammo_shells,0,ammo_max_shells)

func demon_claw_heal():
	pass
func demon_claw_ball():
	pass

func get_pistol_ammo():
	return str(ammo_pistol)
func get_pistol_ammo_cur():
	return str(ammo_pistol_cur)
 
func get_shotgun_ammo():
	return str(ammo_shells)
func get_shotgun_ammo_cur():
	return str(ammo_shells_cur)
	
func get_demon_claw():
	return str("demon")
func get_demon_ball():
	return str("demon_ball")
	
func get_health():
	return str(health)
 
func get_armor():
	return str(armor)

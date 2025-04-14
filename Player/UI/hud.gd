extends CanvasLayer

@onready var armor = $MarginContainer/Stats/Values/ArmorValue
@onready var health = $MarginContainer/Stats/Values/HealthValue
@onready var ammo = $MarginContainer/Stats/Ammo/AmmoValue
@onready var ammo_cur = $MarginContainer/Stats/Ammo/AmmoCurrent

func _process(delta):
	var current_gun = PlayerStats.current_gun
	armor.text = PlayerStats.get_armor()
	health.text = PlayerStats.get_health()
	if current_gun == "Pistol":
		ammo.visible = true
		ammo_cur.visible = true
		ammo.text = PlayerStats.get_pistol_ammo()
		ammo_cur.text = PlayerStats.get_pistol_ammo_cur()
	if current_gun == "Shotgun":
		ammo.visible = true
		ammo_cur.visible = true
		ammo.text = PlayerStats.get_shotgun_ammo()
		ammo_cur.text = PlayerStats.get_shotgun_ammo_cur()
	if current_gun == "Bolt_Rifle":
		ammo.visible = true
		ammo_cur.visible = true
		ammo.text = PlayerStats.get_bolt_ammo()
		ammo_cur.text = PlayerStats.get_bolt_ammo_cur()
	if current_gun == "Demon_Claw":
		ammo.visible = false
		ammo_cur.visible = false
		ammo.text = PlayerStats.get_demon_claw()
		ammo_cur.text = PlayerStats.get_demon_ball()
		#PlayerStats.take_damage(-10)

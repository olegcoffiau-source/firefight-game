extends CharacterBody2D

signal selected_changed(unit: Node2D, is_selected: bool)
signal unit_died(unit: Node2D)

@export var faction: String = "soviet"
@export var unit_type: String = "rifle"

var max_hp: float = 100.0
var current_hp: float = 100.0
var is_alive: bool = true
var is_selected: bool = false
var in_cover: bool = false
var cover_defense_multiplier: float = 1.0

var move_speed: float = 110.0
var attack_range: float = 480.0
var fire_rate: float = 1.8
var damage_per_shot: float = 38.0
var burst_count: int = 1
var sfx_name: String = "shot_rifle"

var target_destination: Vector2 = Vector2.ZERO
var has_destination: bool = false
var current_target: Node2D = null
var fire_cooldown: float = 0.0
var is_firing_anim: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var shadow: Sprite2D = $Shadow
@onready var selection_ring: Sprite2D = $SelectionRing
@onready var health_bar: ProgressBar = $HealthBar
@onready var muzzle_point: Marker2D = $MuzzlePoint

var textures: Dictionary = {}
var anim_timer: float = 0.0

func _ready() -> void:
	_init_unit_stats()
	_load_textures()
	_update_appearance("idle")
	selection_ring.visible = is_selected
	health_bar.max_value = max_hp
	health_bar.value = current_hp
	health_bar.visible = false
	fire_cooldown = randf_range(0.2, 1.0)

func _init_unit_stats() -> void:
	if faction == "soviet":
		selection_ring.texture = load("res://assets/sprites/ui/select_ring_green.png")
		match unit_type:
			"rifle":
				max_hp = 100.0
				move_speed = 105.0
				attack_range = 500.0
				fire_rate = 2.0
				damage_per_shot = 42.0
				burst_count = 1
				sfx_name = "shot_rifle"
			"smg":
				max_hp = 110.0
				move_speed = 120.0
				attack_range = 350.0
				fire_rate = 1.2
				damage_per_shot = 22.0
				burst_count = 3
				sfx_name = "shot_smg"
			"mg":
				max_hp = 130.0
				move_speed = 85.0
				attack_range = 580.0
				fire_rate = 1.5
				damage_per_shot = 28.0
				burst_count = 5
				sfx_name = "shot_mg"
			"officer":
				max_hp = 120.0
				move_speed = 115.0
				attack_range = 420.0
				fire_rate = 1.0
				damage_per_shot = 30.0
				burst_count = 2
				sfx_name = "shot_smg"
	else:
		selection_ring.texture = load("res://assets/sprites/ui/select_ring_red.png")
		match unit_type:
			"rifle":
				max_hp = 100.0
				move_speed = 105.0
				attack_range = 500.0
				fire_rate = 2.0
				damage_per_shot = 42.0
				burst_count = 1
				sfx_name = "shot_rifle"
			"smg":
				max_hp = 110.0
				move_speed = 120.0
				attack_range = 350.0
				fire_rate = 1.1
				damage_per_shot = 22.0
				burst_count = 3
				sfx_name = "shot_smg"
			"mg":
				max_hp = 130.0
				move_speed = 80.0
				attack_range = 600.0
				fire_rate = 1.4
				damage_per_shot = 28.0
				burst_count = 5
				sfx_name = "shot_mg"
			"officer":
				max_hp = 120.0
				move_speed = 115.0
				attack_range = 420.0
				fire_rate = 1.0
				damage_per_shot = 30.0
				burst_count = 2
				sfx_name = "shot_smg"
	current_hp = max_hp

func _load_textures() -> void:
	var prefix = "res://assets/sprites/" + faction + "/"
	if faction == "soviet":
		match unit_type:
			"rifle":
				textures["idle"] = load(prefix + "rifle_idle.png")
				textures["walk_1"] = load(prefix + "rifle_walk_1.png")
				textures["walk_2"] = load(prefix + "rifle_walk_2.png")
				textures["shoot"] = load(prefix + "rifle_shoot.png")
			"smg":
				textures["idle"] = load(prefix + "smg_idle.png")
				textures["walk_1"] = load(prefix + "smg_walk_1.png")
				textures["walk_2"] = load(prefix + "smg_walk_2.png")
				textures["shoot"] = load(prefix + "smg_shoot.png")
			"mg":
				textures["idle"] = load(prefix + "mg_idle.png")
				textures["walk_1"] = load(prefix + "mg_walk.png")
				textures["walk_2"] = load(prefix + "mg_walk.png")
				textures["shoot"] = load(prefix + "mg_shoot.png")
			"officer":
				textures["idle"] = load(prefix + "officer.png")
				textures["walk_1"] = load(prefix + "officer.png")
				textures["walk_2"] = load(prefix + "officer.png")
				textures["shoot"] = load(prefix + "crouch.png")
	else:
		match unit_type:
			"rifle":
				textures["idle"] = load(prefix + "rifle_idle.png")
				textures["walk_1"] = load(prefix + "rifle_walk_1.png")
				textures["walk_2"] = load(prefix + "rifle_walk_2.png")
				textures["shoot"] = load(prefix + "rifle_shoot.png")
			"smg":
				textures["idle"] = load(prefix + "smg_idle.png")
				textures["walk_1"] = load(prefix + "smg_walk_1.png")
				textures["walk_2"] = load(prefix + "smg_walk_2.png")
				textures["shoot"] = load(prefix + "smg_shoot.png")
			"mg":
				textures["idle"] = load(prefix + "mg_walk.png")
				textures["walk_1"] = load(prefix + "mg_walk.png")
				textures["walk_2"] = load(prefix + "mg_walk.png")
				textures["shoot"] = load(prefix + "mg_shoot.png")
			"officer":
				textures["idle"] = load(prefix + "officer.png")
				textures["walk_1"] = load(prefix + "officer.png")
				textures["walk_2"] = load(prefix + "officer.png")
				textures["shoot"] = load(prefix + "crouch_shoot.png")

func _process(delta: float) -> void:
	if not is_alive:
		return
		
	fire_cooldown = max(0.0, fire_cooldown - delta)
	
	if is_firing_anim > 0:
		is_firing_anim -= delta
		_update_appearance("shoot")
	elif has_destination:
		anim_timer += delta * 8.0
		if int(anim_timer) % 2 == 0:
			_update_appearance("walk_1")
		else:
			_update_appearance("walk_2")
	else:
		_update_appearance("idle")

func _physics_process(delta: float) -> void:
	if not is_alive:
		return
		
	if has_destination:
		var dist = global_position.distance_to(target_destination)
		if dist < 8.0:
			has_destination = false
			velocity = Vector2.ZERO
		else:
			var dir = (target_destination - global_position).normalized()
			velocity = dir * move_speed
			if dir.x != 0:
				sprite.flip_h = dir.x < 0
		move_and_slide()
	else:
		velocity = Vector2.ZERO

	_handle_combat_ai(delta)

func _handle_combat_ai(delta: float) -> void:
	if current_target and (not is_instance_valid(current_target) or not current_target.is_alive):
		current_target = null
		
	if not current_target:
		current_target = _find_nearest_enemy()
		
	if current_target and is_instance_valid(current_target) and current_target.is_alive:
		var dist = global_position.distance_to(current_target.global_position)
		if dist <= attack_range:
			var dir = (current_target.global_position - global_position).normalized()
			if dir.x != 0:
				sprite.flip_h = dir.x < 0
				
			if fire_cooldown <= 0.0:
				_fire_at_target(current_target)
		elif faction == "german" and not has_destination:
			if dist < attack_range * 1.5:
				move_to(current_target.global_position + Vector2(randf_range(-60, 60), randf_range(-60, 60)))

func _find_nearest_enemy() -> Node2D:
	var parent = get_parent()
	if not parent:
		return null
	var units = parent.get_tree().get_nodes_in_group("units")
	var nearest: Node2D = null
	var min_dist: float = attack_range * 1.8
	for u in units:
		if u != self and u.is_alive and u.faction != faction:
			var d = global_position.distance_to(u.global_position)
			if d < min_dist:
				min_dist = d
				nearest = u
	return nearest

func _fire_at_target(target: Node2D) -> void:
	fire_cooldown = fire_rate + randf_range(-0.15, 0.15)
	is_firing_anim = 0.25
	
	for i in range(burst_count):
		if not is_alive:
			return
		if i > 0:
			await get_tree().create_timer(0.08).timeout
			if not is_alive or not is_instance_valid(target) or not target.is_alive:
				return
				
		SoundManager.play_sound(sfx_name, 0.12, -2.0)
		
		var bullet = preload("res://scenes/bullet.tscn").instantiate()
		get_parent().add_child(bullet)
		var spawn_pos = global_position + Vector2(0, -12)
		bullet.setup(spawn_pos, target.global_position + Vector2(0, -10), faction, damage_per_shot)
		
		var fx = preload("res://scenes/fx.tscn").instantiate()
		get_parent().add_child(fx)
		fx.global_position = spawn_pos
		fx.setup_fx("muzzle_flash", 0.08)

func take_damage(dmg: float, hit_pos: Vector2) -> void:
	if not is_alive:
		return
	var actual_dmg = dmg * cover_defense_multiplier
	current_hp -= actual_dmg
	health_bar.value = current_hp
	health_bar.visible = true
	
	SoundManager.play_sound("hit", 0.15, -4.0)
	
	var blood = preload("res://scenes/fx.tscn").instantiate()
	get_parent().add_child(blood)
	blood.global_position = global_position + Vector2(randf_range(-6, 6), randf_range(-4, 4))
	blood.setup_fx("blood", 15.0)
	
	if current_hp <= 0:
		die()

func die() -> void:
	is_alive = false
	has_destination = false
	is_selected = false
	selection_ring.visible = false
	health_bar.visible = false
	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(0.4, 0.4, 0.4, 0.8), 0.3)
	tween.tween_property(sprite, "rotation", PI / 2.0 if randf() > 0.5 else -PI / 2.0, 0.2)
	tween.parallel().tween_property(shadow, "modulate:a", 0.0, 0.3)
	
	unit_died.emit(self)
	remove_from_group("units")

func move_to(pos: Vector2) -> void:
	if not is_alive:
		return
	target_destination = pos
	has_destination = true

func set_selected(selected: bool) -> void:
	is_selected = selected
	selection_ring.visible = selected and is_alive
	health_bar.visible = (selected or current_hp < max_hp) and is_alive
	selected_changed.emit(self, is_selected)

func _update_appearance(state: String) -> void:
	if textures.has(state) and textures[state] != null:
		sprite.texture = textures[state]
	elif textures.has("idle"):
		sprite.texture = textures["idle"]

func get_save_data() -> Dictionary:
	return {
		"faction": faction,
		"unit_type": unit_type,
		"pos_x": global_position.x,
		"pos_y": global_position.y,
		"hp": current_hp,
		"max_hp": max_hp,
		"is_alive": is_alive
	}

func load_save_data(data: Dictionary) -> void:
	faction = data.get("faction", faction)
	unit_type = data.get("unit_type", unit_type)
	global_position = Vector2(data.get("pos_x", 0), data.get("pos_y", 0))
	max_hp = data.get("max_hp", 100.0)
	current_hp = data.get("hp", max_hp)
	is_alive = data.get("is_alive", true)
	_init_unit_stats()
	_load_textures()
	_update_appearance("idle")
	health_bar.max_value = max_hp
	health_bar.value = current_hp
	if not is_alive:
		die()

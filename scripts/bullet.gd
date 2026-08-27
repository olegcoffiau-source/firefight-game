extends Node2D

var speed: float = 1200.0
var damage: float = 25.0
var direction: Vector2 = Vector2.ZERO
var shooter_faction: String = ""
var target_pos: Vector2 = Vector2.ZERO
var max_distance: float = 800.0
var traveled: float = 0.0

func setup(start_pos: Vector2, target: Vector2, faction: String, dmg: float) -> void:
	global_position = start_pos
	target_pos = target
	shooter_faction = faction
	damage = dmg
	var diff = target - start_pos
	direction = diff.normalized()
	direction = direction.rotated(randf_range(-0.06, 0.06))
	rotation = direction.angle()
	max_distance = max(400.0, diff.length() + 150.0)

func _process(delta: float) -> void:
	var step = speed * delta
	global_position += direction * step
	traveled += step
	
	if traveled >= max_distance:
		queue_free()
		return
		
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = global_position
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	var results = space_state.intersect_point(query, 8)
	for r in results:
		var collider = r.collider
		var unit = collider.get_parent() if collider is Area2D else collider
		if unit and unit.has_method("take_damage") and unit.is_alive:
			if unit.faction != shooter_faction:
				unit.take_damage(damage, global_position)
				_spawn_hit_fx()
				queue_free()
				return

func _spawn_hit_fx() -> void:
	var fx = preload("res://scenes/fx.tscn").instantiate()
	get_parent().add_child(fx)
	fx.global_position = global_position
	fx.setup_fx("hit_spark", 0.15)

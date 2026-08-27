extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

var lifetime: float = 0.5
var timer: float = 0.0
var fade_out: bool = true

func setup_fx(type: String, duration: float = 0.4) -> void:
	lifetime = duration
	match type:
		"muzzle_flash":
			sprite.texture = load("res://assets/sprites/effects/muzzle_flash_1.png")
			scale = Vector2(0.6, 0.6)
			lifetime = 0.08
			fade_out = false
		"hit_spark":
			sprite.texture = load("res://assets/sprites/effects/hit_spark.png")
			scale = Vector2(0.5, 0.5)
			lifetime = 0.15
			fade_out = true
		"blood":
			sprite.texture = load("res://assets/sprites/effects/blood_splat.png")
			scale = Vector2(0.5, 0.5)
			rotation = randf_range(0, TAU)
			lifetime = 12.0
			fade_out = true
		"explosion":
			sprite.texture = load("res://assets/sprites/effects/explosion.png")
			scale = Vector2(0.8, 0.8)
			lifetime = 0.5
			fade_out = true
		"order_ring":
			sprite.texture = load("res://assets/sprites/ui/select_ring_green.png")
			scale = Vector2(0.4, 0.4)
			lifetime = 0.6
			fade_out = true

func _process(delta: float) -> void:
	timer += delta
	if timer >= lifetime:
		queue_free()
		return
	if fade_out:
		var progress = timer / lifetime
		if progress > 0.5:
			modulate.a = 1.0 - ((progress - 0.5) / 0.5)

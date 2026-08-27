extends Control

@onready var btn_new_game: Button = $UI/CenterContainer/VBoxContainer/BtnNewGame
@onready var btn_continue: Button = $UI/CenterContainer/VBoxContainer/BtnContinue
@onready var btn_exit: Button = $UI/CenterContainer/VBoxContainer/BtnExit
@onready var confirm_dialog: ConfirmationDialog = $ConfirmDialog

func _ready() -> void:
	update_buttons()
	btn_new_game.pressed.connect(_on_new_game_pressed)
	btn_continue.pressed.connect(_on_continue_pressed)
	btn_exit.pressed.connect(_on_exit_pressed)
	confirm_dialog.confirmed.connect(_on_confirm_new_game)
	
	$UI.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property($UI, "modulate:a", 1.0, 0.4)

func update_buttons() -> void:
	var can_continue = GameManager.has_saved_game()
	btn_continue.disabled = not can_continue
	if not can_continue:
		btn_continue.modulate = Color(0.6, 0.6, 0.6, 0.6)
	else:
		btn_continue.modulate = Color(1, 1, 1, 1)

func _on_new_game_pressed() -> void:
	SoundManager.play_sound("click")
	if GameManager.has_saved_game():
		confirm_dialog.popup_centered()
	else:
		_start_new()

func _on_confirm_new_game() -> void:
	SoundManager.play_sound("click")
	_start_new()

func _start_new() -> void:
	var tween = create_tween()
	tween.tween_property($UI, "modulate:a", 0.0, 0.25)
	await tween.finished
	GameManager.start_new_game()

func _on_continue_pressed() -> void:
	SoundManager.play_sound("click")
	var tween = create_tween()
	tween.tween_property($UI, "modulate:a", 0.0, 0.25)
	await tween.finished
	GameManager.continue_game()

func _on_exit_pressed() -> void:
	SoundManager.play_sound("click")
	get_tree().quit()

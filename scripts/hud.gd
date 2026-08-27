extends CanvasLayer

signal select_all_pressed
signal pause_menu_pressed
signal zoom_in_pressed
signal zoom_out_pressed
signal restart_pressed
signal exit_to_menu_pressed

@onready var lbl_soviet_count: Label = $TopBar/HBox/SovietInfo/Count
@onready var lbl_german_count: Label = $TopBar/HBox/GermanInfo/Count
@onready var selected_panel: PanelContainer = $BottomBar/SelectedPanel
@onready var lbl_unit_type: Label = $BottomBar/SelectedPanel/VBox/UnitType
@onready var lbl_unit_hp: Label = $BottomBar/SelectedPanel/VBox/HP
@onready var btn_select_all: Button = $BottomBar/BtnSelectAll
@onready var btn_zoom_in: Button = $RightControls/BtnZoomIn
@onready var btn_zoom_out: Button = $RightControls/BtnZoomOut
@onready var btn_pause: Button = $TopBar/BtnPause

@onready var pause_modal: Control = $PauseModal
@onready var game_over_modal: Control = $GameOverModal
@onready var lbl_game_over_title: Label = $GameOverModal/Center/Panel/VBox/Title
@onready var lbl_game_over_desc: Label = $GameOverModal/Center/Panel/VBox/Desc

func _ready() -> void:
	pause_modal.visible = false
	game_over_modal.visible = false
	selected_panel.visible = false
	
	btn_select_all.pressed.connect(func(): SoundManager.play_sound("click"); select_all_pressed.emit())
	btn_zoom_in.pressed.connect(func(): SoundManager.play_sound("click"); zoom_in_pressed.emit())
	btn_zoom_out.pressed.connect(func(): SoundManager.play_sound("click"); zoom_out_pressed.emit())
	btn_pause.pressed.connect(_toggle_pause)
	
	$PauseModal/Center/Panel/VBox/BtnResume.pressed.connect(_toggle_pause)
	$PauseModal/Center/Panel/VBox/BtnSaveExit.pressed.connect(func(): SoundManager.play_sound("click"); exit_to_menu_pressed.emit())
	$GameOverModal/Center/Panel/VBox/BtnRestart.pressed.connect(func(): SoundManager.play_sound("click"); restart_pressed.emit())
	$GameOverModal/Center/Panel/VBox/BtnMenu.pressed.connect(func(): SoundManager.play_sound("click"); exit_to_menu_pressed.emit())

func update_counts(soviet_count: int, german_count: int) -> void:
	lbl_soviet_count.text = str(soviet_count)
	lbl_german_count.text = str(german_count)

func update_selection_info(selected_units: Array) -> void:
	if selected_units.size() == 0:
		selected_panel.visible = false
	elif selected_units.size() == 1:
		selected_panel.visible = true
		var u = selected_units[0]
		var type_str = "Пехотинец"
		match u.unit_type:
			"rifle": type_str = "Стрелок (Винтовка)"
			"smg": type_str = "Автоматчик (ППШ)"
			"mg": type_str = "Пулеметчик (ДП-27)"
			"officer": type_str = "Командир отделения"
		lbl_unit_type.text = type_str
		lbl_unit_hp.text = "Здоровье: %d / %d" % [int(u.current_hp), int(u.max_hp)]
	else:
		selected_panel.visible = true
		lbl_unit_type.text = "Выбрано бойцов: %d" % selected_units.size()
		var total_hp = 0
		for u in selected_units:
			total_hp += int(u.current_hp)
		lbl_unit_hp.text = "Суммарно HP: %d" % total_hp

func _toggle_pause() -> void:
	SoundManager.play_sound("click")
	var is_paused = not get_tree().paused
	get_tree().paused = is_paused
	pause_modal.visible = is_paused

func show_game_over(victory: bool, soviet_lost: int, german_lost: int) -> void:
	game_over_modal.visible = true
	if victory:
		lbl_game_over_title.text = "ПОБЕДА!"
		lbl_game_over_title.modulate = Color(0.3, 0.9, 0.3, 1)
		lbl_game_over_desc.text = "Силы противника разбиты!\nПотери РККА: %d\nУничтожено врагов: %d" % [soviet_lost, german_lost]
		SoundManager.play_sound("victory", 0.0, 2.0)
	else:
		lbl_game_over_title.text = "ПОРАЖЕНИЕ"
		lbl_game_over_title.modulate = Color(0.9, 0.3, 0.3, 1)
		lbl_game_over_desc.text = "Наши подразделения понесли критические потери.\nПотери РККА: %d\nУничтожено врагов: %d" % [soviet_lost, german_lost]
		SoundManager.play_sound("defeat", 0.0, 2.0)

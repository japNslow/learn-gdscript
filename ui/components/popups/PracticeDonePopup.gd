extends ColorRect

signal accepted

const FADE_DURATION := 0.25

var _raw_summary := ""
var do_fade_background_on_exit := true

@onready var _layout_container := $Layout as Container
@onready var _game_anchors := $Layout/GameAnchors as Control
@onready var _game_container := $Layout/GameAnchors/GameContainer as Control
@onready var _game_texture := (
	$Layout/GameAnchors/GameContainer/MarginContainer/TextureRect as TextureRect
)
@onready var _message_anchors := $Layout/WellDoneAnchors as Control
@onready var _message_container := $Layout/WellDoneAnchors/PanelContainer as PanelContainer

@onready var _move_on_button := (
	$Layout/WellDoneAnchors/PanelContainer/Layout/Margin/Column/Buttons/MoveOnButton as Button
)
@onready var _stay_button := (
	$Layout/WellDoneAnchors/PanelContainer/Layout/Margin/Column/Buttons/StayButton as Button
)

@onready var _summary2_label := (
	$Layout/WellDoneAnchors/PanelContainer/Layout/Margin/Column/Summary2 as RichTextLabel
)

var _scene_tween: Tween


func _ready() -> void:
	set_as_top_level(true)
	visible = false

	_reset_offsets(_message_container)
	_reset_offsets(_game_container)
	if _game_anchors:
		_game_anchors.visible = false
		_game_anchors.custom_minimum_size = Vector2.ZERO

	# BBCode text is not autotranslated, so we do this to preserve the initial value.
	# FIXME: Some weird Windows issue, replace before translating so matching works.
	_raw_summary = _summary2_label.text.replace("\r\n", "\n")
	_summary2_label.text = tr(_raw_summary)

	_move_on_button.pressed.connect(fade_out)
	_stay_button.pressed.connect(hide)


func _reset_offsets(control: Control) -> void:
	if not control:
		return
	control.offset_left = 0.0
	control.offset_right = 0.0
	control.offset_top = 0.0
	control.offset_bottom = 0.0


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		if is_instance_valid(_summary2_label):
			_summary2_label.text = tr(_raw_summary)


func fade_in(_game_container: Control = null) -> void:
	if _scene_tween:
		_scene_tween.kill()

	position = Vector2.ZERO
	size = get_viewport_rect().size
	z_index = 100
	z_as_relative = false

	_reset_offsets(_message_container)
	if _game_anchors:
		_game_anchors.visible = false
		_game_anchors.custom_minimum_size = Vector2.ZERO

	_layout_container.reset_size()
	_layout_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
	_layout_container.pivot_offset = _layout_container.size / 2

	modulate.a = 0.0
	show()

	_scene_tween = create_tween().set_parallel()
	_scene_tween.tween_property(self, "modulate:a", 1.0, FADE_DURATION).from(0.0)
	_scene_tween.tween_property(_layout_container, "scale", Vector2.ONE, FADE_DURATION).from(Vector2(0.9, 0.9)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	_move_on_button.grab_focus()


func fade_out() -> void:
	if _scene_tween:
		_scene_tween.kill()

	_scene_tween = create_tween().set_parallel()
	_scene_tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION).from(1.0)
	_scene_tween.tween_property(_layout_container, "scale", Vector2(0.9, 0.9), FADE_DURATION).from(Vector2.ONE).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	_scene_tween.chain().tween_callback(_on_fade_out_completed)


func _on_fade_out_completed() -> void:
	hide()
	modulate.a = 1.0
	accepted.emit()

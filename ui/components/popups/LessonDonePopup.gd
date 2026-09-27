extends ColorRect

signal accepted

const FADE_IN_DURATION := 0.25
const FADE_IN_START_SCALE := 0.5

var _raw_summary := ""

@onready var _popup_container := $PanelContainer as Control
@onready var _incomplete_summary := $PanelContainer/Layout/Margin/Column/IncompleteSummary as Label
@onready var _move_on_button := $PanelContainer/Layout/Margin/Column/Buttons/MoveOnButton as Button
@onready var _stay_button := $PanelContainer/Layout/Margin/Column/Buttons/StayButton as Button

@onready var _summary_label := $PanelContainer/Layout/Margin/Column/Summary as RichTextLabel

@onready var _particles := $Particles as CPUParticles2D
@onready var _thick_particles := $ThickParticles as CPUParticles2D


var _scene_tween: Tween


func _ready() -> void:
	set_as_top_level(true)
	visible = false

	# BBCode text is not autotranslated, so we do this to preserve the initial value.
	# FIXME: Some weird Windows issue, replace before translating so matching works.
	_raw_summary = _summary_label.text.replace("\r\n", "\n")
	_summary_label.text = tr(_raw_summary)

	_move_on_button.pressed.connect(_on_button_pressed)
	_stay_button.pressed.connect(hide)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		if is_instance_valid(_summary_label):
			_summary_label.text = tr(_raw_summary)


func set_incomplete(incomplete: bool) -> void:
	_incomplete_summary.visible = incomplete


func popup_centered() -> void:
	if _scene_tween:
		_scene_tween.kill()

	position = Vector2.ZERO
	size = get_viewport_rect().size
	z_index = 100
	z_as_relative = false

	_particles.position = size / 2
	_thick_particles.position = size / 2

	_popup_container.reset_size()
	_popup_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
	_popup_container.pivot_offset = _popup_container.size / 2

	modulate.a = 0.0
	show()

	_scene_tween = create_tween().set_parallel()
	_scene_tween.tween_property(self, "modulate:a", 1.0, FADE_IN_DURATION).from(0.0)
	_scene_tween.tween_property(_popup_container, "scale", Vector2.ONE, FADE_IN_DURATION).from(Vector2(FADE_IN_START_SCALE, FADE_IN_START_SCALE)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	_move_on_button.grab_focus()


func _on_button_pressed() -> void:
	if _scene_tween:
		_scene_tween.kill()

	_scene_tween = create_tween().set_parallel()
	_scene_tween.tween_property(self, "modulate:a", 0.0, FADE_IN_DURATION).from(1.0)
	_scene_tween.chain().tween_callback(func():
		hide()
		modulate.a = 1.0
		accepted.emit()
	)

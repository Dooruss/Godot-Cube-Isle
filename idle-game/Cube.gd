extends Area2D

signal cube_clicked(amount: int)
signal passive_tick(amount: int)

# @onready = GetComponent in Start()
@onready var color_rect:    ColorRect = $ColorRect
@onready var passive_timer: Timer     = $PassiveTimer
@onready var click_label:   Label     = $ClickLabel

var click_value:   int = 1
var passive_value: int = 1
var _tween: Tween


func _ready() -> void:
	passive_timer.wait_time = 1.0
	passive_timer.autostart = true
	passive_timer.start()
	click_label.visible = false


# Called right after instantiate() — like setting up a prefab before adding to the scene
func setup(col: Color, click_val: int, passive_val: int) -> void:
	color_rect.color = col
	click_value      = click_val
	passive_value    = passive_val


func on_clicked() -> void:
	emit_signal("cube_clicked", click_value)
	_wiggle()
	_show_click_label(click_value)


# Fires every second — same as InvokeRepeating
func _on_passive_timer_timeout() -> void:
	emit_signal("passive_tick", passive_value)


func _wiggle() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", Vector2(1.3, 0.75), 0.07)
	_tween.tween_property(self, "scale", Vector2(1.0, 1.0),  0.30)


func _show_click_label(amount: int) -> void:
	click_label.text       = "+%d" % amount
	click_label.modulate.a = 1.0
	click_label.visible    = true

	var origin_y := click_label.position.y
	var pop := create_tween()
	pop.tween_property(click_label, "position:y", origin_y - 36.0, 0.5)
	pop.parallel().tween_property(click_label, "modulate:a", 0.0, 0.5)
	await pop.finished

	click_label.position.y = origin_y
	click_label.visible    = false


func apply_upgrades(new_click_val: int, new_passive_val: int) -> void:
	click_value   = new_click_val
	passive_value = new_passive_val

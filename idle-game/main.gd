extends Node2D

const CUBE_SCENE   := preload("res://Cube.tscn")
const CUBE_COLUMNS := 6
const CUBE_SPACING := 80
const GRID_X       := 210


# CubeType acts like a C# data class — one instance per tier
class CubeType:
	var label:                String
	var color:                Color
	var buy_cost:             int
	var count:                int = 0

	var base_passive:         int
	var passive_level:        int = 0
	var passive_upgrade_cost: int

	var grid_y: int

	func _init(p_label: String, p_color: Color, p_buy: int,
			   p_passive: int, p_passive_cost: int, p_grid_y: int) -> void:
		label                = p_label
		color                = p_color
		buy_cost             = p_buy
		base_passive         = p_passive
		passive_upgrade_cost = p_passive_cost
		grid_y               = p_grid_y

	func passive_value() -> int: return base_passive + passive_level


# @onready = GetComponent in Start()
@onready var coin_label:     Label         = $UI/CoinLabel
@onready var info_label:     Label         = $UI/InfoLabel
@onready var button_list:    VBoxContainer = $UI/ScrollContainer/ButtonList
@onready var cube_container: Node2D        = $CubeContainer
@onready var camera:         Camera2D      = $Camera2D

var coins: int = 0
var cube_types: Array = []

# Global click upgrade — one button, affects the earn button and all cubes
var click_level:        int = 0
var click_upgrade_cost: int = 25
var click_value:        int = 1

# Sidebar button references
var earn_button:         Button
var click_upgrade_button: Button
var buy_buttons:     Array = []
var passive_buttons: Array = []


func _ready() -> void:
	cube_types = [
		CubeType.new("Blue",  Color(0.18, 0.55, 0.95),  50,    1,   100,  80),
		CubeType.new("Green", Color(0.22, 0.78, 0.32),  500,   5,   500,  80 + 4 * CUBE_SPACING),
		CubeType.new("Red",   Color(0.90, 0.22, 0.22),  5000,  25,  3000, 80 + 8 * CUBE_SPACING),
	]
	_build_ui()
	# Start camera centred on the viewport
	var vp := get_viewport_rect().size
	camera.position = Vector2(vp.x * 0.5, vp.y * 0.5)


func _process(_delta: float) -> void:
	_refresh_ui()
	_update_camera()


func _build_ui() -> void:
	earn_button = _add_button("Click [+1]")
	earn_button.pressed.connect(_on_earn_pressed)

	click_upgrade_button = _add_button("")
	click_upgrade_button.pressed.connect(_on_buy_click_upgrade)

	for i in cube_types.size():
		var type = cube_types[i]

		var lbl := Label.new()
		lbl.text = type.label + " Cubes"
		button_list.add_child(lbl)

		var buy_btn     := _add_button("")
		var passive_btn := _add_button("")

		# Capture i by value — same closure gotcha as foreach in C#
		var idx := i
		buy_btn.pressed.connect(    func(): _buy_cube(idx))
		passive_btn.pressed.connect(func(): _buy_passive_upgrade(idx))

		buy_buttons.append(buy_btn)
		passive_buttons.append(passive_btn)


func _add_button(txt: String) -> Button:
	var btn := Button.new()
	btn.text                = txt
	btn.custom_minimum_size = Vector2(0, 38)
	button_list.add_child(btn)
	return btn


func _refresh_ui() -> void:
	var total_cps:   int = 0
	var total_cubes: int = 0
	for type in cube_types:
		total_cps   += type.count * type.passive_value()
		total_cubes += type.count

	coin_label.text = "Coins: %d\n+%d/sec" % [coins, total_cps]
	info_label.text = "Cubes: %d" % total_cubes

	earn_button.text          = "Click [+%d]" % click_value
	click_upgrade_button.text = "Click Upgrade Lv%d  [$%d]" % [click_level + 1, click_upgrade_cost]
	click_upgrade_button.disabled = coins < click_upgrade_cost

	for i in cube_types.size():
		var t = cube_types[i]
		buy_buttons[i].text     = "Buy %s  [$%d]"       % [t.label, t.buy_cost]
		passive_buttons[i].text = "Idle+ Lv%d  [$%d]"   % [t.passive_level + 1, t.passive_upgrade_cost]

		buy_buttons[i].disabled     = coins < t.buy_cost
		passive_buttons[i].disabled = coins < t.passive_upgrade_cost


func _on_earn_pressed() -> void:
	coins += click_value


func _on_buy_click_upgrade() -> void:
	if coins < click_upgrade_cost:
		return
	coins              -= click_upgrade_cost
	click_level        += 1
	click_value         = 1 + (click_level * click_level)
	click_upgrade_cost  = int(click_upgrade_cost * 2.0)
	# Push the new click value to every cube regardless of type
	for child in cube_container.get_children():
		if child.has_method("apply_upgrades"):
			var tidx: int = child.get_meta("type_idx", 0)
			child.apply_upgrades(click_value, cube_types[tidx].passive_value())


func _buy_cube(idx: int) -> void:
	var type = cube_types[idx]
	if coins < type.buy_cost:
		return
	coins         -= type.buy_cost
	type.buy_cost  = int(type.buy_cost * 1.35)
	_spawn_cube(type, idx)


func _buy_passive_upgrade(idx: int) -> void:
	var type = cube_types[idx]
	if coins < type.passive_upgrade_cost:
		return
	coins                     -= type.passive_upgrade_cost
	type.passive_level        += 1
	type.passive_upgrade_cost  = int(type.passive_upgrade_cost * 2.2)
	for child in cube_container.get_children():
		if child.has_method("apply_upgrades") and child.get_meta("type_idx", -1) == idx:
			child.apply_upgrades(click_value, type.passive_value())


func _spawn_cube(type, idx: int) -> void:
	var cube: Area2D = CUBE_SCENE.instantiate()  # instantiate() = Instantiate(prefab)

	var col: int = type.count % CUBE_COLUMNS
	var row: int = type.count / CUBE_COLUMNS
	cube.position = Vector2(GRID_X + col * CUBE_SPACING, type.grid_y + row * CUBE_SPACING)

	cube_container.add_child(cube)  # add_child = transform.SetParent
	cube.setup(type.color, click_value, type.passive_value())

	cube.cube_clicked.connect(_on_cube_clicked)
	cube.passive_tick.connect(_on_cube_passive_tick)

	cube.input_pickable = true
	cube.connect("input_event", _make_cube_click_handler(cube))

	# set_meta = storing extra data on a node, like a small extra component
	cube.set_meta("type_idx", idx)

	type.count += 1


func _make_cube_click_handler(cube: Area2D) -> Callable:
	return func(_vp, event: InputEvent, _shape):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			cube.on_clicked()


func _on_cube_clicked(amount: int) -> void:
	coins += amount


func _on_cube_passive_tick(amount: int) -> void:
	coins += amount


# Zooms the camera out if any cube would be off-screen.
# Works like adjusting Camera.orthographicSize in Unity.
func _update_camera() -> void:
	var vp := get_viewport_rect().size

	# Start from viewport height so we never zoom in past 1:1
	var max_y := vp.y
	for child in cube_container.get_children():
		var node := child as Node2D
		if node:
			max_y = max(max_y, node.position.y + float(CUBE_SPACING) * 1.5)

	# zoom = vp_height / world_height_needed  (shrinks below 1.0 to zoom out)
	var target_zoom: float = clamp(vp.y / max_y, 0.2, 1.0)

	# Camera Y centres on the full content area
	var target_y: float = max_y * 0.5

	# lerp = Mathf.Lerp — smooth transition each frame
	camera.zoom       = camera.zoom.lerp(Vector2(target_zoom, target_zoom), 0.05)
	camera.position.y = lerpf(camera.position.y, target_y, 0.05)

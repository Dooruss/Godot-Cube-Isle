extends Node2D

# preload = Resources.Load<GameObject>("path"), loads the Cube prefab
const CUBE_SCENE := preload("res://Cube.tscn")

# @onready = GetComponent / Find called in Start()
@onready var coin_label:             Label  = $UI/CoinLabel
@onready var info_label:             Label  = $UI/InfoLabel
@onready var earn_button:            Button = $UI/EarnButton
@onready var buy_cube_button:        Button = $UI/BuyCubeButton
@onready var click_upgrade_button:   Button = $UI/ClickUpgradeButton
@onready var passive_upgrade_button: Button = $UI/PassiveUpgradeButton

# CubeContainer is an empty Node2D used as a parent folder for spawned cubes
# Same pattern as an empty GameObject used as a container in Unity
@onready var cube_container: Node2D = $CubeContainer

var coins: int       = 0
var cubes_owned: int = 0

var click_upgrade_level:   int = 0
var passive_upgrade_level: int = 0

# These are recalculated after every upgrade and pushed to all cubes
var click_value:   int = 1
var passive_value: int = 1

var cube_cost:            int = 50
var click_upgrade_cost:   int = 25
var passive_upgrade_cost: int = 100

# Grid layout for cube placement
const CUBE_COLUMNS: int    = 6
const CUBE_SPACING: int    = 80
const GRID_ORIGIN: Vector2 = Vector2(140, 80)


# _ready = Start()
func _ready() -> void:
	_refresh_ui()


# _process = Update() only used to keep the coin label updated
func _process(_delta: float) -> void:
	_refresh_ui()


func _refresh_ui() -> void:
	var cps := cubes_owned * passive_value
	coin_label.text = "Coins: %d  (+%d/sec)" % [coins, cps]
	info_label.text = "Cubes: %d" % cubes_owned

	earn_button.text            = "Click  [+%d]" % click_value
	buy_cube_button.text        = "Buy Cube  [$%d]" % cube_cost
	click_upgrade_button.text   = "Click Upgrade Lv%d  [$%d]" % [click_upgrade_level + 1, click_upgrade_cost]
	passive_upgrade_button.text = "Passive Upgrade Lv%d  [$%d]" % [passive_upgrade_level + 1, passive_upgrade_cost]

	# Disable buttons the player cant buy
	buy_cube_button.disabled        = coins < cube_cost
	click_upgrade_button.disabled   = coins < click_upgrade_cost
	passive_upgrade_button.disabled = coins < passive_upgrade_cost


# Button callbacks (in main scene, same as onClick in Unity)

func _on_earn_button_pressed() -> void:
	coins += click_value


func _on_buy_cube_button_pressed() -> void:
	if coins < cube_cost:
		return
	coins -= cube_cost
	cube_cost = int(cube_cost * 1.35)
	_spawn_cube()


func _on_click_upgrade_button_pressed() -> void:
	if coins < click_upgrade_cost:
		return
	coins -= click_upgrade_cost
	click_upgrade_level += 1
	click_value = 1 + (click_upgrade_level * click_upgrade_level)
	click_upgrade_cost = int(click_upgrade_cost * 2.0)
	_apply_upgrades_to_all_cubes()


func _on_passive_upgrade_button_pressed() -> void:
	if coins < passive_upgrade_cost:
		return
	coins -= passive_upgrade_cost
	passive_upgrade_level += 1
	passive_value = 1 + passive_upgrade_level
	passive_upgrade_cost = int(passive_upgrade_cost * 2.2)
	_apply_upgrades_to_all_cubes()


# Spawning the cubes

func _spawn_cube() -> void:
	# instantiate() = Instantiate(prefab) in Unity
	var cube: Area2D = CUBE_SCENE.instantiate()

	var col := cubes_owned % CUBE_COLUMNS
	var row := cubes_owned / CUBE_COLUMNS
	cube.position = GRID_ORIGIN + Vector2(col * CUBE_SPACING, row * CUBE_SPACING)

	# add_child = transform.SetParent in Unity
	cube_container.add_child(cube)
	cube.apply_upgrades(click_value, passive_value)

	# connect() = AddListener() in Unity
	cube.cube_clicked.connect(_on_cube_clicked)
	cube.passive_tick.connect(_on_cube_passive_tick)

	
	cube.input_pickable = true
	cube.connect("input_event", _make_cube_click_handler(cube))

	cubes_owned += 1


func _make_cube_click_handler(cube: Area2D) -> Callable:
	return func(_viewport, event: InputEvent, _shape_idx):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			cube.on_clicked()


# Alot of coin function

func _on_cube_clicked(amount: int) -> void:
	coins += amount


func _on_cube_passive_tick(amount: int) -> void:
	coins += amount


# updates values to every cube (like foreach on a List<Cube>)
func _apply_upgrades_to_all_cubes() -> void:
	for child in cube_container.get_children():
		if child.has_method("apply_upgrades"):
			child.apply_upgrades(click_value, passive_value)

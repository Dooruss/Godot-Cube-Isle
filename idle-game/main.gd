extends Node2D

@onready var multi_button: Button = $UpperController/MultiButton
@onready var auto_button: Button = $UpperController/AutoButton
@onready var auto_amount_button: Button = $UpperController/AutoAmountButton
@onready var CoinAmountLabel: RichTextLabel = $UpperController/CoinAmountLabel
@onready var auto_t_ime: Timer = $UpperController/AutoButton/AutoTIme

var Coins:int = 0
var AutoEnable:bool = false
var AutoAmount:int = 1
var ClickAmount:int = 1
var MultiLevel:int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	CoinAmountLabel.text = str(Coins)


func _on_click_button_pressed() -> void:
	AddCoins(ClickAmount)
	
	
func AddCoins(amount):
	Coins += amount


func _on_auto_t_ime_timeout() -> void:
	if AutoEnable == true:
		AddCoins(AutoAmount)


func _on_auto_button_pressed() -> void:
	if Coins >= 100 and AutoEnable != true:
		Coins -= 100
		AutoEnable = true
		auto_t_ime.start(1)

func _on_multi_button_pressed() -> void:
	if Coins >= (25 * MultiLevel):
		Coins -= (25 * MultiLevel)
		MultiLevel += 1
		ClickAmount = MultiLevel * MultiLevel
		var FormatString = "More per Click!: $%s"
		var ActualString = FormatString % str(25 * MultiLevel)
		multi_button.text = ActualString
		


func _on_auto_amount_button_pressed() -> void:
	if Coins >= 100:
		AddCoins(-100)
		AutoAmount += 2
		var FormatString = "More per second!: $%s"
		var ActualString = FormatString % str(100)
		auto_amount_button.text = ActualString

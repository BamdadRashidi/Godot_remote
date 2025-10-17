extends Button

@onready var previous: Button = $"../HBoxContainer/previous"
@onready var laseractivator: Button = $"../HBoxContainer/laseractivator"
@onready var next: Button = $"../HBoxContainer/next"
@onready var text_edit: TextEdit = $"../TextEdit"
@onready var quit: Button = $"../../quit"
@onready var label: Label = $"../Label"
@onready var timer: Timer = $"../Label/Timer"

var regex = RegEx.new()

func _ready() -> void:
	label.visible = false



func _process(delta: float) -> void:
	pass


func _on_pressed() -> void:
	var text_content = text_edit.get_text()
	text_edit.text = ""
	if check_ip(text_content):
		next.peer.set_dest_address(text_content,next.PORT)
		previous.peer.set_dest_address(text_content,previous.PORT)
		quit.peer.set_dest_address(text_content,quit.PORT)
		laseractivator.peer.set_dest_address(text_content,laseractivator.PORT)
	else:
		label.visible = true
		timer.start()
		print('your IP is not following IP address standards')


func check_ip(ip) -> bool:
	if ip == "":
		return false
	var check = regex.compile("^((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\\.){3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])$")
	if regex.search(ip, check):
		print(ip)
		return true
	else:
		return false


func _on_timer_timeout() -> void:
	label.visible = false


func _on_erase_ip_pressed() -> void:
		next.peer.set_dest_address("",next.PORT)
		previous.peer.set_dest_address("",next.PORT)
		quit.peer.set_dest_address("",next.PORT)
		laseractivator.peer.set_dest_address("",next.PORT)

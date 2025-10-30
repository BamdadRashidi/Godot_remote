extends Button

@onready var previous: Button = $"../HBoxContainer/previous"
@onready var laseractivator: Button = $"../HBoxContainer/laseractivator"
@onready var next: Button = $"../HBoxContainer/next"
@onready var text_edit: TextEdit = $"../TextEdit"
@onready var quit: Button = $"../../quit"
@onready var label: Label = $"../Label"
@onready var timer: Timer = $"../Label/Timer"
@onready var click: Button = $"../../click"

var regex = RegEx.new()

func _ready() -> void:
	label.visible = false
	for btn in [next, previous, quit, laseractivator, click]:
		if btn.has_method("load_ip"):
			btn.peer.set_dest_address(btn.load_ip(),btn.PORT)



func _process(delta: float) -> void:
	pass


func _on_pressed() -> void:
	var text_content = text_edit.get_text()
	text_edit.text = "" 					# resetting the value of the textbox
	
	if check_ip(text_content):
		for btn in [next, previous, quit, laseractivator, click]:
			btn.peer.set_dest_address(text_content,btn.PORT)
		save_ip(text_content)
	else:
		label.visible = true
		timer.start()
		print('your IP is not following IP address standards')


func check_ip(ip) -> bool:
	if ip == "":
		return false
	regex.compile("^((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\\.){3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])$")
	var result = regex.search(ip)
	if result:
		print(ip)
		return true
	else:
		return false


func _on_timer_timeout() -> void:
	label.visible = false


func _on_erase_ip_pressed() -> void:
	for button in [next, previous, quit, laseractivator, click]:
		button.peer.set_dest_address("0.0.0.0", button.PORT)
		button.IP_ADDRESS = ""
		
		
func save_ip(IPaddress):
	var file = FileAccess.open("user://Ipaddrsave.dat",FileAccess.WRITE)
	file.store_string(IPaddress)
	file.close()

extends Button

var peer = PacketPeerUDP.new()
var IP_ADDRESS
var PORT:int = 4307
func _ready() -> void:
	pass


func _on_pressed() -> void:
	print('previous')
	print(IP_ADDRESS)
	peer.put_packet("previous".to_utf8_buffer())

func set_ip(ip):
	IP_ADDRESS = ip


func load_ip() -> String:
	if FileAccess.file_exists("user://Ipaddrsave.dat"):
		var file = FileAccess.open("user://Ipaddrsave.dat",FileAccess.READ)
		var ip_string = file.get_as_text()
		file.close()
		return ip_string.strip_edges()
	else:
		print("no file exists on this path")
		return "0.0.0.0"

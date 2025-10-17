extends Button

var IP_ADDRESS
var PORT:int = 4307

var peer = PacketPeerUDP.new()
func _ready() -> void:
	IP_ADDRESS = ""
	peer.set_dest_address(IP_ADDRESS,PORT)


func _on_pressed() -> void:
	print('next')
	print(IP_ADDRESS)
	peer.put_packet("next".to_utf8_buffer())
	

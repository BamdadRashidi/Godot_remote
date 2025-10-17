extends Button

var peer = PacketPeerUDP.new()
var IP_ADDRESS
var PORT:int = 4307
func _ready() -> void:
	IP_ADDRESS = ""
	peer.set_dest_address(IP_ADDRESS,PORT)



func _on_pressed() -> void:
	print('quit')
	print(IP_ADDRESS)
	peer.put_packet("quit".to_utf8_buffer())

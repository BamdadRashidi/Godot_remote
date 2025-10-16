extends Button

var peer = PacketPeerUDP.new()
func _ready() -> void:
	peer.set_dest_address("IP",4307)



func _on_pressed() -> void:
	print('quit')
	peer.put_packet("quit".to_utf8_buffer())

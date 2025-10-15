extends Button


var peer = PacketPeerUDP.new()
func _ready() -> void:
	peer.set_dest_address("YOUR IP",4307)


func _on_pressed() -> void:
	print('next')
	peer.put_packet("next".to_utf8_buffer())
	

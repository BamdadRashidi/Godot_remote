extends Button


var peer = PacketPeerUDP.new()
func _ready() -> void:
	peer.set_dest_address("",4307)
	peer.set_broadcast_enabled(true)


func _on_pressed() -> void:
	print('next')
	peer.put_packet("next".to_utf8_buffer())
	

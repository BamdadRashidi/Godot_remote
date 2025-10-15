extends Button

var peer = PacketPeerUDP.new()
func _ready() -> void:
	peer.set_dest_address("",4307)
	peer.set_broadcast_enabled(true)


func _on_pressed() -> void:
	print('previous')
	peer.put_packet("previous".to_utf8_buffer())

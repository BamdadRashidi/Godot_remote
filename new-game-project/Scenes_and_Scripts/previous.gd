extends Button

var peer = PacketPeerUDP.new()
func _ready() -> void:
	peer.set_dest_address("YOUR IP",4307)


func _on_pressed() -> void:
	print('previous')
	peer.put_packet("previous".to_utf8_buffer())

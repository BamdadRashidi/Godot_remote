extends Button

var peer = PacketPeerUDP.new()
func _ready() -> void:
	peer.set_dest_address("",4307)
	peer.set_broadcast_enabled(true)



func _on_button_down() -> void:
	print('laser on')
	peer.put_packet("lON".to_utf8_buffer())


func _on_button_up() -> void:
	print('laser off')
	peer.put_packet("lOFF".to_utf8_buffer())

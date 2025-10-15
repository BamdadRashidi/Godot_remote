extends Button

var peer = PacketPeerUDP.new()
func _ready() -> void:
	peer.set_dest_address("YOUR IP",4307)



func _on_button_down() -> void:
	print('laser on')
	peer.put_packet("lON".to_utf8_buffer())


func _on_button_up() -> void:
	print('laser off')
	peer.put_packet("lOFF".to_utf8_buffer())

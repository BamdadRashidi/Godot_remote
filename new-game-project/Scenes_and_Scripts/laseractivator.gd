extends Button

var peer = PacketPeerUDP.new()
var can_send = false
var IP_ADDRESS
var PORT:int = 4307
func _ready() -> void:
	IP_ADDRESS = ""
	can_send = false
	peer.set_dest_address(IP_ADDRESS,PORT)

func _process(delta: float) -> void:
	if can_send == true:
		var accel = Input.get_accelerometer()
		var message = "%f,%f,%f" % [accel.x,accel.y,accel.z]
		peer.put_packet(message.to_utf8_buffer())

func _on_button_down() -> void:
	print('laser on')
	print(IP_ADDRESS)
	peer.put_packet("lON".to_utf8_buffer())
	await get_tree().create_timer(0.07).timeout
	can_send = true


func _on_button_up() -> void:
	can_send = false
	print(IP_ADDRESS)
	print('laser off')
	peer.put_packet("lOFF".to_utf8_buffer())

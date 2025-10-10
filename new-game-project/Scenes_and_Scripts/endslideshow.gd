extends Button

var socket = WebSocketPeer.new()


func _ready() -> void:
	socket.connect_to_url("ws://") #insert IP address here



func _process(delta: float) -> void:
	pass


func _on_pressed() -> void:
	socket.poll()
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		socket.send_text("next")

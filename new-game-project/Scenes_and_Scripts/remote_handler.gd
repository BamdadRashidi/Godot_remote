class_name Connector
extends Node

# Singleton instance
static var instance: Connector

var GyroOn: bool = false

enum CommandType {
	JOYSTICK = 1,
	PREV = 2,
	NEXT = 3,
	CLICK = 4,
	QUIT = 5,
	Gyro = 6
}

@export var port: int = 8888

@export_group("UI & Input References")
@export var ip_textbox: TextEdit
@export var errortxt: Control
@export var next_btn: Button
@export var prev_btn: Button
@export var shut_btn: Button
@export var click_btn: Button
@export var subtmitBtn: Button
@export var clearnBtn: Button
@export var gyroBtn: Button

@export_group("Input Action Map Names")
@export var action_left: StringName = &"ui_left"
@export var action_right: StringName = &"ui_right"
@export var action_up: StringName = &"ui_up"
@export var action_down: StringName = &"ui_down"

# Network & Thresholds
var ip_addr: String = ""
var ipv4_regex: RegEx
var udp_peer: PacketPeerUDP
var stream_buffer: StreamPeerBuffer

var last_sent_input: Vector2 = Vector2.ZERO
var last_sent_input_gyro: Vector2 = Vector2.ZERO
@export var sending_threshold_sq: float = 0.0001 # (0.01 ^ 2) avoids expensive sqrt computations


func _enter_tree() -> void:
	if instance != null and instance != self:
		queue_free()
		return
	instance = self


func _ready() -> void:
	udp_peer = PacketPeerUDP.new()
	
	# Pre-allocate dynamic byte buffer to avoid garbage collection pressure during tick updates
	stream_buffer = StreamPeerBuffer.new()
	stream_buffer.big_endian = false

	if errortxt:
		errortxt.visible = false

	ipv4_regex = RegEx.new()
	ipv4_regex.compile("^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$")

	# UI Signal Connections
	if prev_btn: prev_btn.pressed.connect(_on_previous_click)
	if next_btn: next_btn.pressed.connect(_on_next_click)
	if gyroBtn: gyroBtn.button_down.connect(_on_gyro_click)
	if gyroBtn: gyroBtn.button_up.connect(_on_gyro_release)
	if click_btn: click_btn.pressed.connect(_on_left_click)
	if shut_btn: shut_btn.pressed.connect(_on_quit_click)
	if subtmitBtn: subtmitBtn.pressed.connect(_on_submit_ip_addr)
	if ip_textbox and ip_textbox.has_signal("text_submitted"):
		ip_textbox.connect("text_submitted", _on_submit_ip_addr)


func _physics_process(_delta: float) -> void:
	if GyroOn:
		# Measure real angular velocity around device axes (rad/s)
		var gyro_rot := Input.get_gyroscope()
		# gyro_rot.z handles roll, gyro_rot.x handles pitch
		var direction_gyro := Vector2(gyro_rot.z, -gyro_rot.x)
		
		if direction_gyro != Vector2.ZERO:
			_process_and_send_gyro(direction_gyro)
		else:
			if last_sent_input_gyro != Vector2.ZERO:
				_process_and_send_gyro(Vector2.ZERO)
	else:
		# Retrieve direction vector identically to standard character movement controllers
		var direction := Input.get_vector(action_left, action_right, action_up, action_down)

		if direction != Vector2.ZERO:
			_process_and_send_joystick(direction)
		else:
			# If joystick/input was active last frame but stopped this frame, emit explicit zero packet once
			if last_sent_input != Vector2.ZERO:
				_process_and_send_joystick(Vector2.ZERO)


# --- JOYSTICK EVALUATION ---

func _process_and_send_joystick(input_vec: Vector2) -> void:
	if input_vec.distance_squared_to(last_sent_input) >= sending_threshold_sq or input_vec == Vector2.ZERO:
		last_sent_input = input_vec
		send_joystick(input_vec.x, input_vec.y)

# --- GYROSCOPE EVALUATION ---

func _process_and_send_gyro(input_vec_g: Vector2) -> void:
	if input_vec_g.distance_squared_to(last_sent_input_gyro) >= sending_threshold_sq or input_vec_g == Vector2.ZERO:
		last_sent_input_gyro = input_vec_g
		send_gyro(input_vec_g.x, input_vec_g.y)

	
# --- NETWORK PACKET HANDLING ---

func send_joystick(x: float, y: float) -> void:
	_build_and_send_packet(CommandType.JOYSTICK, x, y)

func send_gyro(x: float, y: float) -> void:
	_build_and_send_packet(CommandType.Gyro, x, y)
	
func send_command(cmd: CommandType) -> void:
	_build_and_send_packet(cmd, 0.0, 0.0)


func _build_and_send_packet(cmd: CommandType, x: float, y: float) -> void:
	if ip_addr.is_empty() or udp_peer == null or ip_addr == "":
		show_error()
		return

	# Fast buffer reuse: seek back to start without reallocation
	stream_buffer.seek(0)
	stream_buffer.put_u8(cmd)
	stream_buffer.put_float(x)
	stream_buffer.put_float(y)

	udp_peer.set_dest_address(ip_addr, port)
	udp_peer.put_packet(stream_buffer.data_array)


# --- UI CALLBACKS ---

func _on_previous_click() -> void: 
	send_command(CommandType.PREV)

func _on_next_click() -> void: 
	send_command(CommandType.NEXT)

func _on_left_click() -> void: 
	send_command(CommandType.CLICK)

func _on_quit_click() -> void: 
	send_command(CommandType.QUIT)

func _on_gyro_click() -> void:
	GyroOn = true

func _on_gyro_release() -> void:
	GyroOn = false
	# Clear gyro velocity state on release
	_process_and_send_gyro(Vector2.ZERO)

func _on_submit_ip_addr(_new_text: String = "") -> void:
	if ip_textbox == null: return

	var raw_input: String = ip_textbox.get("text").strip_edges() if ip_textbox.get("text") != null else ""

	if ipv4_regex.search(raw_input) != null:
		ip_addr = raw_input
		if ip_textbox.has_method("clear"):
			ip_textbox.clear()
	else:
		show_error()

func show_error() -> void:
	if errortxt:
		errortxt.visible = true
	_hide_error_async()

func _hide_error_async() -> void:
	await get_tree().create_timer(3.0, true, false, true).timeout
	if errortxt:
		errortxt.visible = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and udp_peer != null:
		udp_peer.close()


func _on_erase_ip_pressed() -> void:
	ip_addr = ""
	ip_textbox.clear()
	
	
func _on_line_edit_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		ip_textbox.grab_focus()
		DisplayServer.virtual_keyboard_show(ip_textbox.text)

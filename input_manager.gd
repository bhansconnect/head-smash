extends Node

signal device_changed

@export var DEADZONE: float = 0.5

enum Device {KEYBOARD, XBOX, SWITCH, PLAYSTATION, GENERIC_CONTROLLER}

const DEVICE_TYPES = [
	Device.KEYBOARD,
	Device.XBOX,
	Device.SWITCH,
	Device.PLAYSTATION,
	Device.GENERIC_CONTROLLER
]

const ACTION_LEFT: String = "left"
const ACTION_RIGHT: String = "right"
const ACTION_JUMP: String = "jump"
const ACTION_CROUCH: String = "crouch"
const ACTION_INTERACT: String = "interact"

const ACTIONS = [
	ACTION_LEFT,
	ACTION_RIGHT,
	ACTION_JUMP,
	ACTION_CROUCH,
	ACTION_INTERACT,
]

var device: Device = Device.KEYBOARD
var device_index: int = -1
var device_last_changed_at: int = 0

var mappings = {}

func _ready():
	for d in DEVICE_TYPES:
		mappings[d] = {}
		for a in ACTIONS:
			mappings[d][a] = []
	
	var event : InputEvent = InputEventKey.new()
	
	# Arrow mapping
	event.physical_keycode = KEY_LEFT
	mappings[Device.KEYBOARD][ACTION_LEFT].append(event)
	event = InputEventKey.new()
	event.physical_keycode = KEY_RIGHT
	mappings[Device.KEYBOARD][ACTION_RIGHT].append(event)
	event = InputEventKey.new()
	event.physical_keycode = KEY_UP
	mappings[Device.KEYBOARD][ACTION_JUMP].append(event)
	event = InputEventKey.new()
	event.physical_keycode = KEY_DOWN
	mappings[Device.KEYBOARD][ACTION_CROUCH].append(event)
	
	# WASD mapping
	event = InputEventKey.new()
	event.physical_keycode = KEY_A
	mappings[Device.KEYBOARD][ACTION_LEFT].append(event)
	event = InputEventKey.new()
	event.physical_keycode = KEY_D
	mappings[Device.KEYBOARD][ACTION_RIGHT].append(event)
	event = InputEventKey.new()
	event.physical_keycode = KEY_W
	mappings[Device.KEYBOARD][ACTION_JUMP].append(event)
	event = InputEventKey.new()
	event.physical_keycode = KEY_S
	mappings[Device.KEYBOARD][ACTION_CROUCH].append(event)
	
	# Interact mapping
	event = InputEventKey.new()
	event.physical_keycode = KEY_SPACE
	mappings[Device.KEYBOARD][ACTION_INTERACT] = [event]
	
	# Shared controller mappings
	for d in DEVICE_TYPES:
		if d == Device.KEYBOARD:
			continue
		
		event = InputEventJoypadMotion.new()
		event.axis = JOY_AXIS_LEFT_X
		event.axis_value = -1.0
		event.device = -1
		mappings[d][ACTION_LEFT] = [event]
		event = InputEventJoypadMotion.new()
		event.axis = JOY_AXIS_LEFT_X
		event.axis_value = 1.0
		event.device = -1
		mappings[d][ACTION_RIGHT] = [event]
		event = InputEventJoypadButton.new()
		event.button_index = JOY_BUTTON_A
		event.device = -1
		mappings[d][ACTION_JUMP] = [event]
		event = InputEventJoypadButton.new()
		event.button_index = JOY_BUTTON_B
		event.device = -1
		mappings[d][ACTION_CROUCH] = [event]
		event = InputEventJoypadButton.new()
		event.button_index = JOY_BUTTON_X
		event.device = -1
		mappings[d][ACTION_INTERACT] = [event]
	
	# Special mapping modification for Switch buttons
	event = InputEventJoypadButton.new()
	event.button_index = JOY_BUTTON_B
	event.device = -1
	mappings[Device.SWITCH][ACTION_JUMP] = [event]
	event = InputEventJoypadButton.new()
	event.button_index = JOY_BUTTON_A
	event.device = -1
	mappings[Device.SWITCH][ACTION_CROUCH] = [event]
	event = InputEventJoypadButton.new()
	event.button_index = JOY_BUTTON_Y
	event.device = -1
	mappings[Device.SWITCH][ACTION_INTERACT] = [event]
	
	device = guess_device_type()
	update_device(device, device_index)
	emit_signal("device_changed", device, device_index)
	

func _input(event: InputEvent):
	var next_device: Device = device
	var next_device_index: int = device_index
	
	# Did we just press a key on the keyboard?
	if event is InputEventKey:
		next_device = Device.KEYBOARD
		next_device_index = -1
	
	# Did we just use a gamepad?
	elif event is InputEventJoypadButton \
		or (event is InputEventJoypadMotion and event.axis_value > DEADZONE):
		next_device = get_device_type(Input.get_joy_name(event.device))
		next_device_index = event.device
	
	# Debounce changes because some gamepads register twice in Windows for some reason
	var not_changed_just_then = Engine.get_frames_drawn() - device_last_changed_at > Engine.get_frames_per_second()
	if next_device != device or (next_device_index != device_index and not_changed_just_then):
		device_last_changed_at = Engine.get_frames_drawn()
		
		device = next_device
		device_index = next_device_index
		update_device(device, device_index)
		emit_signal("device_changed", device, device_index)
		
		# Repeat this event so it actually gets used.
		# Otherwise you have to tap a key twice.
		Input.parse_input_event(event)

var seen_generic_controllers = []

func get_device_type(device_name: String) -> Device:
	match device_name:
		"XInput Gamepad", "Xbox Series Controller":
			return Device.XBOX
		
		"Sony DualSense", "PS5 Controller", "PS4 Controller":
			return Device.PLAYSTATION
		
		"Switch", "Nintendo Switch Controller", "Lic Pro Controller":
			return Device.SWITCH
		
		_:
			if device_name not in seen_generic_controllers:
				print_debug("Using generic controller setup for unknown controller type: ", device_name)
			seen_generic_controllers.append(device_name)
			return Device.GENERIC_CONTROLLER

func has_gamepad() -> bool:
	return Input.get_connected_joypads().size() > 0

func guess_device_type() -> Device:
	if not has_gamepad():
		return Device.KEYBOARD
	
	return get_device_type(Input.get_joy_name(0))

func update_device(next_device: Device, _index: int):
	InputMap.action_erase_events("jump")
	InputMap.action_erase_events("left")
	InputMap.action_erase_events("right")
	InputMap.action_erase_events("crouch")
	for action in mappings[next_device].keys():
		for event in mappings[next_device][action]:
			InputMap.action_add_event(action, event)

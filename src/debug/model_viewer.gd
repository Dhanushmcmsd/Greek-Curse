extends Node3D

var _model: Node3D
var _camera: Camera3D
var _assets: Array = []
var _index: int = 0
var _angle: float = 0.0


func _ready() -> void:
	var manifest: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://assets/generated/manifest.json")
	)
	_assets = manifest["assets"]
	_camera = Camera3D.new()
	add_child(_camera)
	_camera.current = true
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -30, 0)
	add_child(light)
	_show()


func _process(delta: float) -> void:
	_angle += delta * 0.3
	_camera.position = Vector3(sin(_angle) * 5, 2.5, cos(_angle) * 5)
	_camera.look_at(Vector3(0, 1, 0))


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_index = (_index + 1) % _assets.size()
		_show()


func _show() -> void:
	if _model != null:
		_model.queue_free()
	var info := ModelLoader.load_model("res://" + str(_assets[_index]["path"]))
	_model = info.root
	add_child(_model)
	print("MODEL_VIEWER ", _assets[_index]["id"])

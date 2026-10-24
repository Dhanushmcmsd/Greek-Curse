extends MenuHost
@export var screen: String = "error"


func _ready() -> void:
	Router.changed.connect(_show)
	_show(screen)

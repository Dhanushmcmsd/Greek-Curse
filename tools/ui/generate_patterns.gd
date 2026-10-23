extends SceneTree


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/ui")
	for id in ["solid", "hatch", "dots", "outline"]:
		var image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
		image.fill(Color.TRANSPARENT)
		for x in 8:
			for y in 8:
				var marked: bool = (id == "solid" and y == 7) or (id == "hatch" and (x+y) % 4 == 0) or (id == "dots" and x % 4 == 0 and y % 4 == 0)
				if marked:
					image.set_pixel(x, y, Color(1, 1, 1, 0.65))
		image.save_png("res://assets/ui/pattern_%s.png" % id)
	print("PATTERNS_OK")
	quit()

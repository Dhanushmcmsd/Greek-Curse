class_name ArenaBuilder
extends Node3D

var arena_id: String = "mount_olympus"
var data: Dictionary
var markers: Array[MeshInstance3D] = []


func _ready() -> void:
	data = DataLoader.new().load_json("res://data/arenas/%s.json" % arena_id).value
	var model := (
		ModelLoader.load_model("res://assets/generated/models/arena_%s.glb" % arena_id).root
	)
	add_child(model)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-45, -28, 0)
	key.light_color = Color(data["palette"][1])
	key.light_energy = float(data["lighting"]["key_energy"])
	key.shadow_enabled = true
	add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, 140, 0)
	fill.light_color = Color("7eacda")
	fill.light_energy = float(data["lighting"]["fill_energy"])
	add_child(fill)
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var material := ProceduralSkyMaterial.new()
	material.sky_top_color = Color(data["palette"][0])
	material.sky_horizon_color = Color(data["palette"][0]).lightened(0.18)
	material.ground_bottom_color = Color(data["palette"][0])
	material.ground_horizon_color = material.sky_horizon_color
	sky.sky_material = material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("b6c5d4")
	environment.ambient_light_energy = float(data["lighting"]["ambient"])
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)
	for zone in data["hazard"]["zones"]:
		var marker := MeshInstance3D.new()
		var plane := CylinderMesh.new()
		plane.top_radius = float(int(zone[1]) - int(zone[0])) / 2000.0
		plane.bottom_radius = plane.top_radius
		plane.height = 0.015
		marker.mesh = plane
		var glow := StandardMaterial3D.new()
		glow.albedo_color = Color("ff6425") if data["hazard"]["type"] == "lava" else Color("a9eaff")
		glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		glow.albedo_color.a = 0.65
		marker.material_override = glow
		marker.position = Vector3(float(int(zone[0]) + int(zone[1])) / 2000.0, 0.02, 0)
		marker.visible = false
		add_child(marker)
		markers.append(marker)

		# Separate active hazard geyser/energy column:
		var column := MeshInstance3D.new()
		var col_mesh := CylinderMesh.new()
		col_mesh.top_radius = plane.top_radius * 0.85
		col_mesh.bottom_radius = plane.top_radius * 0.95
		col_mesh.height = 3.2
		column.mesh = col_mesh
		var col_mat := StandardMaterial3D.new()
		col_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		col_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var col_base: Color = (
			Color(1.0, 0.45, 0.18, 0.22)
			if data["hazard"]["type"] == "lava"
			else Color(0.6, 0.9, 1.0, 0.20)
		)
		col_mat.albedo_color = col_base
		column.material_override = col_mat
		column.position = Vector3(marker.position.x, 1.6, 0)
		column.visible = false
		add_child(column)
		marker.set_meta("active_column", column)


func sync(world: SimWorld) -> void:
	for marker in markers:
		marker.visible = false
		var col: MeshInstance3D = marker.get_meta("active_column", null) as MeshInstance3D
		if col != null:
			col.visible = false
	if not world.hazards_enabled or world.tick < world.hazard_offset:
		return
	var rule: Dictionary = data["hazard"]
	var age := (world.tick - world.hazard_offset) % int(rule["period"])
	var cycle := (world.tick - world.hazard_offset) / int(rule["period"])
	var marker := markers[(cycle + world.hazard_zone) % markers.size()]
	var is_visible: bool = age < int(rule["telegraph_ticks"]) + int(rule["active_ticks"])
	marker.visible = is_visible
	marker.scale.y = 1.0

	var column: MeshInstance3D = marker.get_meta("active_column", null) as MeshInstance3D
	var is_active: bool = age >= int(rule["telegraph_ticks"]) and is_visible
	if column != null:
		column.visible = is_active
		if is_active:
			var mat := column.material_override as StandardMaterial3D
			if mat != null:
				var max_alpha := 0.12 if bool(SettingsHooks.get_value("flash_reduction")) else 0.22
				mat.albedo_color.a = max_alpha

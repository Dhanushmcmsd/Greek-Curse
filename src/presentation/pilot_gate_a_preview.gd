class_name PilotGateAPreview
extends Node3D
## Isolated Gate A visual pilot preview scene for intact & partitioned Arissa.
## Preserves intact 73-bone Mixamo deform skeleton and soft skin weights.
## Features:
## - Fixed world direction markers (+X / -X).
## - Dummy opponent on active combat facing side.
## - Multi-camera toggle: Front (Combat) vs Side (Profile).
## - Interactive Amputation toggles: Arm Sever [1], Leg Sever [2], Regrow [3], Intact Mode [M].
## - Controls: [SPACE] Cycle Action | [F] Flip Facing | [C] Camera View | [1..3] Limb States

var anim_player: AnimationPlayer
var model: Node3D
var skeleton: Skeleton3D
var current_action_idx: int = 0
var actions: Array[String] = ["idle", "walk_fwd", "walk_back", "punch_jab", "kick_thrust"]
var hud_label: Label
var facing_dir: float = 1.0

# Partitioned limb tracking
var is_partitioned_mode: bool = true
var arm_l_severed: bool = false
var leg_l_severed: bool = false
var regrown_attached: bool = false

var limb_meshes_arm_l: Array[MeshInstance3D] = []
var limb_meshes_leg_l: Array[MeshInstance3D] = []
var stump_arm_l: Node3D
var stump_leg_l: Node3D
var socket_arm_l: Node3D
var regrown_limb_node: Node3D

var cam_front: Camera3D
var cam_side: Camera3D
var is_side_cam: bool = false
var opponent_dummy: Node3D


func _init() -> void:
	init_model_and_anims()


func _ready() -> void:
	# 1. Setup Camera and Lighting
	cam_front = Camera3D.new()
	cam_front.position = Vector3(0, 1.1, 2.5)
	add_child(cam_front)
	cam_front.look_at(Vector3(0, 0.9, 0), Vector3.UP)
	cam_front.current = true

	cam_side = Camera3D.new()
	cam_side.position = Vector3(2.5, 1.1, 0)
	add_child(cam_side)
	cam_side.look_at(Vector3(0, 0.9, 0), Vector3.UP)
	cam_side.current = false

	var light := DirectionalLight3D.new()
	light.position = Vector3(1, 3, 2)
	add_child(light)
	light.look_at(Vector3.ZERO, Vector3.UP)

	var env := WorldEnvironment.new()
	var we := Environment.new()
	we.background_mode = Environment.BG_COLOR
	we.background_color = Color(0.12, 0.14, 0.18)
	we.ambient_light_color = Color(0.6, 0.6, 0.6)
	env.environment = we
	add_child(env)

	# 2. Arena Floor & Direction Markers (+X / -X)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(8, 4)
	floor_mesh.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.20, 0.24)
	floor_mesh.material_override = mat
	add_child(floor_mesh)

	# World Axis Markers (+X = Right/Green, -X = Left/Red)
	_create_marker(Vector3(2.0, 0.05, 0), Color.GREEN, "+X (RIGHT TARGET)")
	_create_marker(Vector3(-2.0, 0.05, 0), Color.RED, "-X (LEFT TARGET)")

	# Dummy Opponent Target
	opponent_dummy = Node3D.new()
	var dummy_mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.2
	cyl.bottom_radius = 0.2
	cyl.height = 1.7
	dummy_mesh.mesh = cyl
	var dummy_mat := StandardMaterial3D.new()
	dummy_mat.albedo_color = Color(0.8, 0.3, 0.2)
	dummy_mesh.material_override = dummy_mat
	dummy_mesh.position = Vector3(0, 0.85, 0)
	opponent_dummy.add_child(dummy_mesh)
	add_child(opponent_dummy)
	_update_opponent_position()

	# 3. Setup HUD
	var canvas := CanvasLayer.new()
	add_child(canvas)
	hud_label = Label.new()
	hud_label.position = Vector2(20, 20)
	hud_label.add_theme_font_size_override("font_size", 15)
	canvas.add_child(hud_label)

	_apply_model_facing()
	play_action("idle")


func _create_marker(pos: Vector3, col: Color, _label_text: String) -> void:
	var m := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.4, 0.05, 0.4)
	m.mesh = box
	var sm := StandardMaterial3D.new()
	sm.albedo_color = col
	m.material_override = sm
	m.position = pos
	add_child(m)


func init_model_and_anims() -> void:
	if model != null:
		model.queue_free()
		model = null

	var model_path: String = (
		"res://build/pilot_gate_a/arissa_partitioned.glb"
		if is_partitioned_mode
		else "res://build/pilot_gate_a/arissa_intact.glb"
	)
	var pck := load(model_path) as PackedScene
	if pck == null:
		push_error("Failed to load model: " + model_path)
		return
	model = pck.instantiate()
	add_child(model)
	skeleton = model.find_child("Skeleton3D", true, false) as Skeleton3D

	# Setup isolated AnimationPlayer and load clips
	anim_player = AnimationPlayer.new()
	model.add_child(anim_player)
	anim_player.root_node = NodePath("..")

	var default_lib := AnimationLibrary.new()
	anim_player.add_animation_library("", default_lib)

	for act in actions:
		var anim_path := "res://build/pilot_gate_a/anim_%s.glb" % act
		if ResourceLoader.exists(anim_path):
			var a_scene := (load(anim_path) as PackedScene).instantiate()
			var a_player := a_scene.find_child("AnimationPlayer", true, false) as AnimationPlayer
			if a_player != null and not a_player.get_animation_list().is_empty():
				var clip: Animation = a_player.get_animation(a_player.get_animation_list()[0])
				var dup_clip: Animation = clip.duplicate(true)
				default_lib.add_animation(act, dup_clip)
			a_scene.queue_free()

	_cache_partitioned_nodes()


func _cache_partitioned_nodes() -> void:
	limb_meshes_arm_l.clear()
	limb_meshes_leg_l.clear()
	stump_arm_l = model.find_child("STUMP_ARM_L", true, false) as Node3D
	stump_leg_l = model.find_child("STUMP_LEG_L", true, false) as Node3D
	socket_arm_l = model.find_child("SOCKET_ARM_L", true, false) as Node3D

	for child in model.find_children("*", "MeshInstance3D", true, false):
		var mesh_name: String = str(child.name)
		if child.has_meta("limb_group"):
			var group: String = str(child.get_meta("limb_group"))
			if group == "LIMB_ARM_L":
				limb_meshes_arm_l.append(child)
			elif group == "LIMB_LEG_L":
				limb_meshes_leg_l.append(child)
		elif mesh_name.ends_with("_ARM_L"):
			limb_meshes_arm_l.append(child)
		elif mesh_name.ends_with("_LEG_L"):
			limb_meshes_leg_l.append(child)

	_update_limb_visibilities()


func _update_limb_visibilities() -> void:
	# Arm L visibility
	for m in limb_meshes_arm_l:
		m.visible = not arm_l_severed
	if stump_arm_l != null:
		stump_arm_l.visible = arm_l_severed and not regrown_attached

	# Leg L visibility
	for m in limb_meshes_leg_l:
		m.visible = not leg_l_severed
	if stump_leg_l != null:
		stump_leg_l.visible = leg_l_severed

	# Regrown attachment
	if regrown_attached:
		if regrown_limb_node == null and socket_arm_l != null:
			var regrown_mesh := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.04
			cyl.bottom_radius = 0.05
			cyl.height = 0.55
			regrown_mesh.mesh = cyl
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.9, 0.7, 0.2)
			regrown_mesh.material_override = mat
			regrown_mesh.position = Vector3(0, -0.28, 0)
			regrown_limb_node = Node3D.new()
			regrown_limb_node.add_child(regrown_mesh)
			socket_arm_l.add_child(regrown_limb_node)
	else:
		if regrown_limb_node != null:
			regrown_limb_node.queue_free()
			regrown_limb_node = null


func play_action(act_name: String) -> void:
	if anim_player != null and anim_player.has_animation(act_name):
		anim_player.play(act_name)
		_update_hud()


func _apply_model_facing() -> void:
	if model != null:
		model.rotation.y = deg_to_rad(90.0) * facing_dir
	_update_opponent_position()


func _update_opponent_position() -> void:
	if opponent_dummy != null:
		opponent_dummy.position = Vector3(1.8 * facing_dir, 0, 0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			current_action_idx = (current_action_idx + 1) % actions.size()
			play_action(actions[current_action_idx])
		elif event.keycode == KEY_F:
			facing_dir = -facing_dir
			_apply_model_facing()
			_update_hud()
		elif event.keycode == KEY_C:
			is_side_cam = not is_side_cam
			cam_front.current = not is_side_cam
			cam_side.current = is_side_cam
			_update_hud()
		elif event.keycode == KEY_1:
			arm_l_severed = not arm_l_severed
			_update_limb_visibilities()
			_update_hud()
		elif event.keycode == KEY_2:
			leg_l_severed = not leg_l_severed
			_update_limb_visibilities()
			_update_hud()
		elif event.keycode == KEY_3:
			if arm_l_severed:
				regrown_attached = not regrown_attached
				_update_limb_visibilities()
				_update_hud()
		elif event.keycode == KEY_M:
			is_partitioned_mode = not is_partitioned_mode
			arm_l_severed = false
			leg_l_severed = false
			regrown_attached = false
			init_model_and_anims()
			_apply_model_facing()
			play_action(actions[current_action_idx])


func _update_hud() -> void:
	if hud_label == null:
		return
	var act: String = actions[current_action_idx]
	var anim: Animation = null
	if anim_player != null and anim_player.has_animation(act):
		anim = anim_player.get_animation(act)
	var dur: float = anim.length if anim != null else 0.0
	var tracks: int = anim.get_track_count() if anim != null else 0
	var bone_cnt: int = skeleton.get_bone_count() if skeleton != null else 0
	var facing_str: String = "RIGHT (+X Target)" if facing_dir > 0 else "LEFT (-X Target)"
	var cam_str: String = "SIDE PROFILE" if is_side_cam else "FRONT COMBAT"
	var mode_str: String = (
		"PARTITIONED (Amputation Pilot)" if is_partitioned_mode else "INTACT REFERENCE"
	)
	var arm_str: String = (
		"REGROWN ATTACHED"
		if regrown_attached
		else ("SEVERED (STUMP ON)" if arm_l_severed else "INTACT")
	)
	var leg_str: String = "SEVERED (STUMP ON)" if leg_l_severed else "INTACT"

	hud_label.text = (
		"""[GATE A & AMPUTATION PILOT PREVIEW]
Mode: %s | Camera: %s
Model: %s (Deform Bones: %d)
Active Action: %s (Duration: %.2fs, Channels: %d)
Combat Facing: %s (RotY: %.1f°)
Limb Status: Left Arm: [%s] | Left Leg: [%s]
Controls:
  [SPACE] Cycle Action | [F] Flip Facing | [C] Toggle Camera
  [1] Toggle Left Arm Sever | [2] Toggle Left Leg Sever
  [3] Toggle Regrown Arm Attachment | [M] Toggle Intact/Partitioned Model
"""
		% [
			mode_str,
			cam_str,
			"arissa_partitioned.glb" if is_partitioned_mode else "arissa_intact.glb",
			bone_cnt,
			act.to_upper(),
			dur,
			tracks,
			facing_str,
			rad_to_deg(model.rotation.y) if model != null else 0.0,
			arm_str,
			leg_str,
		]
	)

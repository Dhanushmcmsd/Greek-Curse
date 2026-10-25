class_name PilotGateAPreview
extends Node3D
## Isolated Gate A visual pilot preview scene for intact Arissa.
## Loads the intact 73-bone character model and 5 retargeted source animations from build/.
## Displays exact paths, rig profile, bone count, and active playback in a minimal preview HUD.

var anim_player: AnimationPlayer
var model: Node3D
var skeleton: Skeleton3D
var current_action_idx: int = 0
var actions: Array[String] = ["idle", "walk_fwd", "walk_back", "punch_jab", "kick_thrust"]
var hud_label: Label
var facing_dir: float = 1.0


func _init() -> void:
	init_model_and_anims()


func _ready() -> void:
	# 1. Setup camera and lighting
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.1, 2.5)
	add_child(cam)
	cam.look_at(Vector3(0, 0.9, 0), Vector3.UP)

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

	# Floor grid marker
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(4, 4)
	floor_mesh.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.22, 0.26)
	floor_mesh.material_override = mat
	add_child(floor_mesh)

	# 2. Setup HUD
	var canvas := CanvasLayer.new()
	add_child(canvas)
	hud_label = Label.new()
	hud_label.position = Vector2(20, 20)
	hud_label.add_theme_font_size_override("font_size", 16)
	canvas.add_child(hud_label)

	play_action("idle")


func init_model_and_anims() -> void:
	if model != null:
		return
	var model_path := "res://build/pilot_gate_a/arissa_intact.glb"
	var pck := load(model_path) as PackedScene
	if pck == null:
		push_error("Failed to load intact model: " + model_path)
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


func play_action(act_name: String) -> void:
	if anim_player != null and anim_player.has_animation(act_name):
		anim_player.play(act_name)
		_update_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			current_action_idx = (current_action_idx + 1) % actions.size()
			play_action(actions[current_action_idx])
		elif event.keycode == KEY_F:
			facing_dir = -facing_dir
			model.rotation.y = deg_to_rad(90.0) * facing_dir
			_update_hud()


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
	var facing_str: String = "RIGHT (+1)" if facing_dir > 0 else "LEFT (-1)"

	hud_label.text = (
		"""[GATE A ISOLATED PILOT PREVIEW]
Build Profile: RETAINED_MIXAMO_RIG (Intact, Unsevered)
Model Path: res://build/pilot_gate_a/arissa_intact.glb
Active Animation: %s (Duration: %.2fs, Tracks: %d)
Animation Path: res://build/pilot_gate_a/anim_%s.glb
Skeleton Bones: %d (All Mixamo deform bones intact)
Controls: [SPACE] Cycle Action | [F] Flip Facing (Current: %s)
"""
		% [act.to_upper(), dur, tracks, act, bone_cnt, facing_str]
	)

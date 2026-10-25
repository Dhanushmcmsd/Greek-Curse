class_name FighterRig
extends Node3D
## Generated modular mesh adapter. All changes are presentation-only.

const REQUIRED_BONES: Array[String] = [
	"root",
	"spine",
	"head",
	"upper_arm.l",
	"forearm.l",
	"hand.l",
	"upper_arm.r",
	"forearm.r",
	"hand.r",
	"thigh.l",
	"shin.l",
	"foot.l",
	"thigh.r",
	"shin.r",
	"foot.r"
]

const ALLOWED_EXCLUDED_TRACKS: Array[String] = [
	"LeftHandThumb",
	"LeftHandIndex",
	"LeftHandMiddle",
	"LeftHandRing",
	"LeftHandPinky",
	"RightHandThumb",
	"RightHandIndex",
	"RightHandMiddle",
	"RightHandRing",
	"RightHandPinky",
	"LeftEye",
	"RightEye",
	"Leye",
	"Reye",
	"L_horn",
	"R_horn",
	"HeadTop_End",
	"LeftToe_End",
	"RightToe_End",
	"Cloak",
	"Ribbon",
	"Bow",
	"F_skirt",
	"M_skirt",
	"L_A_skirt",
	"L_B_skirt",
	"L_C_skirt",
	"R_A_skirt",
	"R_B_skirt",
	"R_C_skirt"
]

static var _bone_map_cache: Dictionary = {}

var model: Node3D
var groups: Dictionary = {}
var stumps: Dictionary = {}
var sockets: Dictionary = {}
var limb_meshes: Dictionary = {}
var stump_meshes: Dictionary = {}
var skeleton: Skeleton3D
var anim_player: AnimationPlayer
var replacements: Dictionary = {}
var fighter_height: float = 1.8
var fighter_width: float = 0.45
var loaded_model_path: String = ""
var binding_audit_log: Array[Dictionary] = []
var _states: Dictionary = {}
var _stump_palette: String = ""
var _rest_rotations: Dictionary = {}


func load_fighter(id: String, model_override: String = "") -> bool:
	var row: Dictionary = DataLoader.new().load_json("res://data/fighters/%s.json" % id).value
	var mid: String = model_override
	if mid == "":
		mid = str(row.get("model_id", id))
	var mixamo_path := "res://assets/fighters_mixamo/fighter_%s.glb" % mid
	var legacy_path := "res://assets/generated/models/fighter_%s.glb" % id
	var path := ""
	if ResourceLoader.exists(mixamo_path):
		path = mixamo_path
	elif ResourceLoader.exists(legacy_path):
		push_warning(
			"Mixamo model missing for %s (%s); falling back to %s" % [id, mid, legacy_path]
		)
		path = legacy_path
	else:
		push_error("Missing fighter model: " + mixamo_path + " or " + legacy_path)
		return false
	loaded_model_path = path
	model = (load(path) as PackedScene).instantiate()
	add_child(model)
	skeleton = model.find_child("Skeleton3D", true, false) as Skeleton3D
	if skeleton != null:
		for index in skeleton.get_bone_count():
			_rest_rotations[index] = skeleton.get_bone_pose_rotation(index)

	var anim_path := "res://assets/fighters/%s/anims/anims.glb" % id
	anim_player = AnimationPlayer.new()
	model.add_child(anim_player)
	anim_player.root_node = NodePath("..")
	if ResourceLoader.exists(anim_path):
		var anim_scene := (load(anim_path) as PackedScene).instantiate()
		var source_ap := anim_scene.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if source_ap != null:
			for lib_name in source_ap.get_animation_library_list():
				var lib: AnimationLibrary = source_ap.get_animation_library(lib_name)
				var dup_lib: AnimationLibrary = lib.duplicate(true)
				_bind_animation_library_to_skeleton(dup_lib, anim_path)
				anim_player.add_animation_library(lib_name, dup_lib)
		anim_scene.queue_free()

	# Also load Mixamo animation clips assigned in mixamo_pack_map.json
	var pm_res = DataLoader.new().load_json("res://data/animation/mixamo_pack_map.json")
	if pm_res.ok and pm_res.value is Dictionary and pm_res.value.has("fighters"):
		var f_map: Dictionary = pm_res.value["fighters"].get(id, {})
		var actions: Dictionary = f_map.get("actions", {})
		for act_key in actions:
			var clip_info: Dictionary = actions[act_key]
			var clip_file: String = clip_info.get("clip", "")
			if clip_file == "":
				continue
			var anim_glb_path := "res://assets/fighters_mixamo/anims/%s.glb" % clip_file
			if ResourceLoader.exists(anim_glb_path):
				var loaded_glb := (load(anim_glb_path) as PackedScene).instantiate()
				var clip_ap := (
					loaded_glb.find_child("AnimationPlayer", true, false) as AnimationPlayer
				)
				if clip_ap != null:
					for anim_name in clip_ap.get_animation_list():
						var anim: Animation = clip_ap.get_animation(anim_name)
						var target_name: String = str(id) + "_" + str(act_key)
						var default_lib: AnimationLibrary
						if anim_player.has_animation_library(""):
							default_lib = anim_player.get_animation_library("")
						else:
							default_lib = AnimationLibrary.new()
							anim_player.add_animation_library("", default_lib)
						var dup_anim: Animation = anim.duplicate(true)
						_bind_animation_to_skeleton(dup_anim, clip_file)
						if act_key in ["idle", "walk_fwd", "walk_back", "run"]:
							dup_anim.loop_mode = Animation.LOOP_LINEAR
						else:
							dup_anim.loop_mode = Animation.LOOP_NONE
						if default_lib.has_animation(target_name):
							default_lib.remove_animation(target_name)
						default_lib.add_animation(target_name, dup_anim)
				loaded_glb.queue_free()
	fighter_height = float(row["height_mm"]) / 1000.0
	fighter_width = float(row["body"]["shoulder_width"])
	for slot in SimLimbs.LIMB_NAMES:
		var suffix := slot.to_upper()
		groups[slot] = model.find_child("LIMB_" + suffix, true, false)
		stumps[slot] = model.find_child("STUMP_" + suffix, true, false)
		sockets[slot] = model.find_child("SOCKET_" + suffix, true, false)
		if groups[slot] == null or stumps[slot] == null or sockets[slot] == null:
			push_error("Incomplete modular rig: " + id + " " + slot)
			return false
		limb_meshes[slot] = []
		stump_meshes[slot] = []
		var type: String = suffix.substr(0, 3)
		var side: String = suffix.right(1)
		for part in ["UPPER", "LOWER", "END"]:
			var mesh := model.find_child(type + "_" + part + "_" + side, true, false)
			if mesh != null:
				limb_meshes[slot].append(mesh)
		if limb_meshes[slot].is_empty():
			# Support skinned Mixamo meshes partitioned by limb (e.g. *_ARM_L, limb_group="LIMB_ARM_L")
			var target_tag := "LIMB_" + suffix
			var target_suffix := "_" + suffix
			for child in model.find_children("*", "MeshInstance3D", true, false):
				if child.has_meta("limb_group") and str(child.get_meta("limb_group")) == target_tag:
					limb_meshes[slot].append(child)
				elif str(child.name).ends_with(target_suffix):
					limb_meshes[slot].append(child)
		for part in ["CUT_", "BONE_"]:
			var mesh := model.find_child(part + type + side, true, false)
			if mesh != null:
				stump_meshes[slot].append(mesh)
		show_stump(slot, false)
	return true


func is_using_mixamo_model() -> bool:
	return loaded_model_path.begins_with("res://assets/fighters_mixamo/")


func set_limb_visible(slot: String, shown: bool) -> void:
	groups[slot].visible = shown
	for mesh in limb_meshes[slot]:
		mesh.visible = shown


func show_stump(slot: String, shown: bool) -> void:
	stumps[slot].visible = shown
	for mesh in stump_meshes[slot]:
		mesh.visible = (
			shown
			and not (
				str(mesh.name).begins_with("BONE") and SettingsHooks.get_value("gore") == "off"
			)
		)


func attach_to_socket(slot: String, node: Node3D) -> void:
	sockets[slot].add_child(node)


func get_socket_transform(slot: String) -> Transform3D:
	return sockets[slot].global_transform


func apply_palette(id: String) -> void:
	var tint: Color = (
		{"default": Color.WHITE, "ivory": Color(1.0, 0.9, 0.75), "night": Color(0.6, 0.7, 0.95)}
		. get(id, Color.WHITE)
	)
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		for index in mesh.mesh.get_surface_count():
			var material := mesh.get_surface_override_material(index) as StandardMaterial3D
			if material != null:
				material.albedo_color = tint


func attach_regrown(slot: String, id: String) -> bool:
	if not sockets.has(slot):
		return false
	var result := DataLoader.new().load_json("res://data/limbs/%s.json" % id)
	if not result.ok or not slot.begins_with(str(result.value["slot"])):
		return false
	detach_regrown(slot)
	var info := ModelLoader.load_model("res://assets/generated/models/limb_%s.glb" % id)
	if info.root == null:
		return false
	var replacement := info.root
	replacement.set_meta("limb_id", id)
	var base_scale := Vector3(fighter_width / 0.45, fighter_height / 1.8, fighter_width / 0.45)
	# If parent socket is inside a scaled hierarchy (such as Mixamo BoneAttachment3D at 0.01 scale),
	# compensate the scale factor so the limb renders at natural world dimensions.
	var sock: Node3D = sockets[slot] as Node3D
	var sock_global_scale: Vector3 = sock.global_transform.basis.get_scale()
	if sock_global_scale.x > 0.0 and sock_global_scale.x < 0.1:
		base_scale *= (1.0 / sock_global_scale.x)
	replacement.scale = base_scale
	attach_to_socket(slot, replacement)
	replacements[slot] = replacement
	set_limb_visible(slot, false)
	show_stump(slot, false)
	return true


func detach_regrown(slot: String) -> void:
	if replacements.has(slot):
		var old: Node = replacements[slot]
		old.get_parent().remove_child(old)
		old.free()
		replacements.erase(slot)
	set_limb_visible(slot, true)
	show_stump(slot, false)


func sync(fighter: SimFighter) -> void:
	_update_stump_palette()
	for slot in SimLimbs.LIMB_NAMES:
		var state: String = fighter.limbs.parts[slot].state
		var regrown: String = fighter.limbs.parts[slot].regrown_id
		if regrown != "" and state != "severed":
			if not replacements.has(slot) or replacements[slot].get_meta("limb_id") != regrown:
				attach_regrown(slot, regrown)
		elif replacements.has(slot):
			detach_regrown(slot)
		set_limb_visible(slot, state != "severed" and regrown == "")
		show_stump(slot, state == "severed")
		groups[slot].rotation.z = 0.3 if state == "cracked" else 0.0
		pose_limb(slot, 0.3 if state == "cracked" else 0.0)
		if _states.get(slot, "") != state:
			for mesh in limb_meshes[slot]:
				_tint(mesh, Color(0.45, 0.2, 0.35) if state == "bruised" else Color.WHITE)
			_states[slot] = state


func pose_limb(slot: String, angle: float) -> void:
	if skeleton == null:
		return
	var bone_name := ("upper_arm." if slot.begins_with("arm") else "thigh.") + slot.right(1)
	var index := skeleton.find_bone(bone_name)
	if index >= 0:
		skeleton.set_bone_pose_rotation(
			index, _rest_rotations[index] * Quaternion(Vector3.RIGHT, angle)
		)
	if replacements.has(slot):
		replacements[slot].rotation.x = angle


func _tint(node: Node, color: Color) -> void:
	if node is MeshInstance3D:
		var mesh := node as MeshInstance3D
		if color == Color.WHITE:
			mesh.material_overlay = null
		else:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(color, 0.45)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mesh.material_overlay = mat
	for child in node.get_children():
		_tint(child, color)


func _update_stump_palette() -> void:
	var palette := (
		str(SettingsHooks.get_value("gore")) + str(SettingsHooks.get_value("blood_color"))
	)
	if palette == _stump_palette:
		return
	_stump_palette = palette
	var color: Color = (
		{"red": Color("a91830"), "green": Color("54b52b"), "golden": Color("edba44")}
		. get(SettingsHooks.get_value("blood_color"), Color("a91830"))
	)
	if SettingsHooks.get_value("gore") == "off":
		color = Color("555963")
	for meshes in stump_meshes.values():
		for mesh in meshes:
			if str(mesh.name).begins_with("CUT"):
				for surface in mesh.mesh.get_surface_count():
					var material := (
						mesh.get_surface_override_material(surface) as StandardMaterial3D
					)
					if material != null:
						material.vertex_color_use_as_albedo = false
						material.albedo_color = color


static func _get_bone_map() -> Dictionary:
	if _bone_map_cache.is_empty():
		var res: Dictionary = (
			DataLoader.new().load_json("res://data/animation/mixamo_bone_map.json").value
		)
		_bone_map_cache = res.get("bone_map", {})
	return _bone_map_cache


func _bind_animation_library_to_skeleton(lib: AnimationLibrary, source_name: String = "") -> void:
	for anim_name in lib.get_animation_list():
		var anim: Animation = lib.get_animation(anim_name)
		var clip_id := source_name if source_name != "" else str(anim_name)
		_bind_animation_to_skeleton(anim, clip_id)


func _bind_animation_to_skeleton(anim: Animation, source_clip: String = "") -> bool:
	if skeleton == null or anim_player == null:
		return false
	var resolved_root: Node = anim_player.get_node_or_null(anim_player.root_node)
	if resolved_root == null:
		push_error("AnimationPlayer root_node cannot be resolved: " + str(anim_player.root_node))
		return false
	var skel_rel_path: String = str(resolved_root.get_path_to(skeleton))
	var bone_map: Dictionary = _get_bone_map()

	var mapped_required_bones: Dictionary = {}
	var lost_required_bones: Array[String] = []

	var t := anim.get_track_count() - 1
	while t >= 0:
		var track_type: Animation.TrackType = anim.track_get_type(t)
		var orig_path: NodePath = anim.track_get_path(t)
		var sub_part: String = orig_path.get_concatenated_subnames()
		var node_part: String = orig_path.get_concatenated_names()

		var is_3d_transform := (
			track_type == Animation.TYPE_POSITION_3D
			or track_type == Animation.TYPE_ROTATION_3D
			or track_type == Animation.TYPE_SCALE_3D
		)

		if is_3d_transform and sub_part != "":
			var clean_bone: String = sub_part.replace("mixamorig:", "")
			var tgt_bone: String = clean_bone
			if skeleton.find_bone(clean_bone) == -1:
				tgt_bone = bone_map.get(clean_bone, "")

			if tgt_bone != "" and skeleton.find_bone(tgt_bone) != -1:
				var target_path := NodePath(skel_rel_path + ":" + tgt_bone)
				anim.track_set_path(t, target_path)
				binding_audit_log.append(
					{
						"source_clip": source_clip,
						"original_path": str(orig_path),
						"target_path": str(target_path),
						"track_type": track_type,
						"status": "RETAINED",
						"reason": "Resolved to skeleton bone '%s'" % tgt_bone
					}
				)
				if tgt_bone in REQUIRED_BONES:
					mapped_required_bones[tgt_bone] = true
			else:
				var is_allowed_helper := false
				for prefix in ALLOWED_EXCLUDED_TRACKS:
					if clean_bone.begins_with(prefix):
						is_allowed_helper = true
						break
				if is_allowed_helper:
					binding_audit_log.append(
						{
							"source_clip": source_clip,
							"original_path": str(orig_path),
							"target_path": "",
							"track_type": track_type,
							"status": "EXCLUDED",
							"reason": "Explicitly excluded helper track '%s'" % clean_bone
						}
					)
					anim.remove_track(t)
				else:
					if clean_bone in REQUIRED_BONES or tgt_bone in REQUIRED_BONES:
						lost_required_bones.append(clean_bone)
					binding_audit_log.append(
						{
							"source_clip": source_clip,
							"original_path": str(orig_path),
							"target_path": "",
							"track_type": track_type,
							"status": "FAILED",
							"reason":
							"Unresolved required/unallowed skeletal track '%s'" % clean_bone
						}
					)
					anim.remove_track(t)
		elif is_3d_transform and sub_part == "":
			var clean_node := node_part.get_file().replace("mixamorig:", "")
			var tgt_bone: String = clean_node
			if skeleton.find_bone(clean_node) == -1:
				tgt_bone = bone_map.get(clean_node, "")
			if tgt_bone != "" and skeleton.find_bone(tgt_bone) != -1:
				var target_path := NodePath(skel_rel_path + ":" + tgt_bone)
				anim.track_set_path(t, target_path)
				binding_audit_log.append(
					{
						"source_clip": source_clip,
						"original_path": str(orig_path),
						"target_path": str(target_path),
						"track_type": track_type,
						"status": "RETAINED",
						"reason": "Rewrote node path to bone '%s'" % tgt_bone
					}
				)
				if tgt_bone in REQUIRED_BONES:
					mapped_required_bones[tgt_bone] = true
			else:
				var target_node: Node = resolved_root.get_node_or_null(NodePath(node_part))
				if target_node != null:
					binding_audit_log.append(
						{
							"source_clip": source_clip,
							"original_path": str(orig_path),
							"target_path": str(orig_path),
							"track_type": track_type,
							"status": "RETAINED",
							"reason": "Valid non-skeletal 3D node transform"
						}
					)
				else:
					var is_allowed_helper := false
					for prefix in ALLOWED_EXCLUDED_TRACKS:
						if clean_node.begins_with(prefix):
							is_allowed_helper = true
							break
					if is_allowed_helper:
						binding_audit_log.append(
							{
								"source_clip": source_clip,
								"original_path": str(orig_path),
								"target_path": "",
								"track_type": track_type,
								"status": "EXCLUDED",
								"reason": "Excluded helper node '%s'" % clean_node
							}
						)
					else:
						if clean_node in REQUIRED_BONES or tgt_bone in REQUIRED_BONES:
							lost_required_bones.append(clean_node)
						binding_audit_log.append(
							{
								"source_clip": source_clip,
								"original_path": str(orig_path),
								"target_path": "",
								"track_type": track_type,
								"status": "FAILED",
								"reason": "Missing node target: '%s'" % node_part
							}
						)
					anim.remove_track(t)
		else:
			var target_node: Node = resolved_root.get_node_or_null(NodePath(node_part))
			if target_node != null:
				binding_audit_log.append(
					{
						"source_clip": source_clip,
						"original_path": str(orig_path),
						"target_path": str(orig_path),
						"track_type": track_type,
						"status": "RETAINED",
						"reason": "Valid non-transform property/method track"
					}
				)
			else:
				binding_audit_log.append(
					{
						"source_clip": source_clip,
						"original_path": str(orig_path),
						"target_path": "",
						"track_type": track_type,
						"status": "EXCLUDED",
						"reason": "Property target node does not exist: '%s'" % node_part
					}
				)
				anim.remove_track(t)
		t -= 1

	if not lost_required_bones.is_empty():
		push_error(
			(
				"Validation failed: Lost required bone tracks in clip '%s': %s"
				% [source_clip, str(lost_required_bones)]
			)
		)
		return false
	return true

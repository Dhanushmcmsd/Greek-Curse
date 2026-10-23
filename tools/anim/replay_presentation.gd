extends SceneTree


func _initialize() -> void:
 call_deferred("_run")


func _run() -> void:
 var fixture = load("res://tests/proto_fixture.gd")
 var scene := Node3D.new()
 root.add_child(scene)
 current_scene = scene
 var world = fixture.world_with()
 var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/golden/proto_match_01.replay.json"))
 var views: Array = []
 var view_script = load("res://src/presentation/fighter_view.gd")
 for index in 2:
  var view = view_script.new()
  scene.add_child(view)
  view.setup(Color.WHITE, world.fighters[index].height_mm, world.fighters[index].body_width_mm, world.fighters[index].fighter_id)
  views.append(view)
 var started := Time.get_ticks_usec()
 var maximum_reach := 0
 for inputs in data["inputs"]:
  world.step(inputs)
  var before: int = world.hash_state()
  for index in 2:
   views[index].show_fighter(world.fighters[index], world.hitstop_remaining > 0)
   maximum_reach = maxi(maximum_reach, views[index].driver.reach_mismatch_mm)
  if before != world.hash_state():
   push_error("Presentation mutated simulation")
   quit(1)
   return
 if str(world.hash_state()) != data["final_hash"]:
  push_error("Golden mismatch")
  quit(1)
  return
 print("PRESENTATION_REPLAY_OK ticks=", world.tick, " hash=", world.hash_state())
 print("PRESENTATION_US_PER_TICK=", (Time.get_ticks_usec()-started)/data["inputs"].size(), " MAX_REACH_DELTA_MM=", maximum_reach)
 scene.free()
 quit(0)

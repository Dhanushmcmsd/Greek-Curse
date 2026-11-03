extends SceneTree
func _initialize():
 call_deferred("run")
func run():
 for id in ["theron","atalanta","pyrrhus","sibyl","dorian"]:
  var rig=load("res://src/presentation/fighter_rig.gd").new()
  root.add_child(rig)
  rig.load_fighter(id)
  var d=load("res://src/presentation/pose_driver.gd").new()
  d.setup(rig)
  var c=MatchConfig.new()
  c.fighter_ids.assign([id,"theron"])
  var f=load("res://src/presentation/match_launcher.gd").make_world(c).fighters[0]
  d._drive_clip(f,false)
  for side in ["l","r"]:d._solve_guard_arm(side,0.0,true)
  print(id," HEAD ",rig.skeleton.get_bone_global_pose(rig.skeleton.find_bone("head")).origin)
  for n in ["upper_arm.l","forearm.l","hand.l","upper_arm.r","forearm.r","hand.r"]:print("GUARD ",n," ",rig.skeleton.get_bone_global_pose(rig.skeleton.find_bone(n)).origin)
  load("res://src/presentation/combat_pose_constraints.gd").apply(rig,f)
  for n in ["forearm.l","hand.l","forearm.r","hand.r"]:print("AFTER ",n," ",rig.skeleton.get_bone_global_pose(rig.skeleton.find_bone(n)).origin)
  rig.free()
 quit()

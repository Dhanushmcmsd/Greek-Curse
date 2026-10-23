class_name SimHitResolver
extends RefCounted
## One hurtbox per attack. Head wins, then the limb with the largest overlap.


static func overlaps(a: Array, b: Array) -> bool:
	if int(a[0]) + int(a[2]) <= int(b[0]):
		return false
	if int(b[0]) + int(b[2]) <= int(a[0]):
		return false
	if int(a[1]) + int(a[3]) <= int(b[1]):
		return false
	if int(b[1]) + int(b[3]) <= int(a[1]):
		return false
	return true


static func overlap_area(a: Array, b: Array) -> int:
	var width := mini(int(a[0]) + int(a[2]), int(b[0]) + int(b[2])) - maxi(int(a[0]), int(b[0]))
	var height := mini(int(a[1]) + int(a[3]), int(b[1]) + int(b[3])) - maxi(int(a[1]), int(b[1]))
	if width <= 0 or height <= 0:
		return 0
	return width * height


static func choose_zone(hitbox: Array, boxes: Array, order: Array) -> String:
	var head := ""
	var torso := ""
	var best_name := ""
	var best_area := -1
	var best_index := 999
	for box in boxes:
		var spec: Dictionary = box
		var rect: Array = spec["rect"]
		if not overlaps(hitbox, rect):
			continue
		var zone := str(spec["name"])
		if zone == "head":
			head = zone
		elif zone == "torso":
			torso = zone
		else:
			var area := overlap_area(hitbox, rect)
			var index := _order_index(zone, order)
			var better := area > best_area or (area == best_area and index < best_index)
			if better:
				best_area = area
				best_index = index
				best_name = zone
	if head != "":
		return head
	if best_name != "":
		return best_name
	return torso


static func _order_index(zone: String, order: Array) -> int:
	for index in order.size():
		if str(order[index]) == zone:
			return index
	return 999

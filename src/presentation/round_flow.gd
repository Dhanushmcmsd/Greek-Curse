class_name RoundFlow
extends RefCounted

var phase: String = "intro"
var remaining: int = 45
var paused: bool = false
var banner: String = "TRIALS OF OLYMPUS"


func advance() -> bool:
	if paused or phase == "results":
		return false
	if remaining > 0:
		remaining -= 1
		return false
	match phase:
		"intro":
			phase = "ready"
			banner = "READY"
			remaining = 45
		"ready", "round_end":
			phase = "fight"
			banner = "FIGHT"
		"match_end":
			phase = "results"
	return phase == "fight"


func consume(events: Array) -> void:
	for event in events:
		if event.kind == SimEvent.Kind.ROUND_END:
			phase = "round_end"
			remaining = 90
			banner = "ROUND OVER"
		elif event.kind == SimEvent.Kind.MATCH_END:
			phase = "match_end"
			remaining = 120
			banner = "MATCH COMPLETE"
		elif event.kind == SimEvent.Kind.KO:
			banner = "KNOCKOUT"

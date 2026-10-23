class_name SimEvent
extends RefCounted
## A fact the presentation may read. It cannot change the simulation.

enum Kind { HIT, KO, ROUND_START, ROUND_END, MATCH_END }

var kind: int = Kind.HIT
var actor: int = -1
var other: int = -1
var amount: int = 0
var round_index: int = 1
var winner: int = -1


static func make(
	kind: int, actor: int, other: int, amount: int, round_index: int, winner: int
) -> SimEvent:
	var event := SimEvent.new()
	event.kind = kind
	event.actor = actor
	event.other = other
	event.amount = amount
	event.round_index = round_index
	event.winner = winner
	return event

class_name SimEvent
extends RefCounted
## A fact the presentation may read. It cannot change the simulation.

enum Kind {
	HIT,
	KO,
	ROUND_START,
	ROUND_END,
	MATCH_END,
	BLOCK,
	METER,
	GRAB,
	LIMB_STATE_CHANGED,
	LIMB_SEVERED,
	DESPERATE_FURY_STARTED,
	LIMB_CAP_BLOCKED,
	COMBO_EXTENDED,
	LIMB_QUIRK,
	HAZARD,
	ABILITY
}

var kind: int = Kind.HIT
var actor: int = -1
var other: int = -1
var amount: int = 0
var round_index: int = 1
var winner: int = -1
var payload: Dictionary = {}


static func make(
	kind_value: int, actor_value: int, other_value: int, amount_value: int, round_index_value: int, winner_value: int
) -> SimEvent:
	var event := SimEvent.new()
	event.kind = kind_value
	event.actor = actor_value
	event.other = other_value
	event.amount = amount_value
	event.round_index = round_index_value
	event.winner = winner_value
	return event

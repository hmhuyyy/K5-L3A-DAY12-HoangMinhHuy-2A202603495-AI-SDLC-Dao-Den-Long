# EventBus.gd — Collects events generated within a single tick.
# Events are flushed after the tick completes and written immediately.
class_name EventBus
extends RefCounted

# Each event: {"type":"event","tick":N,"name":"...","data":{...}}
var _events: Array[Dictionary] = []

func reset() -> void:
	_events.clear()

func record(tick: int, name: String, data: Dictionary) -> void:
	_events.append({
		"type": "event",
		"tick": tick,
		"name": name,
		"data": data
	})

func drain() -> Array[Dictionary]:
	var out := _events.duplicate(true)
	_events.clear()
	return out

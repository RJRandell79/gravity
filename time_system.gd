extends Node

## Two clocks: ship-time (elapsed for the crew) and calendar-time (elapsed
## for everyone else). They tick together during normal flight; events like
## a black hole jump will later advance calendar-time without ship-time.
##
## Registered as an autoload singleton so it persists across scene reloads
## instead of resetting with the scene tree.

var ship_time: float = 0.0
var calendar_time: float = 0.0

@export var debug_log_interval: float = 1.0

var _debug_accum: float = 0.0

func _process(delta: float) -> void:
	ship_time += delta
	calendar_time += delta

	_debug_accum += delta
	if _debug_accum >= debug_log_interval:
		_debug_accum -= debug_log_interval
		print("ship_time=%.1f calendar_time=%.1f" % [ship_time, calendar_time])

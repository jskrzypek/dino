extends Machine


func transit(state_name, args = {}):
	.transit(state_name, args)
	# interesting, but connecting to the transitioned event instead
	# owner.set_state_label(state_name)

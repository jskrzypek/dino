tool
extends Node2D

export(Array, PackedScene) var room_options = []
export(PackedScene) var final_room
export(Array, PackedScene) var gap_room_options

var room_queue = []
var current_rooms = []
var total_room_width = 0
var active_room_count = 3

export(int) var finishable_room_count = 5
var finishable_rooms_to_add = 5

# Called when the node enters the scene tree for the first time.
func _ready():
	if not room_options:
		print("[WARN]: no room options!")

	finishable_rooms_to_add = finishable_room_count
	clear_current_rooms()

	# should we wait to add the player after the rooms are ready?
	add_rooms_to_scene(active_room_count)

	if Engine.editor_hint:
		request_ready()

func clear_current_rooms():
	for r in current_rooms:
		r.queue_free()

	var to_del = []
	for r in current_rooms:
		to_del.append(r)
	for r in to_del:
		current_rooms.erase(r) # is this even necssary after they are queue_freed? probably?
	total_room_width = 0

var no_more_rooms = false

func get_next_room_instance():
	# return unfinished room first
	# TODO may want to mix this back into the randoms
	if room_queue:
		var room_i = randi() % room_queue.size()
		return room_queue.pop_at(room_i)

	var current_unfinished
	for r in current_rooms:
		if not r.is_finished():
			current_unfinished = r
			break

	# no more randoms? lets add gaps/unfinished rooms until they're all done
	if finishable_rooms_to_add <= 0:
		if room_queue or current_unfinished:
			var opts = gap_room_options

			# TODO assigned rooms could opt-in here
			# but i don't want to instance every room just to check it
			# could also find and re-use an existing instance...?
			# but then we'd want to create a new one, right?
			# for r in room_options:
			# 	if not r in opts && r.is_gap(): # can't call is_gap on instance
			# 		opts.append(r)

			var room_i = randi() % opts.size()
			var room_opt = opts[room_i]
			return room_opt.instance()
		else:
			# use final room when unfinished and random queue are empty
			no_more_rooms = true
			return final_room.instance()

	# none queued, pulling new random room
	var room_i = randi() % room_options.size()
	var room_opt = room_options[room_i]

	var inst = room_opt.instance()

	# already finished rooms do not count towards this
	# this lets us decide how many rooms a user has to 'finish'
	# might look into favoring finishable rooms more in this randomness
	# might not!
	if inst.is_finished():
		finishable_rooms_to_add -= 1

	return inst

func prep_room():
	if no_more_rooms:
		return

	var next_room = get_next_room_instance()

	# could abstract this prep out, it's runner specific
	var next_w = next_room.room_width()
	var offset_x = total_room_width + next_w / 2
	next_room.position.x = offset_x

	# update width so we can keep appending rooms
	total_room_width += next_w

	Util.ensure_connection(next_room, "player_entered", self, "room_entered", [next_room])
	Util.ensure_connection(next_room, "player_exited", self, "room_exited", [next_room])

	# update rooms array
	current_rooms.append(next_room)

	return next_room

func add_rooms_to_scene(count: int):
	for i in count:
		var room = prep_room()
		if room:
			# only need to add newly instanced rooms
			# the others get moved when .position.x is set
			if not room.get_parent():
				call_deferred("add_child", room, true)

func room_entered(_player, room):
	print("\n\n--------------------------------------------------------------------")
	print("entered: ", room)
	print(current_rooms.size(), " current rooms: ", current_rooms)
	print(room_queue.size(), " in room queue:", room_queue)
	var current_room_index = current_rooms.find(room)
	var current_room_count = current_rooms.size()
	var remaining_rooms = current_room_count - 1 - current_room_index
	var rooms_to_make = active_room_count - remaining_rooms

	if rooms_to_make:
		add_rooms_to_scene(rooms_to_make)

func room_exited(_player, room):
	var exited_room_index = current_rooms.find(room)

	# check just-exited room for completion
	if not room.is_finished():
		if not room_queue.has(room):
			room_queue.append(room)

	# remove rooms before the just-exited one
	var to_delete = []
	var to_remove = []

	for idx in exited_room_index - 2: # subtract 2 for some buffer
		var r = current_rooms[idx]
		# TODO remove these extra is_finished calls... :/
		if r.is_finished():
			to_delete.append(r)
		else:
			to_remove.append(r)

	# delete in separate loop b/c array indexes shift in place
	for r in to_delete:
		current_rooms.erase(r)
		r.queue_free()

	for r in to_remove:
		# if we use current to add gaps when something is incomplete, we can't really erase here
		current_rooms.erase(r)
		# remove from current_rooms and scene, but don't queue_free
		# TODO this may not be in the scene/a child anymore
		# not sure if we want to remove this or not
		# r.get_parent().remove_child(r)
		# call_deferred("remove_child", r)

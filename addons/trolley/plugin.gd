tool
extends EditorPlugin


func _enter_tree():
	print("[TROLLEY] entering tree")
	add_autoload_singleton("Trolley", "res://addons/trolley/Trolley.gd")


func _exit_tree():
	print("[TROLLEY] exiting tree")
	remove_autoload_singleton("Trolley")

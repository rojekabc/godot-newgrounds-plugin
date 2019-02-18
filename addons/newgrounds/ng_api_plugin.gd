tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("NewGroundsAPI", "HTTPRequest", preload("res://addons/newgrounds/NewGroundsAPI.gd"), preload("res://addons/newgrounds/ng16.png"))

func _exit_tree():
	remove_custom_type("NewGroundsAPI")




	

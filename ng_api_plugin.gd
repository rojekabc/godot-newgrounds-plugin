tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("NewGroundsAPI", "HTTPRequest", preload("res://addons/ng_api_plugin/NewGroundsAPI.gd"), preload("res://addons/ng_api_plugin/ng16.png"))

func _exit_tree():
	remove_custom_type("NewGroundsAPI")




	

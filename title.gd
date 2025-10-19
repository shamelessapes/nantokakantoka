extends Control

var is_option_window_open := false

func _ready():
	Global.fade_in(Color.BLACK,1.0)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	$start.grab_focus()  # ← 最初にこのUIを選択状態にする
	
	$start.pressed.connect(on_start)
	$option/Window.hide()
	$option.pressed.connect(go_to_option)
	$option/Window.close_requested.connect(on_window_close_requested)
	$option/Window/CanvasLayer/exit_window.pressed.connect(on_window_close_requested)
	$exit.pressed.connect(on_exit)
	
func on_start():
	await Global.change_scene_with_fade("res://tscn/main.tscn" , Color.BLACK)
	
func go_to_option():
	is_option_window_open = true
	$option/Window.show()
	$option/Window/CanvasLayer/DisplayModeOption.grab_focus()  
	


func on_window_close_requested():
	is_option_window_open = false
	$option/Window.hide()
	$option.grab_focus()
	
func on_exit():
	get_tree().quit()

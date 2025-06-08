class_name SkillNameUI
extends Control

@onready var label = $SkillNameLabel

func show_skill_name(name: String):
	label.text = name
	label.visible = true

func hide_skill_name():
	label.visible = false

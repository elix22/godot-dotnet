extends Node
@onready var ui: Label = $CanvasLayer/UI

func _ready() -> void:
	var s = Summator.new()
	s.Add(10)
	s.Add(20)
	s.Add(30)
	s.Add(40)
	print(s.GetTotal())
	ui.text = "Total: " + str(s.GetTotal())
	s.Reset()

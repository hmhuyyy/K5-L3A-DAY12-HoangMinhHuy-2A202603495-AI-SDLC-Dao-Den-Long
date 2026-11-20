# capture_screenshot.gd — Captures a real 1280x720 screenshot of GameScene 3D for README.md.
# Run: godot --path . --script res://src/tools/capture_screenshot.gd
extends SceneTree

var _frames := 0
var _scene: Node3D

func _init() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var packed: PackedScene = load("res://src/gameplay/GameScene.tscn")
	_scene = packed.instantiate()
	get_root().add_child(_scene)

func _process(delta: float) -> bool:
	_frames += 1
	if _frames == 2 and _scene != null:
		# Light L1 and spawn 2 shades near the player so the screenshot shows active gameplay
		_scene._sim.lanterns[0].lit = true
		_scene._sim.lanterns[0].fuel_units = 4800
		_scene._sim.lanterns[1].lit = true
		_scene._sim.lanterns[1].fuel_units = 1500
		var sd1 := Entities.ShadeData.new()
		sd1.id = "S1"
		sd1.pos = Vector3(3.5, 0.0, 5.0)
		sd1.state = Entities.SHADE_CHASE
		_scene._sim.shades.append(sd1)
		var sd2 := Entities.ShadeData.new()
		sd2.id = "S2"
		sd2.pos = Vector3(-4.0, 0.0, 6.0)
		sd2.state = Entities.SHADE_WANDER
		_scene._sim.shades.append(sd2)
		_scene._sync_visuals()
		_scene._update_hud()
	if _frames == 12:
		var tex := get_root().get_texture()
		if tex != null:
			var img := tex.get_image()
			if img != null:
				DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/media"))
				img.save_png(ProjectSettings.globalize_path("res://docs/media/gameplay.png"))
				print("Saved screenshot to docs/media/gameplay.png (%dx%d)" % [img.get_width(), img.get_height()])
		quit(0)
		return true
	return false

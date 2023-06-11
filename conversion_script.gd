#@tool
extends Node
class_name MyNode


# Originally used in the context of a different project, putting it in this repo for
# documentation purposes.


var xml_parser:= XMLParser.new()
var frame_data: Array[Dictionary]




func _ready() -> void:
	var file_names: PackedStringArray
	var path:= "res://addons/duelyst_animated_sprites/assets/spritesheets/units/"
	var dir = DirAccess.open(path)
	if dir:
		file_names = dir.get_files()
	
	for file_name in file_names:
		if file_name.ends_with(".plist"):
			_parse_frames(path + file_name)


func _parse_frames(dir: String):
	#parse frames
	var basename = dir.get_file().get_basename()
	xml_parser.open(dir)
	while xml_parser.read() == OK:
		if xml_parser.get_node_type() == XMLParser.NODE_TEXT:
			var text:= xml_parser.get_node_data()
			if text.ends_with(".png"):
				parse_frame(text.get_basename())
	
	#make the spriteframes
	var spriteframes:= SpriteFrames.new()
	
	# last element contains png name, handle it later, dump it now
	frame_data.pop_back()
	
	for frame in frame_data:
		var name_parts: PackedStringArray = frame["name"].split("_")
		var index: int = name_parts[-1].to_int()
		var animation_name: String = name_parts[-2]
		
		var texture:= AtlasTexture.new()
		texture.set_atlas(load(dir.get_basename() + ".png"))
		texture.set_region(frame["rect"])
		
		if not spriteframes.has_animation(animation_name):
			spriteframes.add_animation(animation_name)
			spriteframes.set_animation_speed(animation_name, 9)
		spriteframes.add_frame(animation_name, texture, 1.0, index)
	
	frame_data.clear()
	spriteframes.remove_animation("default")
	
	ResourceSaver.save(spriteframes,
	"res://addons/duelyst_animated_sprites/assets/spriteframes/units/%s.tres" % basename)


func parse_frame(frame_name: String) -> void:
	var frame: Dictionary = {}
	var current_key: String
	while xml_parser.read() == OK:
		match xml_parser.get_node_type():
			XMLParser.NODE_ELEMENT:
				match xml_parser.get_node_name():
					"dict":
						frame = {}
					"key":
						xml_parser.read()
						current_key = xml_parser.get_node_data()
					"string":
						xml_parser.read()
						match current_key:
							"size":
								return
							"frame":
								frame["name"] = frame_name
								frame["rect"] = parse_rect(xml_parser.get_node_data())
							"offset": # All other fields seem to be useless.
								pass
							"rotated":
								pass
							"sourceColorRect":
								pass
							"sourceSize":
								pass
							_:
								printerr("unkown frame info type: %s at %s" % [current_key, frame_name])
			
			XMLParser.NODE_ELEMENT_END:
				if xml_parser.get_node_name() == "dict":
					frame_data.push_back(frame)
					return


func parse_rect(rect_str: String) -> Rect2:
	rect_str = "Rect2(" + rect_str.replace("}", "").replace("{", "").replace(",", ", ") + ")"
	return str_to_var(rect_str)





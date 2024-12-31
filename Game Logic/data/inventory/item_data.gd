extends Resource
class_name ItemData

#mostly taken from https://www.youtube.com/watch?v=V79YabQZC1s

@export var name: String = ""
# Description before catgirl explains it to you
@export_multiline var description: String = ""
# Description after she explains it to you, if applicable
@export var magical: bool = false
@export_multiline var magicalDescription: String = ""
@export var stackable: bool = false
@export var texture: AtlasTexture
@export var placeable: bool = false
## Object_Data to place, if placeable 
@export var object_data: ObjectData

#unsure about these
@export var value: int = 1
@export var rarity: int = 1

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
@export var quality: int = 0

@export_category("Build Data")
@export var placeable: bool = false
@export var required_space: Vector2i = Vector2i.ONE
## Object_Data to place, if placeable 
@export var object_id: String

@export_category("Econ Data")
#unsure about these
@export var sellable: bool = true
@export var value: int = 1
@export var rarity: int = 1

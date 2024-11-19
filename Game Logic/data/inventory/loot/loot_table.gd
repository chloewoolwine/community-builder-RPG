extends Resource
class_name LootTable

@export var loot_table_entries: Array[LootTableEntry]
@export var gaurrantee_drop: Array[LootTableEntry]
@export var how_many_rolls: int = 1 #how many times to roll!
#use if i want super rare items to drop As Well As ALL of the less rares
#good for trees -> maybe they'll drop an acorn or two :D 
@export var continue_dropping: bool #if an item is hit, do we continue adding more?

#full disclosure: no idea if this actuall works
func roll(rng:RandomNumberGenerator) -> Array[ItemData]:
	var arr : Array[ItemData]= []
	
	for x in range(how_many_rolls):
		var vroll := rng.randi_range(1, 100)
		var chance_calculator := 0
		for entry in loot_table_entries:
			chance_calculator += entry.drop_chance
			if vroll <= chance_calculator:
				for number in range(entry.amount):
					if entry.item_data:
						arr.append(entry.item_data)
				if !continue_dropping:
					break
	
	if gaurrantee_drop.size() > 0:
		for entry in gaurrantee_drop:
			for number in range(entry.amount):
				arr.append(entry.item_data)
	
	return arr

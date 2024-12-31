extends Resource
class_name LootTable

@export var guaranteed_drops: Array[LootTableEntry] ## Drops that WILL occur no matter what
@export var loot_table_entries: Array[LootTableEntry] ## Weight MUST add up to 100
@export var num_rolls: int = 1 ## Number of rolls that should be done

#full disclosure: no idea if this actuall works
func roll(rng:RandomNumberGenerator, rolls: int = num_rolls, drop_guarantee:bool=true) -> Array[ItemData]:
	var arr : Array[ItemData]= []
	var weights := 0
	for entry:LootTableEntry in loot_table_entries:
		weights += entry.weight
	if weights == 100:
		for x in range(rolls):
			var vroll := rng.randi_range(1, 100)
			var chance_calculator := 0
			for entry in loot_table_entries:
				chance_calculator += entry.weight
				if vroll <= chance_calculator:
					if entry.item_data:
						for number in range(entry.amount):
							arr.append(entry.item_data)
					break;
	
	if guaranteed_drops.size() > 0 and drop_guarantee:
		for entry in guaranteed_drops:
			for number in range(entry.amount):
				arr.append(entry.item_data)
	
	return arr

extends Resource
class_name LootTable

@export var loot_table_entries: Array[LootTableEntry] ## Weight MUST add up to 100
@export var num_rolls: int = 1 ## Number of rolls that should be done

#full disclosure: no idea if this actuall works
func roll(rng:RandomNumberGenerator, rolls: int = num_rolls, _drop_guarantee:bool=true) -> Array[ItemData]:
	var arr : Array[ItemData]= []
	for x in range(rolls):
		for entry in loot_table_entries:
			if entry.chance == 1.0:
				for number in range(entry.amount):
					arr.append(entry.item_data)
			else:
				var vroll := rng.randf()
				if vroll <= entry.chance:
					if entry.item_data:
						for number in range(entry.amount):
							arr.append(entry.item_data)
	return arr

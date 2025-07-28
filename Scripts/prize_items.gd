class_name PrizeItems
extends Resource

enum Source
{
	Affairs,
	Traffic,
	Lottery,
	Trade,
	Grape,
	Apple,
	Strawberry,
	Watermelon,
	Mango,
	Banana,
}

@export var prize_name_text: String
@export var item_list: Dictionary[String, int]
@export var sources_of_prize: Array[Source]
@export var weight_in_pool: float = 1.0

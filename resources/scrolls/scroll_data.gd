class_name ScrollData
extends Resource

enum Category { BASE, AREA, BUFF }

@export var id: StringName
@export var display_name: String
@export var category: Category = Category.BASE

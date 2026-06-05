extends Control

func _ready() -> void:
	print("\n=== ACTUAL TREE STRUCTURE ===\n")
	_print_tree(self, 0)
	print("\n=== END TREE ===\n")

func _print_tree(node: Node, indent: int) -> void:
	var prefix = ""
	for i in range(indent):
		prefix += "  "
	
	print(prefix + node.name + " (" + node.get_class() + ")")
	
	for child in node.get_children():
		_print_tree(child, indent + 1)

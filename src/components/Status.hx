package components;

@:publicFields
class Status {
	var watered: Bool = false;
	var deficient: Bool = false;
	var fertilized: Bool = false;
	var message: String = null;
	function new() {}
}

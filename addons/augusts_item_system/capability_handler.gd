extends RefCounted
class_name CapabilityHandler

func execute(target: Node, capability_data: ItemCapability):
	push_error("The 'execute' method must be overridden in the concrete handler: %s" % get_script().resource_path)

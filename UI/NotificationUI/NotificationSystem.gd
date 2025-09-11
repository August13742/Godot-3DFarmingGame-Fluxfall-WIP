extends Node




var item_toast_manager:ItemToastManager

func item_added(item_name:String, qty:int, severity:=1, icon:CompressedTexture2D=null, key:StringName=&""):
	if item_toast_manager: item_toast_manager.post(item_name, qty, severity, icon, key)

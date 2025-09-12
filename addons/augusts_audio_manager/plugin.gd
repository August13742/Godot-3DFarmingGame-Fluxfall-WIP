@tool
extends EditorPlugin


const AUDIO_MANAGER_SINGLETON_NAME = "AudioManager"
const ADDON_BASE_PATH = "res://addons/augusts_audio_manager"
const RESOURCE_BASE_PATH = "res://addons/augusts_audio_manager/resource_scripts"
const AUDIO_MANAGER_SCRIPT_PATH = ADDON_BASE_PATH+"/AudioManager.gd"


func _enter_tree():
	# --- Register Singleton ---
	add_autoload_singleton(AUDIO_MANAGER_SINGLETON_NAME, AUDIO_MANAGER_SCRIPT_PATH)

	# --- Register Custom Types ---
	add_custom_type("MusicResource", "Resource",
	preload(RESOURCE_BASE_PATH+"/music_resource.gd"),
	preload(ADDON_BASE_PATH+"/icons/icon_audio.png"))
	
	add_custom_type("MusicPlaylistResource", "Resource",
	preload(RESOURCE_BASE_PATH+"/music_playlist_resource.gd"),
	preload(ADDON_BASE_PATH+"/icons/icon_parchment.png")
	)
	
	add_custom_type("SFXResource", "Resource",
	preload(RESOURCE_BASE_PATH+"/sfx_resource.gd"),
	preload(ADDON_BASE_PATH+"/icons/icon_audio.png"))
	
	add_custom_type("SFXPlaylistResource", "Resource",
	preload(RESOURCE_BASE_PATH+"/sfx_playlist_resource.gd"),
	preload(ADDON_BASE_PATH+"/icons/icon_parchment.png")
	)
func _exit_tree():
	# Clean up when the plugin is disabled to keep the project clean.
	remove_autoload_singleton(AUDIO_MANAGER_SINGLETON_NAME)
	remove_custom_type("MusicResource")
	remove_custom_type("MusicPlaylistResource")
	remove_custom_type("SFXResource")
	remove_custom_type("SFXPlaylistResource")

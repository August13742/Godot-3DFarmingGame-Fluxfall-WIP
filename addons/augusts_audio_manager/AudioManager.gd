extends Node
## Centralised audio singleton for SFX and Music.

##
## Recommended bus setup:
##   Master ─┬─ Music
##           └─ SFX
##
## See also: play_sfx, play_music, stop_sfx.

#region Signals
## Emitted when a sound finishes.
## - For looping SFX: emits (event_name, -1) when stopped.
## - For tracked one-shot SFX: emits (event_name, voice_id) on completion.
signal sfx_finished(event_name: StringName, voice_id: int)
#endregion

#region Properties
## --- Buses (cached) ---
var _bus_master := -1
var _bus_music  := -1
var _bus_sfx    := -1

## --- Global options ---
@export var process_always := true
@export var enable_spatial_api := true
@export var sfx_default_pitch_range := Vector2(0.9, 1.1)
@export var sfx_default_vol_range   := Vector2(0.95, 1.0)
@export var max_linear_gain := 2.5

## --- Internal State ---
var _one_shot_finish_timers: Array[Dictionary] = []
var _poly_player: AudioStreamPlayer
var _poly_stream := AudioStreamPolyphonic.new()
var _looping_sfx_players: Dictionary[StringName, AudioStreamPlayer] = {}
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _active_is_a := true
var _music_target_volume := 1.0
var _music_fade_tween: Tween
var _current_music_resource: MusicResource
#endregion

#region Godot Lifecycle
func _ready():
	self.process_mode = Node.PROCESS_MODE_ALWAYS if process_always else Node.PROCESS_MODE_INHERIT
	_resolve_buses()
	_init_poly_sfx()
	_init_music_players()

func _process(_delta: float) -> void:
	if _one_shot_finish_timers.is_empty():
		return
	
	var current_time_ms = Time.get_ticks_msec()
	for i in range(_one_shot_finish_timers.size() - 1, -1, -1):
		if current_time_ms >= _one_shot_finish_timers[i].get(&"finish_time_ms"):
			var data := _one_shot_finish_timers[i]
			sfx_finished.emit(data.get(&"event_name"), data.get(&"voice_id"))
			_one_shot_finish_timers.remove_at(i)
			
func _exit_tree():
	for p in _looping_sfx_players.values():
		if is_instance_valid(p): p.stop(); p.queue_free()
	_looping_sfx_players.clear()
	if is_instance_valid(_poly_player): _poly_player.stop()
	if is_instance_valid(_music_a): _music_a.stop()
	if is_instance_valid(_music_b): _music_b.stop()
#endregion

#region Internal Setup
func _resolve_buses():
	_bus_master = AudioServer.get_bus_index("Master")
	_bus_music  = AudioServer.get_bus_index("Music")
	_bus_sfx    = AudioServer.get_bus_index("SFX")
	assert(_bus_master != -1 and _bus_music != -1 and _bus_sfx != -1, "Audio buses 'Master/Music/SFX' must exist.")

func _init_poly_sfx():
	_poly_player = AudioStreamPlayer.new()
	_poly_player.stream = _poly_stream
	_poly_player.bus = "SFX"
	add_child(_poly_player)
	_poly_player.play()

func _init_music_players():
	_music_a = AudioStreamPlayer.new()
	_music_b = AudioStreamPlayer.new()
	_music_a.bus = "Music"; _music_b.bus = "Music"
	_music_a.volume_linear = 0.0; _music_b.volume_linear = 0.0
	add_child(_music_a); add_child(_music_b)
#endregion

#region Utilities
func _clamp_params(vol: float, pitch: float, allow_boost := true) -> Array:
	var vmax := max_linear_gain if allow_boost else 1.0
	return [clamp(vol, 0.0, vmax), clamp(pitch, 0.25, 4.0)]

static func _force_loop(stream: AudioStream) -> AudioStream:
	var s: AudioStream = stream.duplicate()
	if s is AudioStreamOggVorbis: s.loop = true
	elif s is AudioStreamWAV: s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	return s

func _active_music() -> AudioStreamPlayer:
	return _music_a if _active_is_a else _music_b

func _inactive_music() -> AudioStreamPlayer:
	return _music_b if _active_is_a else _music_a

func _track_sfx_finish(event_name: StringName, stream: AudioStream, voice_id: int, pitch_scale: float) -> void:
	var stream_length = stream.get_length() if stream else 0.0
	if stream_length <= 0.0 or pitch_scale <= 0.0: return
	
	var real_duration_ms = (stream_length / pitch_scale) * 1000.0
	var abs_finish_time = Time.get_ticks_msec() + real_duration_ms
	
	_one_shot_finish_timers.append({
		&"event_name": event_name,
		&"voice_id": voice_id,
		&"finish_time_ms": abs_finish_time
	})

func _poly() -> AudioStreamPlaybackPolyphonic:
	var pb = _poly_player.get_stream_playback()
	return pb as AudioStreamPlaybackPolyphonic

## Ensures a music stream has the correct loop flag.
static func _force_music_loop(stream: AudioStream, should_loop: bool) -> AudioStream:
	var s: AudioStream = stream.duplicate()
	if s is AudioStreamOggVorbis: s.loop = should_loop
	elif s is AudioStreamWAV: s.loop_mode = AudioStreamWAV.LOOP_FORWARD if should_loop else AudioStreamWAV.LOOP_DISABLED
	return s
	
#endregion

#region Public API - High Level (Resource-Based)
## The primary method for playing a sound effect from a resource.
## [param volume_scale]: A multiplier for the resource's base volume.
## [b]Returns:[/b] The voice ID if a tracked one-shot is played, otherwise -1.
func play_sfx(resource: SFXResource, volume_scale := 1.0) -> int:
	if not resource or not resource.stream:
		push_warning("[AudioManager] play_sfx called with an invalid resource.")
		return -1

	var final_volume = resource.volume_linear * volume_scale
	if resource.loop:
		play_sfx_loop(resource.event_name, resource.stream, final_volume, resource.pitch_scale)
		return -1
	else:
		return play_sfx_one_shot(resource.stream, final_volume, resource.pitch_scale, resource.event_name, resource.track_finish)

## Plays a random one-shot SFX from an array of resources.
## Applies optional volume and pitch jitter to the selected resource's base values.
func play_sfx_random(playlist:SFXPlaylistResource, volume_scale := 1.0, pitch_jitter := 0.0, vol_jitter := 0.0) -> int:
	if playlist.sfx_resources.is_empty(): return -1
	
	var resource: SFXResource = playlist.sfx_resources.pick_random()
	if not resource or not resource.stream:
		push_warning("[AudioManager] play_sfx_random picked an invalid resource.")
		return -1

	var final_pitch = resource.pitch_scale * randf_range(1.0 - pitch_jitter, 1.0 + pitch_jitter)
	var final_volume = resource.volume_linear * volume_scale * randf_range(1.0 - vol_jitter, 1.0 + vol_jitter)

	return play_sfx_one_shot(resource.stream, final_volume, final_pitch, resource.event_name, resource.track_finish)

## Plays a positional one-shot SFX from a resource.
func play_sfx_at_position(resource: SFXResource, pos: Vector2, volume_scale := 1.0):
	if not resource or not resource.stream:
		push_warning("[AudioManager] play_sfx_at_position called with an invalid resource.")
		return

	if resource.loop:
		push_warning("[AudioManager] Looping SFX cannot be played positionally. Use a standard Node2D with an AudioStreamPlayer2D for this.")
		return

	var final_volume = resource.volume_linear * volume_scale
	play_sfx_at_position_from_stream(resource.stream, pos, final_volume, resource.pitch_scale)

## Stops a looping SFX using its resource definition.
func stop_sfx(resource: SFXResource, fade_out_s := 0.0):
	if resource and resource.loop:
		stop_looped_sfx(resource.event_name, fade_out_s)
#endregion

#region Public API - Low Level (Parameter-Based)
## (Low-Level) Plays a one-shot SFX. Prefer using the resource-based play_sfx().
func play_sfx_one_shot(stream: AudioStream, volume_linear := 1.0, pitch_scale := 1.0, event_name: StringName = &"__anonymous__", track_finish := false) -> int:
	var params = _clamp_params(volume_linear, pitch_scale, true)
	var pb := _poly()
	if pb == null:
		push_error("[AudioManager] Polyphonic playback unavailable.")
		return -1

	var voice_id: int = pb.play_stream(stream, 0.0, linear_to_db(params[0]), params[1])
	if voice_id < 0:
		push_warning("[AudioManager] Polyphonic voice allocation failed.")
		return -1

	if track_finish:
		_track_sfx_finish(event_name, stream, voice_id, pitch_scale)
	return voice_id

## (Low-Level) Plays a random SFX from a list with optional jitter.
func play_sfx_random_from_streams(streams: Array[AudioStream], event_name: StringName = &"__anonymous__", base_vol := 1.0, base_pitch := 1.0, pitch_jitter := 0.05, vol_jitter := 0.0, track_finish := false) -> int:
	if streams.is_empty(): return -1
	var s: AudioStream = streams.pick_random()
	var p := base_pitch * randf_range(1.0 - pitch_jitter, 1.0 + pitch_jitter)
	var v := base_vol   * randf_range(1.0 - vol_jitter,   1.0 + vol_jitter)
	return play_sfx_one_shot(s, v, p, event_name, track_finish)


## (Low-Level) Starts or replaces a named looping SFX.
func play_sfx_loop(event_name: StringName, stream: AudioStream, volume_linear := 1.0, pitch_scale := 1.0):
	stop_looped_sfx(event_name)
	var loop_player := AudioStreamPlayer.new()
	loop_player.bus = "SFX"
	loop_player.stream = _force_loop(stream)
	var params = _clamp_params(volume_linear, pitch_scale, true)
	loop_player.volume_linear = params[0]
	loop_player.pitch_scale = params[1]
	add_child(loop_player)
	loop_player.play()
	_looping_sfx_players[event_name] = loop_player

## (Low-Level) Stops a named looping SFX, optionally fading it out.[br][br]
## Emits sfx_finished(event_name, -1) when done.
func stop_looped_sfx(event_name: StringName, fade_out_s := 0.0):
	if not _looping_sfx_players.has(event_name): return
	
	var p: AudioStreamPlayer = _looping_sfx_players.get(event_name)
	_looping_sfx_players.erase(event_name)
	
	if not is_instance_valid(p): return
	
	var callback = func(): sfx_finished.emit(event_name, -1)
	
	if fade_out_s > 0.001:
		var t = create_tween().set_parallel()
		t.tween_property(p, "volume_linear", 0.0, fade_out_s)
		t.tween_callback(p.queue_free)
		t.tween_callback(callback)
	else:
		p.queue_free()
		callback.call()

## (Low-Level) Plays a positional one-shot SFX (2D).
func play_sfx_at_position_from_stream(stream: AudioStream, pos: Vector2, volume_linear := 1.0, pitch_scale := 1.0):
	if not enable_spatial_api:
		play_sfx_one_shot(stream, volume_linear, pitch_scale)
		return
		
	var p2d := AudioStreamPlayer2D.new()
	p2d.bus = "SFX"
	p2d.stream = stream
	var params = _clamp_params(volume_linear, pitch_scale, false) # No boost for spatial
	p2d.volume_linear = params[0]
	p2d.pitch_scale = params[1]
	p2d.position = pos
	add_child(p2d)
	p2d.finished.connect(p2d.queue_free)
	p2d.play()
#endregion

#region Public API - Music
## The primary method for playing a music track from a resource.
## [param volume_scale]: A multiplier for the resource's base volume.
func play_music(resource: MusicResource, volume_scale := 1.0, fade_override_s := -1.0, start_position_s := 0.0):
	if not resource or not resource.stream:
		push_warning("[AudioManager] play_music called with an invalid resource.")
		return

	_current_music_resource = resource
	var fade_duration = resource.fade_in_s if fade_override_s < 0.0 else fade_override_s
	var final_volume = resource.volume_linear * volume_scale
	
	_crossfade_to_stream(
		resource.stream,
		resource.loop,
		final_volume,
		fade_duration,
		start_position_s
	)

## Plays a track from a playlist resource, respecting its playback mode.
func play_playlist(playlist: MusicPlaylistResource, volume_scale := 1.0, fade_override_s := -1.0, start_position_s := 0.0):
	if not playlist or playlist.tracks.is_empty():
		push_warning("[AudioManager] play_playlist called with an invalid playlist.")
		return
	
	var next_track := playlist.get_next_track()
	if next_track:
		play_music(next_track, volume_scale, fade_override_s, start_position_s)

## (Low-Level) The core crossfade logic. Called by the high-level functions.
func _crossfade_to_stream(stream: AudioStream, loop: bool, target_vol: float, fade_s: float, start_pos: float):
	_music_target_volume = max(target_vol, 0.0)
	var from := _active_music()
	var to   := _inactive_music()
	
	to.stream = _force_music_loop(stream, loop)
	to.volume_linear = 0.0
	to.play(start_pos)
	
	if _music_fade_tween and _music_fade_tween.is_running():
		_music_fade_tween.kill()
		
	_music_fade_tween = create_tween().set_parallel()
	_music_fade_tween.tween_property(to, "volume_linear", _music_target_volume, fade_s)
	
	if from.is_playing():
		_music_fade_tween.tween_property(from, "volume_linear", 0.0, fade_s)
		_music_fade_tween.tween_callback(from.stop)
		
	_active_is_a = not _active_is_a

## Stops the currently playing music.
## Uses the current track's default fade-out unless overridden.
func stop_music(fade_override_s := -1.0):
	var cur := _active_music()
	if not cur or not cur.is_playing(): return

	var fade_duration = fade_override_s
	if fade_duration < 0.0 and is_instance_valid(_current_music_resource):
		fade_duration = _current_music_resource.fade_out_s
	elif fade_duration < 0.0:
		fade_duration = 1.5 # Fallback if no resource is tracked

	var t := create_tween()
	t.tween_property(cur, "volume_linear", 0.0, fade_duration)
	t.tween_callback(cur.stop)
	t.tween_callback(func(): _current_music_resource = null)

## Resumes current music and fades to the last target volume.
func resume_music(fade_s := 1.5):
	var cur := _active_music()
	if not cur: return
	
	if not cur.is_playing():
		cur.play()
		
	create_tween().tween_property(cur, "volume_linear", _music_target_volume, fade_s)

## Temporarily ducks music to a lower linear volume.
func fade_music(to_linear := 0.2, fade_s := 0.5):
	var cur := _active_music()
	if not cur: return
	
	if _music_fade_tween and _music_fade_tween.is_running():
		_music_fade_tween.kill()
		
	var duck_tween := create_tween()
	duck_tween.tween_property(cur, "volume_linear", clamp(to_linear, 0.0, _music_target_volume), fade_s)

## Restores music volume to the target level after a temporary fade.
func unfade_music(fade_s := 0.5):
	var cur := _active_music()
	if not cur: return
	
	if _music_fade_tween and _music_fade_tween.is_running():
		_music_fade_tween.kill()
		
	var duck_tween := create_tween()
	duck_tween.tween_property(cur, "volume_linear", _music_target_volume, fade_s)
#endregion

#region Global pause/mute & volume
func pause_all_audio(paused: bool):
	for p in _looping_sfx_players.values():
		if is_instance_valid(p): p.stream_paused = paused
	if is_instance_valid(_poly_player): _poly_player.stream_paused = paused
	if is_instance_valid(_music_a): _music_a.stream_paused = paused
	if is_instance_valid(_music_b): _music_b.stream_paused = paused

func set_master_volume_linear(v: float):
	AudioServer.set_bus_volume_linear(_bus_master, clamp(v, 0.0, 1.0))

func set_music_volume_linear(v: float):
	_music_target_volume = max(v, 0.0)
	AudioServer.set_bus_volume_db(_bus_music, linear_to_db(_music_target_volume))

func set_sfx_volume_linear(v: float):
	AudioServer.set_bus_volume_db(_bus_sfx, linear_to_db(max(v, 0.0)))

func set_master_volume_db(db: float):
	AudioServer.set_bus_volume_db(_bus_master, db)

func set_music_volume_db(db: float):
	AudioServer.set_bus_volume_db(_bus_music, db)
	_music_target_volume = db_to_linear(db)

func set_sfx_volume_db(db: float):
	AudioServer.set_bus_volume_db(_bus_sfx, db)
#endregion

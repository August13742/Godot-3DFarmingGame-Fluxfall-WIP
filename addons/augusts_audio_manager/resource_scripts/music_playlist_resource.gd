extends Resource
class_name MusicPlaylistResource
## A collection of MusicResources that can be played sequentially or shuffled.


enum PlaybackMode { SEQUENTIAL, SHUFFLE }

## The list of music tracks included in this playlist.
@export var tracks: Array[MusicResource]

## How to select the next track from the list.
@export var playback_mode := PlaybackMode.SHUFFLE

var _last_track_index := -1


## Gets the next track to play based on the playback mode.
func get_next_track() -> MusicResource:
	if tracks.is_empty():
		return null

	if playback_mode == PlaybackMode.SEQUENTIAL:
		_last_track_index = (_last_track_index + 1) % tracks.size()
		return tracks[_last_track_index]
	
	# Shuffle mode
	var next_index := randi() % tracks.size()
	# Avoid playing the same track twice in a row if possible
	if tracks.size() > 1 and next_index == _last_track_index:
		next_index = (next_index + 1) % tracks.size()
	
	_last_track_index = next_index
	return tracks[next_index]

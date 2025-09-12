extends Resource
class_name MusicResource
## A self-contained definition for a music track.


## The audio stream for the music track.
@export var stream: AudioStream

## Whether the music should loop by default.
@export var loop: bool = true

## The default target linear volume for this track (supports >1.0).
@export_range(0.0,2.0,0.01) var volume_linear: float = 1.0

## The default fade-in duration in seconds when this track starts.
@export var fade_in_s: float = 2.0

## The default fade-out duration in seconds when this track stops.
@export var fade_out_s: float = 2.0

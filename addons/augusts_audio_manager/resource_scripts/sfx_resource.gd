extends Resource
class_name SFXResource
## A self-contained definition for a sound effect event.
## Bundles the audio stream with all its playback parameters.


## A unique name for this event, primarily used to identify and stop looping sounds.
## For tracked one-shots, this name is passed through the sfx_finished signal.
@export var event_name: StringName = &"__anonymous__"

## The audio data to be played.
@export var stream: AudioStream

## If true, the sound will play as a managed loop.
@export var loop: bool = false

## If true for a one-shot sound, the sfx_finished signal will be emitted upon its completion.
@export var track_finish: bool = false

## The linear volume multiplier for this sound.
@export_range(0.0,2.0,0.01) var volume_linear: float = 1.0

## The pitch multiplier for this sound.
@export var pitch_scale: float = 1.0

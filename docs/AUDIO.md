# Audio pipeline

The supplied soundtrack is now integrated. See [Final music and letter integration](FINAL_MUSIC_AND_LETTER.md) for all eleven mappings, lossless conversion, local overlay, credits and verification.

Search priority: executable/music, user://music, source res://music, then bundled res://assets/audio/instrumental. Only authorized assets should be bundled; supplied recordings are excluded from Git and PCK. OGG/WAV are loaded through the existing AudioDirector; music/tracks.json overrides loop_start, loop_end and loop_crossfade in seconds.

Scene crossfades use two players over 1.25 seconds. Loop seams reuse those players with a 0.8-second blend before the configured loop_end; leading/trailing silence can be skipped without editing the recordings. Missing tracks fade to silence. Volume zero mutes music; original sound effects remain independent.

Credits/metadata supplied with the local overlay must be completed before redistribution.

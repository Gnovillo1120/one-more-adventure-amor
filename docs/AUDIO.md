# Audio replacement pipeline

No music-generation tool is available in this session. Existing six synthesized draft themes are preserved but muted; they are not described as acoustic/orchestral recordings. Sound effects remain at the configured volume, including original soft notification/applause cues.

Put original or properly licensed recordings in assets/audio/instrumental using exactly these base names with .ogg (preferred) or .wav:

| File | Scene | Arrangement |
| --- | --- | --- |
| uees | MUN | Light acoustic piano, pizzicato strings, flute |
| ikura | Phone/date | Romantic piano and gentle strings |
| halloween | Party | Rhythmic party ambience |
| intimate | Pool relationship scene | Intimate piano and soft strings |
| cookies | Kitchen | Playful pizzicato and woodwinds |
| minecraft | Voxel exploration | Strings, flute, harp |
| boss | Rescue battle | Dramatic orchestral percussion/strings |
| ending | Menu/beach/credits | Expressive piano and soft strings |

scripts/audio_director.gd prefers OGG over WAV, supports imported assets and direct file decoding, and uses two players with a 1.25-second equal-power crossfade. Rapid changes cancel obsolete fades; missing tracks fade to silence. Volume updates during fades. data/audio_tracks.json records expected instrumentation and per-track loop_start seconds; WAV may also specify loop_end seconds. WAV loop samples account for stereo channels/bit depth. OGG loops from its specified offset to EOF: export an exactly trimmed loop body (or intro plus loop with offset). Crossfade does not repair a badly edited loop seam.

Import in Godot and rebuild to ship the supplied music. Audio credits/licensing records must be added with source, creator, permission/license, required attribution and any edits. No external sample or recording rights are implied by this pipeline. Headless QA covers WAV loading, stereo loop math, overlap, volume, missing tracks and rapid changes with isolated silent fixtures. OGG playback and actual replacement musical quality still need audition when recordings are supplied.

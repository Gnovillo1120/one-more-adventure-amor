# Audio replacement pipeline

No convincing acoustic/orchestral recording tool or licensed recordings are available in this session. Existing synthesized drafts are preserved but muted. Original soft sound effects remain at the configured volume.

## Drop in music without rebuilding

Create/use the music folder beside One More Adventure Amor.exe. Copy original or properly licensed OGG (preferred) or WAV files using these exact base names:

| Name | Use / arrangement direction |
| --- | --- |
| uees | MUN: acoustic piano, pizzicato strings, flute |
| ikura | Date: warm piano and gentle strings |
| halloween | Party: rhythmic instrumental ambience |
| intimate | Pool: soft piano/strings |
| cookies | Kitchen: playful woodwinds/pizzicato |
| minecraft | Exploration: strings, flute, harp |
| boss | Rescue: orchestral percussion/strings |
| ending | Menu/beach/credits: expressive piano/strings |

Example: music/ikura.ogg. Open Settings and select “Recargar archivos de música” to reload the current theme. Future scene changes load their matching files automatically. Missing tracks fade to silence. Search priority: executable/music, user://music, then bundled res://assets/audio/instrumental. Source development can use either of the latter folders; bundled changes require re-export.

Optional music/tracks.json overrides loop points in seconds:

```json
{"ikura":{"loop_start":0.0},"ending":{"loop_start":3.0,"loop_end":90.0}}
```

Defaults come from data/audio_tracks.json. OGG loops from loop_start to EOF; loop_end applies to WAV. Trim/edit loop seams before supplying recordings. Two players provide a 1.25-second equal-power crossfade, live volume and cancellation of obsolete fades. A reload reads new files and loop configuration.

Supply music credits with creator, source, license/permission, attribution and edits. No recording rights are implied. Automated QA uses isolated silent WAV fixtures to verify loading, stereo loop math, fades, volume, missing tracks and external reload; actual OGG playback and musical quality need audition once recordings are supplied.

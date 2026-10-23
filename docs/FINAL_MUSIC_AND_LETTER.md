# Final music and personal letter integration

Branch `feature/final-music-and-letter`, based on latest main `80a5dc6`. No merge to main. Existing M2 polish and gameplay are preserved.

## Soundtrack

| Original supplied filename | Runtime filename | Scene |
| --- | --- | --- |
| `PlayGame.ogg` | `play_game.ogg` | Main menu / start screen |
| `Memories Hub.ogg` | `memories_hub.ogg` | Memory Room and scrapbook |
| `Uess.flac` | `uess.wav` | UESS MUN chapter |
| `ikura.ogg` | `ikura.ogg` | Ikura restaurant |
| `Yacht.ogg` | `yacht.ogg` | Salinas Yacht Club |
| `Haloween.ogg` | `halloween.ogg` | Halloween party |
| `intimate.ogg` | `intimate.ogg` | Poolside confession / romantic phone moments |
| `Cookies.ogg` | `cookies.ogg` | Cookie-making |
| `minecraft.ogg` | `minecraft.ogg` | Minecraft exploration |
| `boss.ogg` | `boss.ogg` | The Forgotten One confrontation |
| `ending.ogg` | `ending.ogg` | Sunset beach, personal letter and credits |

Recordings remain ignored under root `music/`; the exact originals are archived in `music/originals/`. OGG runtime copies are byte-identical. `Uess.flac` was decoded by actual FFmpeg 7.1 to 48 kHz stereo 16-bit PCM `uess.wav`; decoded PCM hashes match. `tools/prepare_local_soundtrack.py` reproduces the conversion and local manifest. No resampling or lossy re-encoding was used.

The supplied PlayGame and Memories Hub files contain identical audio. They remain separately mapped as requested; the system has only two music voices, with one remaining active after each transition.

The existing AudioDirector provides 1.25-second equal-power scene crossfades and 0.8-second loop-seam blends. Local `tracks.json` skips near-digital leading/trailing silence without modifying any recordings. Loop joins are softened, not claimed to be musically seamless authored loops. Volume zero mutes; settings changes/reload remain functional. Original sound-effect assets and playback remain unchanged.

Memory Room and scrapbook use memories_hub; closing a paused scrapbook restores the chapter/confrontation track. Romantic phone scenes and pool use intimate. The existing 3D quest state selects minecraft and boss; no Minecraft gameplay was changed.

## Local playback and redistribution

- Ready-to-play local folder: `builds/final-music-letter-local/One More Adventure Amor.exe`. Its recordings are ordinary files at `music/<runtime filename>` beside the EXE, with `music/tracks.json`, `CREDITS.md` and `LOCAL_SOUNDTRACK_MANIFEST.json`.
- Distributable ZIP: `builds/One More Adventure Amor Final Music and Letter.zip`. It contains the EXE/PCK, controls and license notices; its music directory contains credits/manifest only. Sound effects remain packed in the PCK.
- Separate private overlay: `builds/LOCAL ONLY - One More Adventure Amor Soundtrack Overlay.zip`. Extract beside the public EXE to add `music/`. Do not publish the overlay without redistribution rights.

No creator/title/license tags were present, and no redistribution authorization was supplied. Credits state that recordings were selected and supplied by Guillermo and that authorship/permission are unverified. They do not invent musician attribution. Git ignores root recordings and all build outputs; export excludes root music entirely. Local originals and private reference photographs are preserved.

## Verbatim letter

The sunset beach has a parchment card with a fully visible, word-wrapped, scrollable body. Heading and controls are separate from the body. Mouse wheel, arrows, Page Up/Down and Home/End scroll; E or Continue closes the card. There is no timer or forced typewriter delay. Ending music continues through the letter and credits.

The body was extracted directly from the supplied attachment: **1,333 characters**, UTF-8 SHA256 `b77187c3afb2bb006d4ffe1b20f010a7d1e852fd0fdcbe7c715dd4ed313447fc`. It preserves spelling, punctuation, capitalization and mixed languages. Storage is `data/story.json` → `personal_letter.paragraphs`; `data/final_letter_integrity.json` records the source checksum. Native validation hashes the actual rendered RichTextLabel body.

Existing placeholder dialogue checkpoints reopen the real letter. Saves during reading restore it. Credits has “Leer la carta de nuevo”; existing chapter replay also remains. The sunset scene and credits are preserved.

## Validation

All fifteen existing suites pass **4,182 checks**. Native integration passes **184 source / 184 Windows with soundtrack / 155 Windows without recordings**, all with zero failures. Historical placeholder/silent-soundtrack assertions now reflect the supplied final content; ordinary dialogue-fit checks exclude the long letter because it uses its separately verified scrolling view. The full route still traverses seventeen scenes; six obsolete placeholder dialogue advances are replaced by one exact letter card.

Native source and Windows runs use actual Godot key/mouse events for the beach prompt, scrolling, volume slider and credits replay. All eleven supplied recordings decode and produce nonzero samples captured from Godot’s real audio mixer. OGG and WAV loop seams, crossfade overlap/release, same-track restart guards, all scene mappings, saved/legacy letters and music-free operation are checked. [Exact results and package hashes](final-music-letter/BUILD_VERIFICATION.json).

Windows evidence: [letter first page](final-music-letter/windows/06_letter_top.png), [final line](final-music-letter/windows/07_letter_bottom.png), [credits](final-music-letter/windows/08_credits.png), [reading/replay GIF](final-music-letter/letter_and_credits.gif), [soundtrack input trace](final-music-letter/windows/FINAL_INTEGRATION_TRACE.json), [music-free trace](final-music-letter/windows-without-music/FINAL_INTEGRATION_TRACE.json). These are actual exported-game captures.

Known limits: source recordings have no attribution/license metadata; redistribution is not authorized by this work. Loop points are based on detected silence, so musical seam preference still merits personal listening. Native checks ran on the current Windows laptop; other machines have not been tested in this pass. No unrelated gameplay/art/Minecraft overhaul was performed.

Reproduce:

```powershell
python tools/prepare_local_soundtrack.py
& $godot --path . -- --self-test --validate-final-integration --capture-dir=docs/final-music-letter/source
# Exported local EXE: same arguments, absolute capture directory.
# Music-free EXE: add --expect-no-music.
python tools/package_final_music_letter.py
```

Implementation commit `de56354` is pushed. No merge. PR creation awaits browser sign-in after connector 403; [prepared PR text and comparison](PR_FINAL_MUSIC_LETTER.md).

# Windows release

Godot 4.7.2 official Windows x86_64 export templates are prepared locally in `.tools/` by `python tools/prepare_export.py`. The script downloads only ZIP metadata and the two Windows template members when HTTP ranges are supported; otherwise it downloads the complete official archive. ZIP CRC and uncompressed size are checked while extracting. It does not install templates into AppData or modify original references.

Official release source: [Godot 4.7.2 archive](https://godotengine.org/download/archive/4.7.2-stable/). Templates: [official template archive](https://godot-releases.nbg1.your-objectstorage.com/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz), with [official GitHub mirror](https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz). The object-storage certificate was expired during preparation; the verified GitHub mirror supports ranges and is used without disabling TLS checks. No substitute editor executable is presented as a game build.

`export_presets.cfg` exports all runtime resources and explicitly includes `data/*.json`. It excludes original reference photos/screenshots, concept sheets, documentation, tools, QA runner, downloaded templates and earlier builds. Backgrounds/portraits/sprites/music remain included. This keeps private source photographs out of the distributable.

After all generated assets are integrated and import/runtime validation passes:

```powershell
New-Item -ItemType Directory -Path builds/windows -Force
& 'C:\Users\gsnov\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --export-release 'Windows Desktop' 'builds/windows/One More Adventure Amor.exe'
```

Run `builds/windows/One More Adventure Amor.exe`. Keep the matching `.pck` beside it; both files are required because the preset does not embed the PCK. Final build availability, export results and smoke-test limitations belong in DEVELOPMENT_STATUS.md. This document's existence does not mean export has completed.

Preparation verification: official Windows release/debug members extracted with ZIP CRC verification; 72,146,151 bytes transferred using ranges rather than the 1,281,349,702-byte archive. A temporary `builds/qa/Adventure QA.exe` debug export completed successfully and launched headless for ten frames without errors. Its 11,045,308-byte PCK included `data/story.json`; binary path checks found no private-reference directory, QA runner or local template paths. This QA build predates final art integration and is not the gift release. Final release export and visual smoke testing remain required.

Godot is MIT licensed. The preparation script retrieves `.tools/GODOT_LICENSE.txt` and `.tools/GODOT_THIRD_PARTY_NOTICES.txt` from the official release source. Copy both beside the executable for distribution. Retain the [official license text](https://github.com/godotengine/godot/blob/4.7.2-stable/LICENSE.txt) and relevant third-party notices ([Godot distribution guidance](https://docs.godotengine.org/en/stable/about/complying_with_licenses.html)). Original game story and art do not grant rights to copied Minecraft or other commercial assets; none should be packaged.

The personal letter remains a deliberately marked placeholder until Guillermo edits `data/story.json` → `personal_letter`. Validate the ending after personalizing it before gifting the game.

Final release completed 10 October 2026: builds/windows/One More Adventure Amor.exe (109,268,480 bytes) and matching PCK (1,882,000 bytes). Actual release native-render smoke test completed all 19 screens with NATIVE_CAMERA_ROTATION_OK and CAPTURE_GALLERY_OK; no runtime errors. Screenshots are in docs/export_screenshots. Distribution ZIP includes executable, PCK, README, Godot notices and font license. Personal letter and duration/performance limits remain as documented in DEVELOPMENT_STATUS.md.

Current feature release: export_presets.cfg now defaults to builds/chapter-1-2-overhaul/One More Adventure Amor.exe. The original builds/windows release is preserved. Package name: builds/One More Adventure Amor Chapters 1-2.zip. Update includes the accessible-exit/NPC/trivia/restaurant/audio-pipeline overhaul; actual replacement instrumental music is pending.

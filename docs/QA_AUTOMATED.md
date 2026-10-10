# Automated runtime story QA

Run from the project directory with Godot 4.7.2:

```powershell
& 'C:\Users\gsnov\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script scripts/story_test.gd -- --self-test
```

`--self-test` is mandatory: the runner refuses to operate without it. Game save/settings writes are disabled; only an isolated `user://qa_slot_story.json` is written and removed. Existing real save, backup and settings bytes are compared before/after. This dedicated runner invokes the production gameplay systems.

Verified result: **411 assertions, zero failures, 18 scenes, 235 dialogue steps**, Godot 4.7.2 headless. Runtime startup, execution and clean shutdown complete without errors.

Coverage:

- All six sections follow natural scene progression from fresh game to credits and back to menu. Scene indices are not skipped. The runner places Anami at actual interaction targets, calls the runtime interaction method, advances actual dialogue, presses actual minigame button signals and uses scene exits.
- Every authored choice alternative terminates; ordinary route chooses its first option. Distant interaction is rejected; hotspots start dialogue. All four keepsakes enter the rescue.
- Food and baking wrong selections allow retries; actual correct button signals finish three steps. Wrong dance key preserves progress, then the eight-key sequence finishes.
- Voxel fish, cat, villager hint, ordered farm switches, cave sword combat, waterfall portal, safe bridge, boss shadows, four memory pedestals, final sword hits and rescue signal reach the authored reunion. Out-of-order farm input is rejected safely. Combat uses actual attack methods and physics frames, with cooldown reset to accelerate testing.
- Each voxel phase's actual game save payload is serialized through FileAccess, read back and restored into a new live voxel instance. Quest, switches, memories, enemy health and boss health are checked. Memory completion/position restoration and keepsake/chapter payload roundtrip are checked.
- Falling below the world restores the appropriate phase checkpoint; a lethal cave hit restores health and retains quest progression.
- Real save/settings files remain unchanged.

Limits: this headless test does not prove visual composition, keyboard/mouse hardware operation, navigation paths, camera clipping, animation quality, real-time combat feel, soundtrack quality, 20–45 minute duration, or old-laptop performance. Target placement bypasses walking/navigation. Production save atomic rename/backup fallback and the real-save load button are not exercised, to avoid touching a player's save. GUI smoke tests and Windows export tests remain separate requirements.

## Production persistence and input QA

Run the same command with `--script scripts/persistence_test.gd`. Verified: **231 assertions, zero failures**, all 187 authored lines measured; maximum dialogue height 102 pixels fits the current 112-pixel regular dialogue allocation. Choice texts fit their 31-pixel button height.

This additional runner overrides `save_path` and `settings_path` before startup, then enables actual production saving against explicit isolated QA slots. It exercises actual `save_game`, `load_game`, `_save_settings` and `_load_settings`: chapter/scene/unlocks, completed scene and position, keepsakes/play time, partial voxel farm puzzle, living enemy HP and player health/position, previous-checkpoint backup, deliberately corrupted primary recovering from backup, repaired primary, volume/text-speed/graphics ConfigFile roundtrip. Real saves/settings bytes remain unchanged, and only the explicitly named QA files are removed.

Injected keyboard events plus buffered-event flushing verify held-key movement in both 2D and 3D, desk collision and E interaction. Camera pivot yaw synchronization passes; headless mouse capture is unavailable, so actual mouse-controlled rotation remains a GUI check. The production corruption fallback now parses quietly and logs no expected-error noise. Windows atomic rename's normal path is exercised by production saving; forced rename-failure fallback and filesystem failure cases remain untested.


## Current overhaul results
The preceding 411-check baseline describes the original release. Current full story: 503 checks, 18 scenes, 247 dialogue steps; production persistence: 231; focused chapter_overhaul_test.gd: 153; audio_pipeline_test.gd: 10; navigation: 77 targets. All pass. Run each new runner with --headless --path . --script scripts/NAME_test.gd -- --self-test. Chapters 1–2 and other memory scenes now walk collision-valid navigation paths. Native release additionally verifies real mouse/keyboard menu events and camera rotation. See CHAPTER_OVERHAUL.md for coverage and honest remaining human checks.

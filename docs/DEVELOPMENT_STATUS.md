# Development status

## Completed playable release — 10 October 2026

Continued the existing project after the interruption; preserved original references, authored story, working gameplay and earlier assets. Godot 4.7.2, GDScript, GL Compatibility. The complete six-chapter route is implemented: UEES, messages/Ikura, Halloween, cookies, voxel rescue, and sunset beach/letter/credits. Eighteen scenes and 187 authored dialogue entries include convergent choices and forgiving food, dance and baking activities.

Memory chapters remain entirely 2D top-down pixel art. Ten original environment backgrounds, 48 separate transparent 64×64 portraits (eight expressions per person in casual/formal/Halloween outfits), and six four-direction walking sheets are integrated with limited palettes, nearest-neighbor filtering and integer scaling. Guillermo is clean-shaven in final portraits, sprites and the voxel character. Earlier art is preserved as source material, excluded from the release.

The 3D adventure includes reference-led house/farms/trading hall, fish/cat/villager chain, ordered farm switches, waterfall cave, forgiving sword combat, safe End bridge, memory pedestals, boss and rescue. Checkpoints retain puzzle/combat progress. Menus, chapter unlocks, autosave/backup recovery, volume/text speed/fullscreen/3D resolution settings, original synthesized instrumental themes and cues, transitions, keepsakes and ending are integrated.

## Verification

- Full story runner: 411 checks, zero failures; all 18 scenes and 235 dialogue steps through credits/menu, including alternative choices and retry paths. Repeated after the final layout correction.
- Production persistence/input runner: 231 checks, zero failures; isolated actual save/load/backup/settings, keyboard movement/interactions, collision and dialogue fit. Existing player files preserved.
- 3D navigation: 16 interaction destinations reachable with collision clearance; zero failures. This checks geometry, not human camera comfort.
- Source native rendering and actual Windows release: 19 gallery captures each, menu through ending/settings; exported pixel portraits and backgrounds visually inspected. Native mouse rotation verification passes. No runtime errors in the release smoke-test log.
- Windows x86_64 release export succeeds. Executable and matching PCK are in builds/windows; distribution ZIP includes both plus Godot/font notices and play instructions. Original private reference photographs, concepts, tools and QA scripts are excluded.

Evidence: docs/QA_AUTOMATED.md, docs/NAVIGATION_QA.md, docs/export_screenshots, and docs/RELEASE.md.

## Before gifting / limits

The personal letter is deliberately marked as an editable placeholder: replace data/story.json → personal_letter.paragraphs, then rebuild the release. See docs/LETTER.md. The route is complete, but the target 30–45 minute duration and older 8 GB laptop performance have not been measured. Full human playtesting, camera comfort and music quality remain subjective checks; automated progression accelerates combat and places characters at interaction targets. The soundtrack is an original synthesized piano-like draft, not a recorded piano performance. HEIC reference originals remain untouched and unconverted; they are not runtime dependencies.

## Chapters 1–2 overhaul
Implemented on feature/chapter-1-2-overhaul, preserving the completed game. Scene-defined accessible exits fix Ikura's blocker; richer MUN/restaurant/NPC activities, UN trivia, food cards, optional school-drama game and readable chat are integrated. Additive save state preserves legacy v1 checkpoints. Existing music is now muted pending real instrumental replacements; crossfade WAV/OGG architecture is implemented. See CHAPTER_OVERHAUL.md and AUDIO.md for current validation and limits. Updated build: builds/chapter-1-2-overhaul/One More Adventure Amor.exe. Earlier release is preserved.

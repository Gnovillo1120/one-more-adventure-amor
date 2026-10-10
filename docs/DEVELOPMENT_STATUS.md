# Development status — 10 October 2026

The complete six-chapter game and Chapters 1–2 overhaul are preserved on feature/chapter-1-2-overhaul. PR #1 remains open and unmerged; main is unchanged. Godot 4.7.2 / GL Compatibility. Memory chapters retain 2D pixel art, nearest filtering, 48 expression portraits and four-direction sprites; Guillermo remains clean-shaven. Only the adventure chapter uses 3D voxel environments.

## Current polish pass

All 18 memory scenes now register real props/actors for required objectives and visible doors, gates or arches for completed exits. The same ground anchor drives object placement and interaction radius. Gold marks identify current required interactions, cyan marks optional ones; decoration has no prompt. Existing diploma, food, bandana and cookie art is reused. Voxel fish, switches, portal, NPC and memory pedestals have identifiable objects.

Root cause: interaction target coordinates and marker rendering existed independently of actual object visuals; later scenes inherited generic targets without props. Temporary decorative textures also expired before rendering, producing white squares; retaining them fixes this.

MUN gains visible chair/delegate interactions, papers, idle gestures, optional notes and distinct playful trivia responses. Ikura gains customers, passing food, staff conversation and a visible reservation host. Walking restores standing animation. Existing story beats, activities and additive v1 saves are preserved.

Synthetic draft music stays muted. Original cues remain. WAV/OGG instrumental replacements can now be dropped into music beside the executable and reloaded from Settings without rebuilding. No final acoustic/orchestral recordings have been supplied. See AUDIO.md.

## Validation and handoff

Automated suites: story 503, production persistence/input 231, focused overhaul 161, target visibility/alignment 255, navigation 205, audio 12 checks; zero failures. Navigation covers 63 memory targets across 18 scenes plus 16 voxel destinations using production collision/movement. Source and packaged native captures cover 25 screens, mouse/keyboard UI and 3D camera rotation. Screenshots: docs/polish_screenshots and docs/polish_release_screenshots (local ignored artifacts). See POLISH_PASS.md.

Updated executable: builds/chapter-1-2-polish/One More Adventure Amor.exe, with matching PCK, notices and music instructions. ZIP: builds/One More Adventure Amor Chapters 1-2 Polish.zip. Earlier builds remain available. Private references, concepts and test scripts are excluded.

Remaining: personalize the placeholder letter in data/story.json, supply licensed instrumental recordings and audition loops, human-test pacing/camera comfort and older 8 GB laptop performance. Automated runs do not establish the target 30–45 minute duration. HEIC references remain untouched and are not runtime dependencies.

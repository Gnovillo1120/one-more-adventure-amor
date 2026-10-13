# Development status — 13 October 2026

## 2D animation polish — feature branch

Started from clean latest main at `94e0397` (Living 2D Memories merged through PR #4), on `feature/2d-animation-polish`. Confirmed the swimsuit walking atlas mixed directions within its frame cycles and swimming used one directionless action row.

Corrected swimsuit walking; added separate actual four-direction swimming, front-facing idle treading, 0.85-second ladder entry/exit and splash. Central mappings, stationary idle, action priorities, clothing-safe held props, varied existing NPC pose cadence and safe saves during transitions are implemented. A developer-only seven-outfit/four-direction preview scene supports pause/frame stepping and is excluded from exports. Environments, minigame data, story dialogue, voxel scripts and Guillermo's clean-shaven/no-blush art are unchanged.

Ten suites pass: 2,394 checks, including 220 animation checks and the existing 17-scene/219-dialogue-step story plus voxel rescue. Native source/export proof uses real WASD/E input, consecutive viewport crops and row/frame/position records. Movement GIFs, directional strips, treading/ladder strips and viewer captures are under `docs/animation/`. Explicit crop boundaries were corrected after native treading inspection exposed neighboring-row contamination.

Separate Windows build: `builds/2d-animation-polish/One More Adventure Amor.exe`; ZIP: `builds/One More Adventure Amor 2D Animation Polish.zip`. Older builds remain. Packaging verifies required runtime assets and exclusion of private reference photos, concepts and developer viewer. Known limits: front-facing tread, reversed ladder art on exit, existing NPC pose library, static directional intermediate clothing stages and further human/lower-end playtesting. See `ANIMATION_POLISH.md` for implementation, evidence and art provenance. Publication outcome will be recorded after push/PR preparation.

# Development status — 12 October 2026

## Living 2D memories — playable feature branch

Branch `feature/living-2d-memories` starts at latest `origin/main`, `f82f8d0`, after PR #3 merged. The initial working tree was clean. Existing minigames, story text, voxel systems and prior builds are preserved.

Reviewed the supplied references before environment implementation. The named `assets/references/living_2d/` directory is absent in this checkout; the supplied images are instead in the yacht club, bedroom, phone, pixel-art and UEES reference directories. Real pool/marina and atrium photographs guide layout; pixel-art catalogues guide readable silhouettes and context poses. `assets/references/` remains ignored, untracked and excluded from exports. No reference photograph enters generated runtime art.

Implemented transparent context frames, eight ambient archetypes, swimwear/outfit stages, sixteen furniture sprites and two new backgrounds. Handheld phone transitions/history, independent NPC routes, optional club seating/drinks/pool/changing, a 75-second spatial bedroom preparation activity, fountain/footstep staging, 55 party/staff actors, quiet romantic poses and a pause album are integrated. Guillermo's casual, formal, Halloween and seated sprites have neutral cheeks; his clean-shaven likeness and Halloween walking sheet's eye makeup remain.

Validation: nine suites pass, 2,174 checks: living activities 89, minigames 699, full story 470, persistence 206, chapter 170, room/phone 63, targets 245, navigation 220, audio 12. The story traverses all 17 scenes, 219 dialogue steps and the preserved voxel rescue. A late pose regression was fixed by separating seated visual offsets from legal movement ground anchors. Native source/export input verifies P and mouse phone reopening, E outfit collection and pool bounds. Party process-monitor samples measured 3.9 ms in source and 7.36 ms in the export with 55 actors on the RTX 3070 Laptop GPU; these samples are not a benchmark or lower-end performance guarantee.

Windows release: `builds/living-2d-memories/One More Adventure Amor.exe`; ZIP: `builds/One More Adventure Amor Living 2D Memories.zip`. Earlier builds remain untouched. Baseline captures render the preserved pre-overhaul PCK; source/export captures are under `docs/living/`. Reference photos, source concepts, tools, tests and developer screenshots are excluded from the pack.

Limits: lightweight NPC routes and four main party costume families, one swimming stroke set, a fixed dress→bandana→sneakers sequence with a simple wardrobe distractor. Extra dancing uses Anami's new dance frames and Guillermo's existing step frames. The pool wing emphasizes player activity rather than autonomous swimmers. Artist cleanup, human pacing and lower-end playtesting remain useful. The original personal letter/final instrumental recordings still await user content. Implementation committed as `8c32292` and pushed to `origin/feature/living-2d-memories`. Draft PR creation returned GitHub 403, "Resource not accessible by integration". The prepared comparison and PR description are in `PR_LIVING_MEMORIES.md`; no merge was performed.

See `LIVING_MEMORIES.md` for the reference review and implementation contracts.

## Interactive memory minigames — active branch

Working on `feature/interactive-memory-minigames`, branched from Claude's tested `feature/claude-3d-overhaul` at `9d5a754`. Claude's shaders, voxel characters and rebuilt world are preserved. The older entries below are historical checkpoints; PR #1 has since merged.

Implemented mandatory five-exchange MUN debate (7/10), exact three-dish Ikura ordering, the supplied ten-question Guillermo quiz (8/10, fifth choice on Q10, Hard Mode before Q8), and one continuous kitchen with deterministic 0–100% baking. Poor baking awards the keepsake and advances. Removed the old first-date scored quiz from playable interactions. Semantic challenge state and recipe evaluation live outside UI nodes; each successful action is a visual-animation hook.

Chapter checkpoints now retain active challenge phase, selections, scores, previous successes, exploration and dialogue position. Legacy v1 checkpoints remain accepted; the former second cookie scene maps to the consolidated first scene. Private references and existing generated art are preserved; Guillermo stays clean-shaven.

Final validation: all eight suites pass, 2,096 checks total: challenges 699, story 481, persistence/input 206, chapter 170, room/phone 63, visible targets 245, navigation 220, audio 12. The story run traverses all 17 consolidated memory scenes and the complete 3D rescue. Native source and exported OpenGL captures pass real mouse ordering, keyboard submission and camera rotation. The exported Windows executable exits cleanly, with no stderr errors.

Release: `builds/interactive-memory-minigames/One More Adventure Amor.exe`; ZIP: `builds/One More Adventure Amor Interactive Memory Minigames.zip` (40,010,585 bytes). Earlier builds remain intact. Runtime question/recipe banks are included, private references are excluded, ZIP CRCs verified. Source/exported screenshots live in `docs/minigames/`. Claude's PR #2 is now merged. See `MINIGAMES.md` for contracts, files, sources and limitations.

Commits `e73a3c0` and `756a9d0` are pushed to the requested branch. PR creation returned GitHub 403 “Resource not accessible by integration”; the browser fallback failed to start twice. No PR was created or merged. Complete PR text is prepared in `docs/PR_MEMORY_MINIGAMES.md`; [open the prepared comparison](https://github.com/Gnovillo1120/one-more-adventure-amor/compare/main...feature/interactive-memory-minigames?expand=1).

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

## Active complete-redesign request
Phase A is implemented as an architectural checkpoint: layered MUN/dining/Ikura rooms, depth-sorted actors and foreground tables, integrated seating animation, accessible delegations, clipped container chat and an editable Guillermo quiz. Full production art, Phase B staging, Minecraft reconstruction and animated kidnapping/rescue remain unfinished. See REDESIGN_STATUS.md for exact continuation. Do not treat the earlier playable release as meeting the new cinematic acceptance bar.
Phase A release validation: all seven suites pass (503/231/177/255/220/12/63 checks), 29 native source/exported captures, UI and camera smoke checks. Intermediate build: builds/redesign-phase-a/One More Adventure Amor.exe; ZIP: builds/One More Adventure Amor Redesign Phase A.zip. It does not include the requested 3D reconstruction or cinematics.

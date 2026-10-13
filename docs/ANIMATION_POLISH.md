# 2D character animation polish — 13 October 2026

Branch `feature/2d-animation-polish` starts from clean latest main at `94e0397`, the merged Living 2D Memories PR #4. This is a focused animation correction. No environment, story data, minigame bank, voxel script or Guillermo artwork is changed.

## Diagnosis and correction

The old swimwear row zero contained front, left, right and back views. Rows one/two also mixed directions and row three repeated a back frame. Cycling columns therefore rotated the character. The old swim action selected row three of `anami_actions.png` independently of movement direction.

Replaced the defective swimsuit walking atlas with coherent down/left/right/up rows. Added a separate swimming atlas with four genuinely different directional stroke cycles, an upright front-facing treading cycle and a ladder cycle. Land frames are 32×48; wider swimming frames are 48×48. Every sheet has four columns. `atlas.json` records both layouts. Source atlases are retained under `assets/art/concepts/`; the runtime sheets live under `assets/art/living/`. Explicit crop boundaries avoid neighboring-row contamination, found and corrected during native inspection. Normalization registers baseline/scale across directions, applies binary alpha, 24 colors per frame and nearest-neighbor resizing.

`character_animation.gd` centralizes direction/state/frame mappings. `memory_actor.gd` supports explicit action cell dimensions and water anchoring. `living_memories.gd` selects swimming states from movement, with slow treading when stopped. Movement cadence restarts on a direction/action change; blocked movement holds idle rather than cycling walking frames. Seated art holds one authored view rather than cycling through different viewpoints. Partial outfit stage columns are treated as directional views, not walking frames.

## State and interaction rules

| State | Artwork / behavior |
| --- | --- |
| `swim_down`, `swim_left`, `swim_right`, `swim_up` | Separate atlas rows 0–3; four stroke frames |
| `swim_idle` | Row 4; gentle front-facing treading at 2 frames/second |
| `enter_pool` | Row 5; 0.85-second climbing transition, then splash and swim control |
| `exit_pool` | Row 5 in reverse; 0.85-second transition, then standing swimsuit |

Priority is ladder/busy interaction → swimming → phone → story dancing → timed pose → sitting/carried drink → ordinary movement. Ladder and phone use prevent walking. Movement interrupts optional sipping/sitting/dancing; carried drink state remains. Short changing/surprise poses finish before movement resumes. Phone/drink artwork that belongs to casual clothing is replaced by held-object overlays on other outfits, avoiding a sudden costume swap. Fountain drinking retains its formal authored sheet. Existing Halloween dance/romance art is retained.

Pool movement boundaries and ladder interaction radius remain unchanged. Entry/exit saves record the semantic destination immediately; reload discards the transient animation lock and resolves the saved position onto a legal water/land position. Pause freezes the transition; completion restores control after resume. No save format migration is needed. Walking in the pool wing clears any prior bench pose.

Ambient counts are unchanged. Individual cadence offsets and rates vary; dancers use their supported poses, chatters gesture briefly then hold idle, and stationary staff do not endlessly cycle walking frames. This uses existing lightweight routes and art.

## Developer viewer and visual evidence

Run `scenes/dev/animation_preview.tscn` in Godot, or:

```powershell
& 'C:/Users/gsnov/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe' --path . scenes/dev/animation_preview.tscn
```

The viewer offers all seven requested outfits, simultaneous four-direction cards, available authored actions, row/frame/cell readouts, pause and frame stepping. Nondirectional actions repeat their actual authored pose and are identified as such. The tool is excluded from player exports and has no player-menu entry.

`--capture-animation` runs the real game, injects WASD and E input, and captures viewport crops while positions and animation frames change. It does not render source PNGs as proof. Each movement strip contains eight consecutive samples per direction: down, left, right, up from top to bottom. `frames.json` records selected rows/frames/positions. Ladder strips show exit then entry, including final states. Treading has its own strip. The GIF only assembles those captured viewport crops; it does not invent frames. Native source and exported Windows captures are in `animation/source/` and `animation/release/`. These are automated native input checks and visual inspection, not an uninterrupted human playthrough.

- [Exported movement review GIF](animation/release/four_directions.gif)
- [Swimsuit walking strip](animation/release/walk_directions.png)
- [Four-direction swimming strip](animation/release/swim_directions.png)
- [Treading strip](animation/release/treading.png)
- [Ladder transition strip](animation/release/ladder.png)
- [Developer viewer captures](animation/preview/)

## Validation and release

Ten suites pass, 2,394 checks total: animation polish 220, living activities 89, minigames 699, full story 470, persistence 206, chapter 170, room/phone 63, targets 245, navigation 220, audio 12. The existing 17-scene / 219-dialogue-step story and voxel rescue still pass. Animation tests cover mapping, bounds, distinct direction art, stationary idle, priorities, ladder/pause/splash, outfit restoration and saves during both transitions. Native movement samples confirm correct rows, changing frames and actual movement in every direction.

Windows release: `builds/2d-animation-polish/One More Adventure Amor.exe`; ZIP: `builds/One More Adventure Amor 2D Animation Polish.zip`. Older builds are preserved. Packaging verifies ZIP integrity, required assets/minigame banks and exclusion of private references, source concepts and the developer viewer.

## Known limits

Treading is a shared front-facing cycle. Exit reverses the climbing frames. NPC variety uses the existing pose library rather than new full directional NPC sheets; no new NPCs are added. Intermediate dressing stages have directional static poses until the final outfit uses its full walking sheet. Existing portraits/Guillermo sprites are preserved, including clean-shaven neutral cheeks. Native checks were performed on the RTX 3070 Laptop GPU; lower-end performance and further human pacing/playtesting remain. Original personal-letter/music content requirements are unchanged.

## Art provenance and prompts

Built-in imagegen generated the two replacement atlases using the existing generated Anami outfit sheet as the identity reference. No personal reference photo was copied or committed. `tools/prepare_animation_assets.py` deterministically converts the retained generated sources into the runtime atlases. The historical living-asset pipeline reapplies this correction when rerun.

Walking prompt: Create a corrected game sprite atlas based on Anami in the first three rows of the reference for identity only. Brown long hair, glasses, turquoise one-piece swimsuit, barefoot; crisp limited-palette RPG pixel art. Four columns/four rows on transparent background. Rows: down/front, left, right, up/back. Each row contains idle, step A, passing, step B, all facing that row's direction; never mix directions within a row. Consistent proportions, body size and baseline; no gradients, smooth illustration, text, grid lines, backgrounds or shadows. Generous transparent gutters.

Swimming prompt: Production pixel-art atlas using the same identity reference, four columns/six rows. Rows: four down/front strokes, four left strokes with head left/feet right, four right strokes with head right/feet left, four up/back strokes, four gentle upright front-facing upper-body treading frames, four right-facing ladder-climbing frames. Every row stays in one direction; never cycle viewpoints. Brown long hair/glasses/turquoise swimsuit, consistent pixel scale/proportions, crisp limited palette, transparent gutters; no painted water, ladder props, grid, text or smooth cartoon rendering.

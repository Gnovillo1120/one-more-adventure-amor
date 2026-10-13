# Director's Cut — Memory Book milestone

13 October 2026. Branch `feature/directors-cut`, based on main `217b3b4` (merged animation-polish PR #5). Safe pre-amendment checkpoint: `bf27a37`. This is milestone 1, not the completed Director's Cut.

## Playable changes

New Game opens in **La última página**, a short, skippable introduction in a fictional Memory Room. Anami approaches the reading desk. The title uses this room instead of the former beach background. WASD explores the room, E opens the desk book or inspects a display, and a visible Continue button keeps the main route easy to follow. Reading desk collision and display approach points are separate from their art. Chapter boundaries now return here; a photograph zoom leads into the selected memory. Saved chapter recovery gradually warms the book, and a faint purple crack disappears after the rescue chapter. This is gentle visual foreshadowing, not a new mandatory puzzle.

Six chapter pages are separate from **exactly five personal keepsakes**:

| Object | Meaning and presentation |
| --- | --- |
| Yoda LEGO keychain | Anami's childhood box held R2-D2, Darth Vader and Yoda for a future loved person. The optional box opens, shows all three, then highlights the Yoda she gave Guillermo. |
| Gold A necklace | Guillermo's first gift to Anami, for her birthday. No birthday date or additional circumstances were invented. Gentle color glint; stable under Reduced Motion. |
| Guillermo's photograph | A single-person pixel illustration represents the photograph that prompted Anami's first message. It is labeled an interpretation, not the original or a generic couple photograph. |
| MUN diploma | Represents where they first met, their debate and first encounter, rather than just an award. |
| Oatmeal recipe | Preserves their time baking together. The page records the first and latest completed scores **in this playthrough**, including an imperfect first batch. The actual recipe, evaluation and completion rules are unchanged. |

All five pages are available for optional inspection. Seeing/opening them persists but never gates progression. Gifts are not assigned to fabricated chapter dates. The paper spread uses the game's familiar navy buttons with dark ink and high-contrast cream paper. Small item illustrations render at integer sizes with transparent backgrounds and nearest filtering.

The red bandana remains in the Halloween outfit, getting-ready sequence and associated sprite assets. Its symbolic chapter token, completion narration, HUD representation and voxel memory callback were corrected. Old saves containing `Bandana roja` migrate that internal token to `El comienzo de nosotros` while preserving the Halloween scene and activity state. The existing four voxel activations remain four; their illustrations/callbacks now reference the diploma, photograph, Yoda and cookies, with the A necklace mentioned alongside the everyday memories. No new fetch quest was added. These lines remain dramatized game dialogue, not historical quotations.

## Creative additions

Completed chapter replay makes a round trip: it stores the main journey checkpoint, resets only the replayed chapter's local scenes, and returns to the room at its natural exit. A visible return button aborts the replay. Saving during replay retains that return checkpoint. New baking results remain in the book while the original main-route challenge state is restored.

Imperfect pages preserve the first completed batch rather than overwriting it with a later perfect score. The score is explicitly a game-session result, never an assertion about a real baking occasion.

After the first chapter, the book can briefly show `Guill…`. An optional **Recordar su nombre** action restores the name and persists. The page explicitly frames this as a book interaction; no collectible or name repair is required for the ending.

## Files and persistence

`scripts/directors_cut.gd` manages the hub, cinematic skip, optional inspections, session notes and replay bookmark. `scripts/memory_room.gd` renders/collides/moves. `data/directors_cut.json` holds chapter metadata and the five Spanish keepsake entries. Existing `scripts/game.gd` remains the route/save/UI orchestrator. Saves retain version 1 and gain an optional `directors_cut` dictionary; old memory/voxel saves enter their original scene. An interrupted `opening` save recovers in the playable hub. Existing production atomic writes and backup recovery remain. The previous gameplay-photo album remains separately available under Pause → Fotos de la partida.

Reduced Motion is saved in settings, removes the opening walk/photograph zoom and ambient dust, and stabilizes necklace glint. Existing minigame scoring, outfit/swimming transitions, corrected walking atlases, original portraits and Guillermo's clean-shaven/no-blush art are preserved.

## Art provenance

Built-in imagegen created the room and neutral book/recipe atlas. Runtime files are `assets/art/directors/memory_room.png`, `book_open.png`, `book_closed.png`, `recipe_card.png`, and `locked_photo.png`. Normalization uses nearest sampling and limited palettes, keeping the generated alpha. Source concepts remain in the local Codex generated-image directory, outside the repository.

Prompt set for these assets: a warm evening top-down pixel-art reading room matching the existing bedroom's nostalgic identity, clear walkable wooden floor, six empty back-wall display tables, central reading desk, plants/shelves/lamps and a subtle purple crack; no people or lettering. The object atlas requested isolated transparent pixel-art scrapbook objects in a 4×2 grid: closed/open books, receipt, pool photograph, cookie recipe, miniature house, empty cracked photo frame and restored book. Only the neutral books, recipe and empty frame were retained. Bandana-themed variants were excluded after the amendment.

Three attempts at the corrected item atlas returned imagegen safety-system rejections with category `other`, without a specific explanation. No rejected output was used and no API fallback was invoked. The six small transparent **native SVG pixel-vector** assets were then authored as integer-grid shapes in `tools/author_keepsake_vectors.py`: closed/open box, Yoda keychain, A necklace, single-man photo interpretation and diploma. They are actual runtime art, not descriptions or signs. The photo interpretation uses the existing brown-haired, clean-shaven character design, without reference photograph pixels. Box toy sprites use integer coordinates, without fractional raster scaling. Original game character assets were not replaced.

`tools/normalize_directors_art.py` crops/normalizes accepted generated assets. Private `assets/references/` remains ignored, untracked and excluded from exports. No personal reference photograph enters this change or release. Future dog/leash, Monopoly and tomato memories remain out of scope.

## Verification and evidence

Eleven suites pass: **2,465 checks**, including Director's Cut 69, story 470, persistence 206, minigames 699, living activities 89, animation 222, chapter overhaul 170, redesign 63, visible targets 245, navigation 220 and audio 12. The story traverses all 17 scenes, 219 dialogue steps and the existing voxel rescue with optional keepsakes untouched. New checks cover real save/load, legacy bandana-token migration, interrupted-opening recovery, collision/approach points, skip idempotence, replay return/abort, baking first/latest notes, exact five-object identities and photograph/button layout bounds.

Native viewport evidence is under `docs/directors/`: `before/` renders the preserved animation-polish PCK, `source/` renders the current source, and `export/` renders the matching Windows build. Input proof reports actual WASD movement and E book opening. PNGs show the hub, five keepsake pages, box states, name restoration and photograph transition. GIFs are assembled only from captured Godot viewport frames by `tools/directors_evidence.py`; concept images are never substituted for gameplay evidence.

Native renderer: Godot 4.7.2, OpenGL 3.3 Compatibility, NVIDIA driver 555.97, RTX 3070 Laptop GPU, Windows, 1280×720 logical viewport. No benchmark or older-laptop FPS claim is made.

Separate executable: `builds/directors-cut-milestone-1/One More Adventure Amor.exe`; ZIP: `builds/One More Adventure Amor Directors Cut Milestone 1.zip`. Earlier builds remain untouched. Packaging checks required runtime assets, reference/concept/developer exclusions and ZIP integrity. The build README explicitly identifies the personal letter as a placeholder and final music as pending.

## Precise remaining work

Milestone 2: stage the MUN award/missed goodbye; polish phone ghosting and food delivery; party/confession/date (21 October 2023); improve visible cookie actions. Retain all real orders, supplied quiz answers, recipe, swimming and outfits.

Milestone 3: peaceful shared-world opening, actual on-screen kidnapping (currently narration), more varied rescue staging, confrontation and rescue animation. Existing four memory activations are retained here; integrate the five personal objects as visual/emotional callbacks without five mandatory collection quests.

Milestone 4: beach approach, personal-letter presentation, real supplied letter content, final licensed instrumental recordings, accessibility/pacing and older-laptop QA. Never invent the personal letter or imply this development build is gift-ready. The current broad storyline is playable, but these Director's Cut milestones remain unfinished.

Current limitations: lightweight item sprites, box opening uses authored discrete states, necklace glint is a color reflection rather than a new multi-frame atlas, replay supports whole chapters (no separate direct minigame replay shortcut yet), and the photograph is an interpretation. Human pacing and low-end performance still need evaluation.

Delivery checkpoint: implementation `fff408b` is pushed to `origin/feature/directors-cut`; main remains unchanged. ZIP verified at 42,867,587 bytes, SHA-256 `f983191d719cd952f4ca5f2195431839debd091c817c4d363bc14b745c292037`. The matching export exits cleanly after native capture; movement and E book opening pass, with no stderr errors. GitHub draft PR creation returned 403, "Resource not accessible by integration". No PR was created or merged; `PR_DIRECTORS_CUT.md` contains the prepared description and comparison link.


## Milestone 1 playtest correction pass — 13 October 2026

See [PLAYTEST_FIXES.md](PLAYTEST_FIXES.md) for exact causes, implementation, native before/after evidence and limits. The explicit keepsake HUD loop was removed; the lobby bench and generic posts are gone; nearest contextual prompts replace marker clutter. Optional photography uses actual outfit-matched phone poses, subject focus, shutter sound and a persisted single unlock linked separately from the Instagram keepsake. Its album thumbnail is bounded. The beach letter has its own ground anchor and unobstructive bottom HUD prompt.

Q4 accepts five cities and Q8 Xbox 360, both answer C. Source bank/helper/test keys and cached ongoing sessions are corrected; ten questions, Hard Mode and 8/10 remain. Twelve suites pass 2,563 checks, including 98 focused regressions. Native source/export proof covers all five photo poses and unlock timing, quiz Q4/Q8, room exit/lobby, album and final beach/card at both window sizes. Corrected Windows build/ZIP are under `builds/directors-cut-playtest-fixes/` and `builds/One More Adventure Amor Directors Cut Playtest Fixes.zip`. Previous milestone builds, characters, minigames, swimming/outfit systems and personal-letter placeholder are preserved. Milestones 2–4 remain pending; no merge to main.

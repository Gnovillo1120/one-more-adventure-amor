# Director’s Cut — M2 animation and visual polish

Branch `feature/directors-cut-m2-polish`, created from clean, updated `main` at `fe935b3`. No merge to main. This continues the working Director’s Cut rather than restarting it. Private references and previous builds are preserved.

## Changes by memory

**Cookies:** the existing preparation quiz, physical recipe, scoring, kitchen E router and forgiving completion remain. Countertop choreography now gives nine ingredient types separate open-container sprites, colors and particle shapes: powder, grains, oat flakes, butter pieces and vanilla stream. The measuring cup fills, then moves/tips toward the appropriate bowl. Container openings and the fork tines use pivots checked against the actual sprites. Bowl accumulation is weighted by recipe quantity, with continuous fill growth rather than a full-bowl pop. Dry and wet mixtures have separate compositions; reserved dry/oat portions visibly enter the mixing bowl. Whisk movement follows mouse circles or the keyboard alternative, with bounded rotation and textured contents. Egg pickup/rim taps precede the split shell, white and yolk; incorrect taps retain the shell penalty. Actual egg halves are cropped from the existing egg sprite.

Scoop travel connects the dough bowl to the selected tray position. Six representative cookies remain player-placeable, with a spacing warning. The fork travels through water/sugar, contacts the selected portion, deforms it and leaves tine marks. The tray travels into/out of the oven while the door opens/closes; cookies gradually expand and darken. Mitts, the 8–10-minute window, rack swapping, pause-safe timing and cooling remain. Cookies transfer individually to the rack. Both existing hero sprites taste a bite-sized cookie; four quality tiers have different cookies and reactions. Poor batches still unlock the memory and record first/latest scores.

Short physical transfers finish before the next input is accepted. The semantic action commits immediately, so saving/loading during a transfer preserves progress and discards only the temporary animation lock. The current action’s instructions remain visible until its animation ends. Gathering has opening storage, reaching and storage-to-counter item motion. Guillermo’s quiz walking direction uses the actual derivative of his route rather than flipping incorrectly during the return half.

**UESS dining:** reconstructed the architectural shell from locally inspected photographs: large pale stone slabs, broad light windows, marble-like columns, ceiling lighting, round linen tables with navy skirts and white chairs. An old table was moved out of the serving route, including its collision footprint. Independent serving counters have reachable ground anchors and collision. The player collects a plate, rice, menestra and meat in order. Three distinct serving staff use coordinated aprons and ladle motion. Students wait nearby. Anami and Guillermo carry progressively filled plates; the hero rig holds the upper body/arms steady while the walking legs retain their directional cycles. Guillermo independently walks the same four-station route, receiving each component separately; his partial progress survives saves. The chair becomes available when both meals are ready. Plates appear on the table as each person sits; her existing seating route and relationship conversation follow.

**UESS ceremony:** the chair is a real prerequisite. Anami turns toward the announcement and sits; eighteen additional seated students applaud with staggered gestures. The presidency stands beside the handoff, Guillermo walks forward, the diploma moves between them and remains in his hand. The player regains control to approach him. E/Space skips safely, pause freezes choreography, interrupted saves reopen a usable chair and legacy completed ceremonies are not repeated. The original authored award conversation is retained.

**Fountain:** the 128×48 sheet’s four columns are different viewing directions. Cycling them as a temporal animation caused the spin. Drinking now holds the authored left-facing column 1, row 0, with a small lean, preserving formal clothing and restoring movement afterward. Native tests sample twenty frames across four approaches.

**Supporting cast / Moncayo:** eight genuinely different young student designs replace UESS filler art. Hair silhouettes, skin tones and clothing vary; the crowd reuses these designs rather than claiming eighteen unique characters. Lower-leg, seated, applause and subtle gesture rigs animate them. Moncayo has one consistent curly-haired, glasses/navy-sweater design based on locally observed features, a registered four-direction walking sheet and matching default portrait. His dialogue appearance uses the standing pose. Presidency, Chad delegate, host, catering/event staff and waiter have mapped default portraits; unnamed speakers use a neutral silhouette. Existing Guillermo/Anami likenesses, clean-shaven/no-blush appearance and outfits remain.

**Ikura:** twelve believable choices over two keyboard-accessible menu pages, with food sections, descriptions and illustrations. Six new original icons distinguish the added rolls, shoyu ramen, katsu, green tea and lemonade. “Carta inspirada” identifies the menu as an interpretation; no historical prices are claimed. The correct order remains shared gyozas, Guillermo’s miso ramen and Anami’s sushi. Wrong orders can retry. Arrow paging is handled before GUI focus consumes it. Served ramen has restrained pixel steam; the waiter and seated eating gestures use the actual scene actors/food.

Other chapters, five keepsakes, chapter replay, debate, ten-question quiz (five cities, Xbox 360, 8/10 threshold), Halloween preparation, swimming, photography, 3D finale and final letter placeholder remain. Their regression suites still run.

## Assets

Runtime additions under `assets/art/polish/`:

| Assets | Use |
| --- | --- |
| `cast_0.png`–`cast_7.png` | Eight distinct students, 32×48 |
| `cast_8.png`, `moncayo_walk.png` | Matched Moncayo standing / four-direction poses |
| `cast_9.png`–`cast_11.png` | Presidency, catering server, waiter |
| `portrait_0.png`–`portrait_11.png` | Matching default head/shoulder crops |
| `ingredient_*.png` | Nine distinct open containers, 64×80, with mouth pivots |
| `menu_*.png` | Six new original food/drink icons, 32×32 |
| `meal.svg`, `neutral.svg` | Editable meal plate and neutral portrait |

Existing hero sprites, expression portraits and kitchen raster props are preserved. New runtime art includes twelve supporting cast sprites, twelve matched default portrait crops, the 16-frame Moncayo walk sheet, six menu icons, nine 64×80 ingredient containers, meal.svg and neutral.svg. Pixel geometry/particles/choreography extend the existing code-native art system. Original generated source sheets are retained under `assets/art/concepts/polish_*_source.png`; runtime normalization is reproducible through `tools/normalize_polish_cast.py`. [Reference handling and generation provenance](m2-polish/ART_PROVENANCE.md) explains what was inspected and generated. No private photograph was uploaded to generation or committed/exported.

## Verification and evidence

All fifteen headless suites cover the existing full route, save/load, replay/book, 3D navigation, quizzes and baking, plus new cast/portrait integrity, four outcome tiers, legacy ceremony/lunch recovery and saving during a cup transfer. [Build verification](m2-polish/BUILD_VERIFICATION.json) records exact results, native input counts, scores and hashes.

The native runners use `Input.parse_input_event`/`flush_buffered_events`, actual WASD movement, contextual E targets, mouse hit testing and keyboard controls. They do not call station/key/interaction methods to prove input. Headless movement placement is explicitly limited to routing checks; physical polling is validated in the native source and exported Windows game. Fine steering briefly slows the **test driver’s** time scale near navigation waypoints to avoid automation overshoot at corners; ordinary gameplay is unchanged. The oven’s timed portion runs at normal time scale. Both an excellent batch and a deliberately imperfect batch must finish in the Windows executable before packaging.

All linked GIFs are assembled from actual Windows viewport PNGs, without invented frames:

* [Physical E ingredient collection](m2-polish/ingredient_collection.gif), with before/pressed/after frames; inventory counts are recorded in the input trace.
* [Quiz helper walking](m2-polish/quiz_helper.gif).
* [Flour and cup transfer](m2-polish/flour_transfer.gif), [egg cracking](m2-polish/egg_cracking.gif), [mixing](m2-polish/mixing.gif).
* [Scooping, dipping and pressing](m2-polish/scoop_and_press.gif), [oven and rack](m2-polish/oven_and_cooling.gif), [tasting](m2-polish/tasting.gif).
* [Catered meal and seating](m2-polish/catered_memory.gif), [four-direction plate carrying](m2-polish/plate_carrying.gif), [Guillermo receiving food](m2-polish/guillermo_catering.gif), [ceremony](m2-polish/ceremony.gif), [stable fountain](m2-polish/fountain.gif), [menu pages](m2-polish/ikura_menu.gif).

Viewport frames and JSON input traces are under `m2-polish/source/`, `uess-source/`, `export/`, `export-imperfect/` and `uess-export/`. Full-screen milestones and assembled GIFs are committed; raw `motion_*.png` samples remain local and can be regenerated with the capture flags. Asset review sheets are explicitly labeled separately. Packaging verifies the current PCK predates Windows evidence, ZIP integrity, required runtime assets, private/reference/concept exclusion and that the prior input-fix ZIP is unchanged.

Example reproduction:

```powershell
& $godot --headless --path . --script scripts/m2_polish_test.gd -- --self-test
& $godot --path . -- --self-test --validate-baking-input --capture-dir=docs/m2-polish/source
& $godot --path . -- --self-test --validate-polish-input --capture-dir=docs/m2-polish/uess-source
# Run the exported EXE with the same user arguments; add --baking-imperfect for the poor batch.
python tools/package_m2_polish.py
```

## Build and limits

Windows executable: `builds/directors-cut-m2-polish/One More Adventure Amor.exe`, alongside its matching PCK. ZIP: `builds/One More Adventure Amor Directors Cut M2 Polish.zip`. Previous builds remain intact. [Compare branch to main](https://github.com/Gnovillo1120/one-more-adventure-amor/compare/main...feature/directors-cut-m2-polish).

This is a personal-playtest development build. Native automation and frame review do not substitute for an uninterrupted human pacing review or ordinary-laptop performance testing; the native device is an RTX 3070 Laptop GPU. Supporting portraits are small sprite-derived default portraits; background students use lightweight code rigs rather than complete bespoke directional/action atlases. Cooking combines existing raster tools with code-native pixel motion/contents rather than a fully hand-drawn atlas for every hand pose. The dining architecture is a playable interpretation of the photographs, not a literal photographic reconstruction. Final licensed music and the actual personal letter remain pending; this is not the final gift release.

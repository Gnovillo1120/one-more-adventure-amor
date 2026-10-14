# Director’s Cut Milestone 2 — 14 October 2026

Branch: `feature/directors-cut-milestone-2`, based on latest stable main `b472b49`. Implementation commit: `f6d06dc` (physical baking, original art, 2D staging and QA). Release evidence/docs are recorded in the following documentation commit. No merge into main. M1 scenes, room/book, exactly five objects, current saves, clean-shaven/no-blush Guillermo and existing 3D finale are preserved.

## Playable cookie memory

The short three-question warm-up leads into a walkable domestic kitchen. Guillermo walks between ingredients during the quiz. Fridge, pantry, sink, counter, oven and cooling rack have contextual E interactions and restrained focus outlines. The island and cabinetry have collision footprints and reachable approaches; the oven, dough, countertop crumbs and cooling batch change with the session.

Walk to the pantry for dry ingredients, fridge for eggs/butter, and sink for water/tools. At the counter, hold Space or the pour button to fill the cup, then Enter adds the actual amount. R empties a mistaken pour. Nine ingredients are measured, including the quantities absent from the old five-question measurement quiz. All targets come from the supplied recipe: flour 2 cups, cinnamon 1½ tsp, butter 1 cup, each dough sugar 1 cup, oats 3 cups; soda, salt and vanilla 1 tsp. Two eggs are cracked separately. Water and topping sugar remain separate for the fork.

Mix with circular mouse movement over the bowl, or hold Space. Complete dry whisking, creaming butter/sugars, two eggs + vanilla, three gradual dry additions, then three oat additions. The whisk and dough visibly change. For eggs, G picks up, T taps the edge, Enter cracks; mouse uses the egg, rim, then bowl. Two taps give a clean crack; poor taps leave shell fragments and reduce quality.

Visit the fridge for a one-hour time skip, set/preheat the oven, return to the counter, spray the tray, place six representative walnut portions (the full recipe yields roughly 24), and dip the fork in water/sugar before each press. Mouse placement permits bad spacing; R resets the tray. Keyboard Enter places the next suggested position; arrows choose a cookie for pressing, D dips the fork.

Insert the tray at the oven. Baking time advances only after insertion and stops while paused/menu/loading. One real second equals ¼ recipe minute; the 8–10-minute window occurs around 32–40 seconds. M takes mitts, S swaps racks after four minutes, Enter pulls the tray. The close-up and world oven both show timing and changing cookies. Cool on the tray for five abbreviated seconds, transfer to the rack, then taste together. Imperfect cookies always advance and award the original cookie keepsake.

Scoring: ingredients 25, continuous measurement accuracy 25, ordered preparation/mixing/spacing 20, chill 10, temperature 10, bake timing 10; shells, missing spray and omitted rack swap subtract small penalties. Scores remain bounded 0–100. Shape/colour, playful result text and the existing first/latest scrapbook notes reflect performance. The legacy evaluator remains available for old test cases; completed old scores are preserved and active old recipe phases adapt to physical phases. Close-ups reload into the usable kitchen, retaining partial pours, mixing, eggs, tray positions and timer state.

## Cinematic presentation

`memory_cinematic.gd` owns short pan/focus/zoom, letterbox, actor movement/facing, gestures and timed sound cues. A single idempotent finish path restores camera/control and advances its callback once. Space/E/Esc skips; Reduced Motion removes zoom. Checkpoints distinguish introduction staging from post-task staging, so loading continues safely.

UESS adds a camera beat around the existing foot accident, debate reaction, visible diploma/congratulations staging and departing missed-goodbye movement. Ghosting/Salinas adds quieter framing and phone reaction without changing chronology/messages. Ikura delivers actual gyoza/ramen/sushi sprites to the couple’s table after the preserved order and corrected ten-question quiz. Halloween adds getting-ready/arrival/dance direction and a concise seated → leaning → kiss sequence using the existing actual affection frames. Romance remains forgiving.

## Additional improvements

- F1 recipe card during every close-up; actual quantities remain available without a penalty.
- Keyboard alternatives for sustained mouse gestures and tray arrangement.
- A helping Guillermo during the prep quiz and growing flour/oat crumbs on the counter.
- Both world and close-up oven feedback; the player may step away and return while baking.
- Stable collision recovery avoids returning a loaded character to an exact furniture tangent.

## References and art

All eight PNGs in local `assets/references/References for Cookie Level/` were inspected before design. Images 1–2 guide sage fridge, domestic cabinet/pantry layout, sink/window/plants and the island; image 3 guides counter framing and measurement props; 4–5 guide bowl/whisk and egg interactions; 6 guides tray spacing/fork; 7 guides oven timing/mitts; 8 guides readable individual tools. Their sample quantities/chocolate chips/UI are not copied into the actual recipe. No pet, private letter or relationship fact is invented.

Original raster art was generated with the built-in imagegen tool: `assets/art/baking/home_kitchen.png`, `counter.png`, and the separate transparent bowl/cup/whisk/egg/tray/fork/mitt/rack/jar sprites. Backgrounds are 320×180, props 64×48 (jar 64×80), each normalized to at most 40 colours, displayed with nearest filtering and no mipmaps. Original native SVG prototypes remain alongside the final sprites. Prompt/provenance details: `milestone2/ART_PROVENANCE.md`. References stay local, ignored and excluded from the export.

## Validation and evidence

Thirteen suites pass 2,603 checks: M2 53; playtest fixes 98; Director’s Cut 69; story 470; persistence 206; minigames 686; living memories 89; animation 222; chapter overhaul 170; redesign 63; target visibility 245; navigation 220; audio 12. The story runner reaches credits through all 17 scenes and 219 dialogue steps. New checks cover physical scoring, old result/mid-recipe adaptation, JSON checkpoints, reachable stations, E/Tab transitions, mouse pouring/release, circular mixing, keyboard selection, paused simulation, progression and idempotent skip. The old suite now delegates physical baking to the new driver rather than asserting obsolete quiz-only phases.

Native Godot viewport captures: `milestone2/source/`, repeated against the exported Windows executable in `milestone2/export/`. `baking.gif`, `mixing.gif` and `first_kiss.gif` are assembled exclusively from those in-engine frames. Diagnostic capture flags require `--self-test`; ordinary startup never runs them or touches a QA checkpoint.

Build: `builds/directors-cut-milestone-2/One More Adventure Amor.exe` with matching PCK. Package: `builds/One More Adventure Amor Directors Cut Milestone 2.zip`. Previous builds remain intact. Windows x64, Godot 4.7.2, GL Compatibility. Automated/native render validation does not substitute for a human pacing/laptop playtest. The personal letter remains an explicit editable placeholder and final licensed music is still pending; this remains a development build.

Comparison: https://github.com/Gnovillo1120/one-more-adventure-amor/compare/main...feature/directors-cut-milestone-2

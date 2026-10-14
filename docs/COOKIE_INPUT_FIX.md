# Cookie progression blocker — actual E input fix

## Root cause

The persistent `BakingView` controller remains `game.challenge` after the quiz even though its panel closes, `modal` becomes null, the world becomes active and `session.state.station` is empty. The old global `_unhandled_input` branch unconditionally called `challenge.key()` and returned for every key whenever a challenge existed. `BakingView.key()` ignores station keys while station is empty. Consequently physical E reached the controller, returned without action, and never reached `memory.interact()`. The world still calculated a valid `baking:pantry`/fridge/sink target and displayed E. Neither dialogue nor cinematics was active; the state was correctly `gather`. This was an input ownership mismatch, not a missing recipe state or scene callback.

The previous 2,603 checks did not cover this boundary. The prior integration runner directly called `memory.interact()`, `view.key()` and station methods; the capture runner directly drove actions. Those verified state/graphics but bypassed the defective global keyboard dispatch. They were insufficient evidence of physical E handling.

## Corrected pathway

Physical `InputEventKey(E)` → `game._input` leaves world-mode baking input unconsumed → `_unhandled_input` passes through the retained controller → `memory.interact()` selects the same contextual target used by the prompt → `target_interacted` → `game._target_interaction` → `BakingView.show_station` → durable pantry/tools state → changed/autosave, visible inventory objective and feedback.

Baking close-ups explicitly own their keyboard controls before GUI focus navigation, including Tab, arrows and letter controls. World mode owns spatial E instead. The closed panel is detached immediately before freeing, so it cannot retain focus. Context selection is shared for active baking; other memories retain their established behavior.

After the quiz, E at pantry collects the ten dry ingredients; E at fridge collects butter/eggs; E at sink collects water and tools. Repeated visits do not duplicate or toggle off ingredients. The objective shows 0/13 → 10/13 → 12/13 → 13/13. E at the counter explains missing ingredients/tools until ready, then opens measuring. Later wrong-station visits explain the next required station. Existing partial saves resume without resetting the quiz or batch. No cinematic or art improvements are included.

## Regression and exported validation

`baking_input_test.gd` runs the real memory introduction and three-question quiz via `Input.parse_input_event`, then verifies actual E dispatch and ingredient collection. Headless uses legal station placement because its DisplayServer cannot map held physical walking keys; its 17 input-routing checks are not claimed as walking or full bake proof.

`baking_input_runner.gd` runs natively and in the actual Windows release. It walks the navigation route with held WASD events, injects physical E press/release events, and uses only actual keyboard controls and real process/timer advancement for the rest of cooking. It never calls station, act, key or interact methods. It completes measurement, all mixing/egg/addition steps, chilling, preheat, spraying/portions, all fork presses, insertion/mitts/rack swap, a timed pull in the perfect window, cooling, tasting and chapter completion. Tab and pause/resume are included. Both native runs pass 826 checks; many checks are repeated walking-waypoint assertions, not 826 distinct features. The exported run contains 1,701 logged key events and yields a 100% batch.

The test-only `--prove-original-routing` option recreates the old unconditional router in an in-memory script without changing project source. The same regression fails at the first station E interaction (`counter explains missing ingredients`), exit 1, proving sensitivity to the reported root cause. The corrected router passes. The old-route failure is expected and retained separately from passing QA results.

All fourteen headless suites pass 2,620 checks, including the full 17-scene / 219-dialogue-step story route and existing save/animation/quiz/voxel checks. The M2 semantic suite now expects automatic station collection. The native Windows workflow is additional evidence rather than a substitute for the routing test.

Evidence: `milestone2/input_fix/export/` contains 35 actual viewport captures and `INPUT_TRACE.json`; each station has before-E, E-pressed and after-E frames, plus perfect-window and result captures. The input annotation is diagnostic-only and records the actual injected key; normal gameplay has no diagnostic overlay. `actual_input_progression.gif` is assembled exclusively from those exported-engine frames. `QA_RESULTS.json` and `BUILD_VERIFICATION.json` record results and hashes. Previous M2 screenshots/GIFs are historical state/render evidence, not proof of this input fix.

Run headless: Godot `--headless --path . --script scripts/baking_input_test.gd -- --self-test`.
Run native/export: `-- --validate-baking-input --self-test --capture-dir=ABSOLUTE_PATH`.
Package after export validation: `tools/package_baking_input_fix.py`.

## Corrected build

Separate folder: `builds/directors-cut-milestone-2-input-fix/One More Adventure Amor.exe`, with matching PCK. ZIP: `builds/One More Adventure Amor Directors Cut Milestone 2 Input Fix.zip`. Start this EXE, not the preserved original M2 EXE. The previous M2 ZIP hash is verified unchanged. Existing saves are compatible, including a session stuck at ingredient gathering. Private references remain excluded. The final letter/music remain pending. Work stays on `feature/directors-cut-milestone-2`; no merge into main.

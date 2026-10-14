# Continue here — Director’s Cut Milestone 2

Current branch: `feature/directors-cut-milestone-2`, based on stable main `b472b49`. Read `MILESTONE_2.md` and current `DEVELOPMENT_STATUS.md`. Do not restart the working game. The 2D cinematic controller, spatial domestic kitchen, physical baking phases, persistent partial actions and source/export evidence are implemented. Preserve all M1 playtest fixes, five objects, corrected quiz facts, saves and no-blush/clean-shaven sprites.

Architecture additions: `memory_cinematic.gd` owns concise staging/skip cleanup; `baking_session.gd` owns durable physical actions/scoring and legacy adaptation; `baking_view.gd` connects stations and counter controls; `baking_room.gd` renders live batch/oven/crumbs. Game retains progression/dialogue/save ownership. `milestone2_test.gd` verifies new integration; guarded `milestone2_capture_runner.gd` writes actual source/export viewport evidence without assertion side effects in release builds. Capture source, export, and capture the Windows executable sequentially; then run `tools/package_milestone2.py`. Never use generated concept images as gameplay evidence.

Next work should follow user playtest feedback. Later milestones still include visible voxel kidnapping/rescue staging, final beach/letter presentation, supplied personal letter and licensed music. The current build remains a development release. Personal reference images stay local, ignored and export-excluded. No branch is merged automatically.

## Historical Milestone 1 continuation notes

# Continue here — Director's Cut

Milestone 1 playtest corrections are complete. Read `PLAYTEST_FIXES.md` before continuing. The explicit gameplay HUD keepsakes, lobby bench and generic signposts are removed; real phone photography, corrected quiz facts/cache migration and unobstructed beach card are implemented. Latest corrected build is `builds/directors-cut-playtest-fixes/`; twelve suites pass 2,563 checks. Preserve these corrections and their native evidence.

Continue `feature/directors-cut`; do not restart or replace working systems. Read `DIRECTORS_CUT.md` and the top of `DEVELOPMENT_STATUS.md`. Milestone 1 and the priority keepsake amendment are implemented. Earlier releases remain preserved. Main is not merged automatically.

Architecture: `game.gd` still owns progression/dialogue/challenge/save/UI/audio. `directors_cut.gd` owns optional hub/book state and whole-chapter replay bookmarks; `memory_room.gd` owns the 2D room. `data/directors_cut.json` separates six chapter pages from five personal objects. Existing memory/voxel worlds, living activities and corrected character animation systems remain working.

Exactly five featured personal objects: Yoda LEGO keychain, gold A necklace, Guillermo photograph (first-message pixel interpretation), MUN diploma, oatmeal recipe. The bandana stays in Halloween clothing and its getting-ready minigame, never symbolic inventory. Gift chronology and actual quotations must not be invented. Private reference photos stay local, ignored and excluded. Do not add future dog walks/Monopoly/tomatoes in this implementation. Guillermo remains clean-shaven without cheek blush.

Next substantial milestone: MUN award/missed-goodbye staging, ghosting phone pacing, restaurant food delivery, Halloween confession dated 21 October 2023 and visible baking actions. Then milestone 3: peaceful shared voxel world, actual visible kidnapping, confrontation/rescue animation. Then milestone 4: final beach and letter presentation, supplied personal letter, licensed music, accessibility/pacing and target laptop testing. Never invent the personal letter. Existing complete route does not mean the Director's Cut is finished.

QA runners require `-- --self-test`. Eleven suites pass 2,465 checks. `directors_cut_test.gd` covers optional objects, legacy migration, hub saves, interrupted intro, replay restoration and UI bounds; `story_test.gd` explicitly visits hub transitions and traverses all 17 scenes. Use native Godot captures, never concept images as gameplay proof. Source and export captures use `-- --capture-directors --self-test --capture-dir=ABSOLUTE_PATH`. Capture/export sequentially to avoid locking output PNGs during resource scans. Build separately to `builds/directors-cut-milestone-1/` and use `tools/package_directors_release.py`; older builds must remain intact.

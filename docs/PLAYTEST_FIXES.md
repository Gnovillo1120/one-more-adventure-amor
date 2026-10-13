# Director's Cut milestone 1 — playtest corrections

13 October 2026, on the existing `feature/directors-cut` branch. Started from clean `6fc3c13`. Memory Room, five personal keepsakes, chapter replay, existing game route, minigames, walking/swimming/outfit art and previous builds are preserved. This is a targeted correction pass; milestones 2–4 are not implemented here.

## Corrections and causes

The upper-right keepsakes were deliberately added by `_build_hud()` in `scripts/game.gd`, rather than leaked room nodes. That loop is removed entirely. Normal 2D/voxel HUDs contain no decorative Memory Book textures; room/inspection rendering remains owned by the director, and the existing world/UI cleanup still removes it on scene changes. Scripted voxel memory pedestals are retained.

The lobby's wooden bench was an extra `LivingMemories` prop at `(940,360)`, without a sitting activity or dedicated blocker. Removed its creation. The former footprint is walkable; the background couches, fountain and meaningful club/party seating remain.

Generic `notice` signposts become flat documents where the interaction actually concerns papers, notes or a schedule. The goodbye decision is a contextual-only choice hotspot, without an invented object. A legacy notice descriptor also renders flat paper rather than a post. Real room names, delegation labels, fixtures and exit signage remain. `context_target()` selects the same nearest valid target as E interaction, checks intervening furniture, and hides during dialogue, menus, phone use and photo actions. One small E badge appears beside actual objects or above NPC heads; activities without a physical marker use the existing bottom prompt area. No field of arrows/rings/ellipsis markers remains. Objective state and selected highlight are separate so the real exit remains visibly open after completion.

The beach card now has its own ground anchor `(820,465)` instead of being drawn over Guillermo at `(715,430)`. Neither character is relocated. The flattened card and bottom `E · Leer carta` prompt avoid Guillermo's sprite. Prompts disappear while the letter dialogue opens, leaving portraits unobstructed. The personal letter remains the unchanged editable placeholder.

## Photography

The optional MUN action is Anami taking a phone photograph of the conference/Guillermo. No authored context required a professional photographer's camera. The existing optional party-photo activity uses the same action with outfit-matched arms.

`scripts/photo_action.gd` provides a 2.1-second action: stop/facing → pocket retrieval → hold → raise/aim → focus → shutter → lower → idle. Forty transparent, authored native SVG overlay frames provide five poses in four directions for formal and Halloween sleeves, aligned with existing 32×48 bodies and rendered at 2× nearest scale. Character bodies/likenesses are preserved. `tools/author_photo_action.py` is their editable source and creates the original short PCM camera-shutter sound. No reference-photo pixels or external recordings are used.

The shutter at 1.25 seconds is the authoritative unlock. Camera focus brackets and a brief 16% subject flash make the shot visible; Reduced Motion disables camera zoom and subject flash. Controls remain locked during the action. Focus restores the original viewport transform, including when the scene is interrupted. A save before the shutter cannot grant a photograph; a saved completed shot reloads in safe idle. Repeat actions retain one unlock; album labels are deduplicated across the two conference scenes.

The optional conference photograph remains a gameplay recreation under **Book → Fotos de la partida**, separate from Guillermo's Instagram photograph among the five personal keepsakes. Its actual viewport thumbnail is local player data. Visual inspection also exposed the old album preview being clamped to its image's large minimum size; it now stays inside its intended 275×155 rectangle.

## Corrected quiz facts and legacy sessions

Q4 is C / 5, with `Cinco ciudades.` Q8 is C / Xbox 360. Both zero-based answer indices are 2. Options, ten questions, Hard Mode at index 7 and the 8/10 threshold remain. The generation helper and explicit test answer key were corrected too.

The bank has revision 2. An unfinished saved quiz from the old bank has its answered choices, score and feedback re-evaluated against corrected facts on load; an active result updates its pass/fail status using the existing threshold. Completed chapter progress is not revoked. This prevents Continue from displaying cached `Cuatro ciudades` feedback after the data correction. Normal session roundtrips remain compatible with Godot's JSON numeric representation.

## Verification

Twelve suites pass, **2,563 checks**: new playtest regressions 98; Director's Cut 69; story 470; persistence 206; minigames 699; living activities 89; animation 222; chapter overhaul 170; redesign 63; target visibility 245; navigation 220; audio 12. Story traversal covers all 17 scenes, 219 dialogue steps and preserved voxel rescue.

New checks cover overlay absence across memory/voxel transitions, room/inspection ownership, five inspected entries through real save/load, bench footprint, obsolete descriptors, nearest prompt/wall selection, photograph timing/unique unlock, Instagram separation, interrupting focus, album bounds/deduplication, corrected quiz scoring and old-session migration, and the final card interaction/placeholder.

`docs/playtest/before/` renders the preserved milestone-1 PCK; `source/` and `export/` render the corrected source and executable. Captures cover the lobby, room exit, document prompt, all five phone poses, shutter/unlock, scrapbook/album, Q4, Q8/Hard Mode, beach/card at 1280×720 and a 960×540 window, and letter dialogue. `proof.json` records actual physical E input, pose frame/busy/unlock timing and successful final-card interaction. `tools/playtest_evidence.py` assembles only actual viewport captures into comparisons (old build left, corrected right) and photography GIFs. PNGs captured during fade-in were refreshed after UI settling; they are not concept art.

Native conditions: Godot 4.7.2, GL Compatibility, NVIDIA RTX 3070 Laptop GPU / driver 555.97. The logical viewport stays 1280×720 and scales into the smaller window. No performance benchmark or lower-end compatibility guarantee is claimed. The supplied attachment contained request text; these before images reproduce the issues from the preserved executable rather than being the user's original screenshots.

## Delivery and remaining limits

Corrected executable: `builds/directors-cut-playtest-fixes/One More Adventure Amor.exe`. ZIP: `builds/One More Adventure Amor Directors Cut Playtest Fixes.zip`. Earlier milestone-1 executable/PCK/ZIP remain untouched. Packaging checks runtime additions, reference/concept/test/tool exclusions and ZIP integrity. Private reference photographs remain ignored, untracked and excluded.

Phone poses are discrete overlays on existing bodies, not a replacement full-body atlas. The saved optional photograph is a full gameplay viewport recreation, including the existing HUD. Existing chapter minigames and animations are preserved. The actual personal letter, final licensed music, older-laptop/human pacing verification and cinematic milestones 2–4 remain pending. No merge to main.

Release verification: corrected ZIP is 42,879,543 bytes; SHA-256 `b7b4b2d442c18d2cfc6b9bb64c0ed143d5c8ee88e1bf67a1ee0a48a669b9f503`. Native export exits with no stderr errors. Original milestone-1 ZIP still matches `f983191d719cd952f4ca5f2195431839debd091c817c4d363bc14b745c292037`.

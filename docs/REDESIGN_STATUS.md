# Redesign checkpoint — Phase A

10 October 2026. Existing clean branch feature/chapter-1-2-overhaul at d191880 inspected before edits. Main and all original references remain untouched. PR #1 stays open; no merge/reset/force push.

Implemented: scene-specific layered conference, dining and Ikura rooms; depth-sorted actors/furniture; layout-defined feet collision; accessible France/Chad/Brazil/Kenya with ordinary interaction radius; integrated chair/table fixtures; seated couple compositions and a short approach/sit tween; shared actor rendering; container-based clipped chat with wrapped full-length messages, complete history (up to 100), automatic arrival scrolling and Home/End/Page Up/Page Down. Guillermo quiz is editable in data/guillermo_quiz_template.json, with choices, zero-based correct answers, score responses and optional image paths. It is explicitly a placeholder and does not infer private facts.

Architecture: data/room_layouts.json is the single furniture/footprint layout source; layered_room.gd draws only floor/walls, room_fixture.gd draws foreground furniture, memory_actor.gd shares original walking art and seated compositions. memory_world.gd owns a Y-sorted depth_root. Scene IDs, order, authored story, portrait designs, walking sheets and v1 saves are preserved. Saved seating is additive. New fixtures replace old painted furniture in the three rebuilt rooms. Other rooms retain their backgrounds for the later rebuild.

Visual review: actual Godot native captures compared with prior build and original UESS conference/dining photos. New rooms show spatially consistent furniture and foreground table occlusion. This is an architectural checkpoint, not final production art: floors, decoration, NPC pose variety and room density still require refinement. Furniture is original code-native pixel art; no copied reference photographs are shipped.

## Exact continuation

1. Phase A follow-up/Phase B: refine room density, table silhouettes and lighting; add proper authored seated frames and staging for awards, first kiss, pool confession and ending. Retain the new navigation/collision and chat architecture. Complete layer conversion for lobby/auditorium/party/kitchen/beach.
2. Phase C: inspect every Minecraft reference, create reference inventory and approximate landmark layout, then build ONLY main house/pond/paths/cherry valley as the rendered quality benchmark. Preserve current quest IDs until the benchmark passes visual review.
3. Phase D: expand the benchmark to farms, trading hall, waterfall/cave and elevated terrain with batched textured meshes; refine animated voxel characters/animals, compact HUD and older-laptop profiling.
4. Phase E: actual 45–90s in-engine kidnapping (peaceful start, unease, reveal, restraint, visible dragging, pushback, closing portal, cat aftermath), then animated rescue/reunion. Integrate viewed/skip/replay and save state. No such cinematics are implemented in this checkpoint; existing prototype events remain.
5. Phase F: repeat automated and real movement QA, visual comparison, cinematic proof frames, final Windows export/package. Supply licensed instrumental recordings; existing drop-in pipeline remains functional and synthetic music stays muted.

Run each scripts/*_test.gd with Godot --headless --path . --script <file> -- --self-test. New redesign_test includes injected physical WASD input for all four delegations and both seating routes, phone containment/height/scrolling and template score. Existing full story runner covers all 18 scenes to credits, but 3D combat QA uses target placement; it does not replace the requested future real-path 3D playtest.

Source captures: docs/redesign/before and docs/redesign/after. Required seating: 03g_dining_seated and 04f_ikura_seated; phone stress: 04g_phone_long and 04h_phone_960. Capture images are local ignored artifacts. The capture image is a 1280×720 logical viewport even when native window size changes; a smaller window scales the same layout.

## Checkpoint verification and Windows package

Phase A commit: 57433ed. All seven automated suites pass: story 503, persistence 231, overhaul 177, visibility 255, navigation 220, audio 12, redesign 63 checks. This is regression evidence, not a visual-quality score. New movement QA uses injected WASD; routes to every delegate and both seating positions execute production movement. The source and actual release produce 29 native captures, with mouse/keyboard ordering and camera checks passing. Long phone messages were visually inspected after full arrival; they wrap and scroll within the clipped screen. Main character portraits and walking designs remain untouched.

Visual evidence: docs/redesign/before versus docs/redesign/release/02_uees.png, 03c_dining.png, 03g_dining_seated.png, 04_ikura.png, 04f_ikura_seated.png, 04g_phone_long.png and 04h_phone_960.png. The new seated torso/lap composition fixes standing behind an empty chair; dedicated new seated sprite artwork is still recommended. The room art remains an intermediate code-native style and has not met the requested final production bar.

Playable checkpoint: builds/redesign-phase-a/One More Adventure Amor.exe and matching PCK. Distribution: builds/One More Adventure Amor Redesign Phase A.zip. This is explicitly an intermediate release. No rebuilt Minecraft benchmark or kidnapping proof frames are supplied because those phases are not implemented. Prior build folders and private references are preserved.

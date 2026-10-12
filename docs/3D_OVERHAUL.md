# 3D overhaul (visual layer)

Gameplay is unchanged: quest IDs, target positions, saves and all 7 QA suites behave as before.

## New files
- `scripts/voxel_style.gd` - materials, sky/lighting moods (day -> End), chunked voxel terrain, cherry trees, particles, props.
- `scripts/voxel_chars.gd` - chibi anime-voxel characters (Anami, Guillermo, villagers), cat, shadow creatures, boss, face painter, walk/swing animation.
- `assets/shaders/` - `toon`, `outline`, `water`, `portal`, `sky`.
- `tools/capture_3d.gd` - dev-only screenshot rig.

## Changed
- `scripts/voxel_world.gd`: world building rewritten to use the above; gameplay half only gets animation hooks, smooth mood transitions, Guillermo's happy face when freed.

## Looking at the result (works headless, software GL)
    xvfb-run -a godot --path . --rendering-driver opengl3 --script tools/capture_3d.gd -- /tmp/shot
Prints draw calls / triangles per view. Last measured: ~135-400k tris, 250-1700 draws (software renderer, not real FPS).

## Known limits / next steps
1. Not Genshin-grade models: real skinned characters (VRoid, Meshy/Tripo) would replace voxel chibis.
2. HUD (game.gd) untouched; bottom bars overlap.
3. Needs a human playthrough and an old-laptop FPS test; Windows export not rebuilt.
4. If slow: lower tree chance in `_build_forest`, disable sun shadows in `Style.make_sun`.

## Prompt for continuing with an AI agent
Do NOT change quest IDs, target positions or gameplay logic. Work only in voxel_style.gd, voxel_chars.gd, assets/shaders. After EVERY change run tools/capture_3d.gd, view the PNGs, compare with docs/reference_contact.jpg. Do not claim a visual improvement you have not looked at. Keep under ~400k tris/frame. One task at a time.

# Continue here

Do not restart or replace working systems. Read DEVELOPMENT_STATUS.md, GAME_DESIGN.md and ASSET_REFERENCE.md first. The complete route and Windows build exist. Main scene: scenes/main.tscn; orchestration/UI/save/audio: scripts/game.gd; 2D navigation/animation: scripts/memory_world.gd; 3D exploration/combat/checkpoints: scripts/voxel_world.gd; authored Spanish story: data/story.json.

Art contract: memories and ending are 2D top-down pixel art; only the rescue uses 3D voxels. Final portraits are separate transparent 64×64 PNGs, eight expressions per character/outfit. Use crisp limited-palette pixels and nearest-neighbor integer display. Guillermo has NO mustache. Preserve original references and completed generated assets. Final walking sheets are assets/art/sprites-v2; original sheets remain fallback/source.

Next useful work: personalize the explicitly marked letter, run a human playthrough to assess pacing/camera/music, and test the intended older laptop. Measure duration before promising 30–45 minutes. Change only issues found, rerun relevant tests, export again and refresh the ZIP. QA runners require --self-test and isolate player saves. Release instructions and licenses are in RELEASE.md; source and exported screenshot galleries provide visual evidence.

Current feature update: Chapters 1–2 overhaul is implemented; read CHAPTER_OVERHAUL.md. Music drafts are preserved but muted pending licensed WAV/OGG replacements; use AUDIO.md. Keep feature/chapter-1-2-overhaul and do not merge main without user instruction.

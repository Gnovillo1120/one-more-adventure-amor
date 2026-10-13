# Fix four-direction swimsuit walking and swimming animations

The swimsuit walking atlas mixed viewpoints within animation rows, causing visible spinning. Swimming always selected one row. Replace the defective walking sheet and add actual four-direction swimming, separate treading and brief ladder entry/exit animations with splash and safe movement locks.

Centralize row/frame mapping, preserve idle frames and clothing during actions, hold seated poses, and vary supported NPC pose timing without increasing counts. Add a developer-only seven-outfit/four-direction inspector with pause/step and exclude it from exports. Saves during ladder transitions resolve to a legal destination with control restored.

Validation: ten suites / 2,396 checks, including preserved minigames, 17-scene story and voxel rescue. Native source and exported Windows captures use actual WASD/E input. `docs/ANIMATION_POLISH.md` links directional movement GIFs/strips, treading/ladder evidence and viewer captures. A separate Windows ZIP preserves previous builds and excludes private/developer material.

Limits: front-facing treading, reversed climbing frames for exit, existing NPC pose library and static directional intermediate dressing stages. Further human pacing/lower-end playtesting remain useful. Environments, dialogue, minigames, voxel gameplay and Guillermo's clean-shaven/no-blush art are preserved.

[Prepared comparison](https://github.com/Gnovillo1120/one-more-adventure-amor/compare/main...feature/2d-animation-polish?expand=1). No automatic merge.

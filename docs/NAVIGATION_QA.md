# 3D navigation collision audit

Run `Godot --headless --path . --script scripts/navigation_test.gd`.

Result: **16 target checks passed; zero failures**. The connected walkable grid
contains 3,397 mainland cells and 1,092 End cells.

The runner instantiates the actual voxel world, waits for physics registration,
and samples the real static collision geometry on a one-meter grid. Downward
physics rays establish supporting floor heights. A capsule with height 1.8m and
radius .38m checks body clearance, slightly wider than the player's .35m radius.
Flood fill connects cardinal neighbor cells only when floor heights differ by
less than .08m, so tests do not assume jumping or stair climbing.

The mainland checks cover fish, cat, villager, all three ordered farm switches,
cave portal, the house doorway and its interior. The End checks cover its bridge
entry, all four memory pedestals, Guillermo and sword range around the boss.
The runner builds the same bridge slab and rail geometry used by the bridge
interaction before scanning the End; it does not change production geometry.
Target checks use 2.7m reach, inside the gameplay interaction radius of 3.5m.

This is a **collision reachability audit**, not an input-driven bot playthrough.
It does not claim to verify mouse navigation, steering comfort, animation,
camera clipping, enemy avoidance or a human player's completion time. Actual
quest transitions and combat state are separately covered by `story_test.gd`.
Manual keyboard/mouse playthrough remains useful for those experiential checks.

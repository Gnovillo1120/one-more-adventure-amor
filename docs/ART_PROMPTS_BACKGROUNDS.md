# Generated environment artwork

All ten final PNGs are in `assets/art/backgrounds/`. Generated with the built-in image generation tool, then processed with `tools/finish_backgrounds.py`: nearest sampling to 320x180 logical pixels, quantization to 32 colors without dithering, nearest enlargement to 1280x720. This gives an actual coarse square-pixel grid and discrete palette. Original generated files remain in Codex generated-images storage.

## Shared prompt constraints

Original authentic SNES-inspired 16-bit pixel art for a 16:9 Godot 2D adventure, amber/teal/lavender palette; coarse square clusters, limited colors, discrete shading; no smooth gradients or painterly illustration. Orthographic top-down interior scenes with short visible wall faces, broad open lower half for movement, quiet bottom 20 percent for dialogue. No people, text, logos or watermarks. Reference photos are visual design references only, never retained photographic pixels.

## Scene prompt set

- `lobby.png`: University vestibule with cream wall panels, glass front entrance doors upper center, teal sofas at upper sides, palm planters, low coffee table, broad open cream tiled lower floor.
- `present.png`: Cozy home gaming room with two desktop PCs on an upper-wall desk, blank teal screens, keyboards and empty chairs, lavender sofa, bookshelf and plant, small upper-center rug, clear lower wood floor.
- `phone.png`: Salinas yachtclub terrace with marina and white anchored yachts through large upper window/railing, distant coastal palms, two empty wicker seats and round table tucked upper left, side plants, clear cream tiled lower terrace. Phone itself is supplied by the game UI.

- `debate.png`: UESS debate-room photo reference. Brown wood-paneled lecture room, tiered desks and black chairs at upper sides, large blank projection screen at back, geometric stained glass at right, podium upper left, open beige tiled central aisle and lower floor.
- `dining.png`: UESS dining photo reference. Round dark-teal cloth tables, slender white ladder-back chairs, small greenery centerpieces, pale marble panels, bright back windows, buffet upper left, clear beige tiled lower floor.
- `auditorium.png`: UESS graduation auditorium photo reference. Tiered pale gray seats upper left/right, staircase central aisle, cream panels, amber lamps, low wooden lectern and diploma table, open lower wooden stage.
- `ikura.png`: Cozy small Japanese restaurant evening, timber bar and stools upper wall, amber paper lanterns, bamboo corner, small tables with bowls/gyoza plates at sides, teal chairs, shoji details, broad open wood floor.
- `party.png`: Large backyard Halloween night, warm house sliding doors at top, string lights and pumpkins, rectangular teal pool upper right with concrete patio, broad dark lawn lower half, left concrete path, snack table and potted palms along edges.
- `kitchen.png`: Warm home kitchen evening, oak cupboards stove and countertop upper wall, cookie tray and mixing bowl, teal fridge upper right, lavender night window, left dining table, right houseplant, clear lower cream tile.
- `beach.png`: Cinematic sunset beach in crisp pixel clusters, peach/lavender clouds above horizontal teal ocean, sun reflection, broad clear sandy lower45 percent, two empty small cushions near shore. No people. This deliberately uses a horizon composition for the final memory, while the room scenes use top-down composition.

Actual architecture is interpreted for game readability; these scenes are original illustrations rather than measured replicas of the supplied photos.

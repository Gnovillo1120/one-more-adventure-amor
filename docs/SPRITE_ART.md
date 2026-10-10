# Character sprites, second art pass

Generated with the built-in image generation tool, using the original character
portraits and the couple photograph as references. No photo pixels appear in the
finished sprites. Sources remain in `assets/art/concepts/`; original first-pass
sprites remain untouched.

## Deliverables

- `assets/art/sprites-v2/anami_casual.png`
- `assets/art/sprites-v2/guillermo_casual.png`
- `assets/art/sprites-v2/anami_formal.png`
- `assets/art/sprites-v2/guillermo_formal.png`
- `assets/art/sprites-v2/anami_halloween.png`
- `assets/art/sprites-v2/guillermo_halloween.png`
- `{name}_preview.png`: nearest-neighbor 4x inspection sheet, not a game texture.
- `{name}_validation.json`: dimensions, palette count, alpha, frame bounds.

All sheets are 128x192 RGBA PNG, sixteen 32x48 cells. Direction rows are **down,
left, right, back**; animation columns are **idle, walk A, idle, walk B**. All feet
have an alpha-bound bottom at local y=46. Each entire sheet uses 24 opaque RGB
colors and alpha values 0/255. Import with nearest filtering.

## Prompt specifications

Each character received separate built-in generation calls, with transparent
background enabled and the portrait plus couple photograph supplied as reference
images. Prompts requested authentic hand-placed tiny square pixels, a limited
24-color palette, classic nostalgic top-down RPG proportions, four columns and
four direction rows, identical anatomy/outfit/scale, equal baseline, idle and
opposite walking legs, no grid lines, no labels, no shadows, and a large upscale
of a logical 128x192 atlas to permit cleanup.

Anami: long light-brown hair, small dark-framed glasses, teal casual blouse, dark
blue jeans, light shoes, warm tan skin; recognizable appearance from the woman in
the reference photo. Guillermo: medium dark-brown center-parted hair, dark
eyebrows, clean-shaven face, **no mustache**, black jacket, white T-shirt, dark
jeans, white shoes, warm tan skin. Outfit atlases additionally requested Anami's
cream blazer/lavender blouse and denim dress/red bandana, and Guillermo's navy
suit/amber tie and black jacket with one red eye/metallic cheek makeup. No smooth illustration or antialiased output
was requested. Back-facing rows show the back of the hair and clothing.

## Cleanup and verification

`python tools/prepare_sprite_atlas.py assets/art/concepts/anami_sprite_atlas_source.png anami`

`python tools/prepare_sprite_atlas.py assets/art/concepts/guillermo_sprite_atlas_source.png guillermo`

`python tools/prepare_sprite_atlas.py assets/art/concepts/anami_wardrobe_atlas_source.png anami --wardrobe`

`python tools/prepare_sprite_atlas.py assets/art/concepts/guillermo_formal_atlas_source.png guillermo --outfit formal`

`python tools/prepare_sprite_atlas.py assets/art/concepts/guillermo_halloween_atlas_source.png guillermo --outfit halloween`

The script detects the four occupied alpha bands rather than assuming perfectly
even generated canvas padding; this prevents the next row's hair entering a
previous frame. It thresholds source alpha, crops sixteen characters, applies
one fixed scale per sheet, centers and bottom-aligns frames, reduces each full
atlas to a shared 24-color palette without dithering, and verifies every cell.
The `--wardrobe` option requires eight actual direction bands and splits formal
and Halloween halves. Guillermo's first wardrobe source contained only seven
rows, so it failed validation rather than silently dropping a direction. Its
valid top four rows were cropped to the formal source; a separate generation
was requested for the incomplete Halloween outfit. The corrected Halloween
source contains all four directions and passed all sixteen-frame checks.
Its palette reserves two colors for the tiny red eye and metallic cheek so
rare makeup pixels are preserved rather than merged into the hair shades.
The source files are preserved.

Final sheets were visually inspected enlarged with nearest-neighbor
scaling. Four directions are readable, silhouettes remain separated, no heads
are clipped, and all shoes share a baseline. Profile walk frames have similar
silhouettes, a normal limitation of a four-frame tiny sprite animation; idle and
walk poses are distinct.

# Art provenance — Milestone 2

Built-in `image_gen.imagegen` through the imagegen skill; no CLI fallback. Four original accepted outputs, not copied references. Original output files remain in the local Codex generated-images directory; project runtime files are in `assets/art/baking/`.

All eight reference PNGs were inspected first. Input guidance: kitchen images 1 + 8; empty counter images 3 + 5; props image 8; jar image 3. Backgrounds are 320×180/40 colours with no dithering. Transparent props are separate 64×48 PNGs, jar 64×80, at most 40 colours, actual alpha retained. Atlas spacing differed from the requested equal grid, so inspected object bounds were cropped individually; disconnected neighboring crop fragments were removed during normalization. No gameplay UI, characters or cookie appearance is baked into the counter artwork. Godot supplies those interactive elements. Nearest filtering and no mipmaps preserve the pixel grid. Original SVG prototypes remain, but final close-ups use PNG sprites.

## Prompt 1

Local original: `.codex/generated_images/01a12398-aa13-7940-9736-9b23c3038753/exec-2f294564-0cdd-421b-b967-ac493fd456a4.png`.

```text
Use case: stylized-concept. Create a production game environment background for a 2D top-down nostalgic pixel RPG at 16:9. Use supplied references only for domestic details, NOT their smooth style. Authentic crisp hand placed pixel art, limited 32 color palette, warm amber wooden floor, sage green fridge left, wooden pantry right, farmhouse sink beneath sunny plant window center back wall, stove oven back right with green kettle. Strict orthographic top-down RPG perspective with visible front furniture faces, no isometric diagonal view. All back fixtures occupy upper 35 percent. Central wooden island occupies rectangle x38%-68%, y43%-57%, with small floral green bowl and checked towel, plenty of walking floor around it. Lower 35 percent entirely unobstructed wood floor, doorway bottom right. No characters, pets, lettering, UI, signs, markers, text, chocolate chips. Cozy lived-in home not commercial kitchen. Strong discrete pixel clusters, no blur, gradients, painterly texture. Artwork will be normalized to 320x180 and nearest enlarged. Reference1 kitchen layout; reference2 objects. This is original new environment not edit.
```

## Prompt 2

Local original: `.codex/generated_images/01a12398-aa13-7940-9736-9b23c3038753/exec-3bb0b7fc-24d3-49e8-944d-3a7b43b2334b.png`.

```text
Use case stylized-concept. Original 16:9 pixel-art gameplay background for close-up domestic baking counter. Reference1 is framing/ceramic/checkcloth guidance only; reference2 is warm cozy sink cabinetry guidance. Authentic limited 32-color nostalgic RPG pixel art with crisp block clusters, no smooth gradients or blurry painted rendering, designed at 320x180 enlarged. Large EMPTY honey wood counter fills lower 65 percent. Small checked sage-green towel on far left, utensils in ceramic jar far right, wood cabinets and sunny green plants/sink in upper 30 percent, warm amber light. Leave CENTER working surface completely EMPTY so game renders separate measuring cup/bowl/egg/tray animated objects. No baked cookies, characters, hands, text, labels, arrows, UI, bowl in center or foreground, no chocolate chips. Strict usable neutral background, original art do not copy supplied compositions.
```

## Prompt 3

Local original: `.codex/generated_images/01a12398-aa13-7940-9736-9b23c3038753/exec-b0c968f3-eb4c-43cf-be20-dedc36aae2d8.png`.

```text
Use case stylized-concept. Production transparent-background sprite sheet for cozy 2D nostalgic pixel-art baking game. STRICT exactly FOUR columns by TWO rows uniform equal cells, each object centered with generous transparent margin, consistent orthographic counter perspective and scale. Authentic discrete crisp pixel clusters, 32-color palette, no painterly softness or smooth gradients, intended each sprite about64x48 pixels. NO shadows outside objects, no text labels, no background, no grid lines, no UI, no characters. Top row left to right: cream ceramic mixing bowl with sage green tiny floral motif and EMPTY brown interior; transparent marked measuring cup EMPTY with red graduations; wire whisk with sage green handle; one whole brown egg. Bottom row left to right: EMPTY rectangular silver baking tray with parchment; metal fork with wooden handle; red oven mitt with tiny ochre flower motif; EMPTY metal cooling rack. Objects must fill each cell cleanly isolated actualtransparentRGBA. Reference is prop shapes/style inspiration only. Do NOT include chocolate, cookies, filled dough, hands, extra utensils or other objects.
```

## Prompt 4

Local original: `.codex/generated_images/01a12398-aa13-7940-9736-9b23c3038753/exec-7f128c43-b641-4919-9423-34eece03b377.png`.

```text
Production sprite transparent background, one isolated cream ceramic flour canister with sage-green lid and a small wooden measuring scoop leaning against it. Nostalgic authentic crisp 2D pixel art for a cozy RPG baking counter, deliberately limited 24-color palette, warm amber shading in discrete block clusters, no smooth gradients, no blur, no painterly style. Front three quarter counter perspective, container fills frame, no letters or UI, no backdrop or shadowoutsideobject. Match reference ceramic greens and cozy domestic utensils but create original object. Intended runtime sprite64x80 with nearestneighbor scaling. Actual transparency.
```

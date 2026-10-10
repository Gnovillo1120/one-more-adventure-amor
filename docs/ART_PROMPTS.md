# Dialogue portrait generation

Built-in image generation was used with the couple selfie as a likeness reference. The first smooth concept sheet is preserved externally and is not rendered in the game.

Corrected prompt: Recreate the sixteen portraits as true low-resolution RPG pixel art, not a pixel filter over smooth illustration. Four by four equal cells. Deliberate square pixel clusters, at most 24 opaque colors requested, skin and hair each three tones, no antialiasing, gradients, blur or smooth outlines. Anami has long light-brown hair, glasses and a teal shirt. Guillermo has center-parted dark-brown hair, black jacket and white undershirt, completely clean shaven with no mustache, beard or upper-lip shading. Preserve eight expressions each: neutral, happy, playful, embarrassed, surprised, affectionate, worried, frightened. Transparent backgrounds, generous margins, no decorative hearts or text. No copied commercial portraits.

The production preparation script splits expressions into separate aligned 64x64 PNGs and enforces a common 32-color maximum palette with binary alpha. Godot renders these with nearest-neighbor filtering at integer scales. Source atlas remains preserved under `assets/art/concepts/`; only the prepared portraits are used in dialogue.

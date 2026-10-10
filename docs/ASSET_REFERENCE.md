# Asset reference index

All 27 original reference images remain under `assets/references/`. Their pixels are design references, not finished-game artwork. Original photos and Minecraft screenshots must never be rendered in gameplay or overwritten. Generated artwork and original procedural voxel geometry are separate assets. Import sidecars are not counted as images.

Inspection: all 19 Minecraft PNGs were viewed together in `docs/reference_contact.jpg`; all five JPEGs were viewed individually. The three HEICs were not decoded: no reliable local HEIC decoder was available during this pass. Do not infer their subjects or outfits. Preserve originals and convert copies to PNG/JPEG when a reliable decoder is available. PNG and JPEG need no format conversion for Godot; HEIC requires conversion before direct image import.

## Minecraft screenshots — 20 files

Directory: `assets/references/Minecraft screenshots/`. Filenames below are exact. Material descriptions describe appearance; they do not claim exact block IDs or dimensions. The screenshots constrain recognizable silhouettes and geography, not a complete faithful world extraction.

| File | Format | Visible reference / use |
| --- | --- | --- |
| IMG-20250210-WA0007.jpg | JPEG | Indoor couple selfie, not Minecraft. Guillermo: dark center-parted hair, subtle mustache, blue shirt. Anami: warm smile, brown hair, glasses, blue top. Primary facial/portrait reference. |
| Screenshot 2026-10-09 210014.png | PNG | Wide cherry-blossom valley at sunset; winding water below, terraced grass hills, pagoda on high ground. Overall landscape, pink canopy palette and landmark placement. |
| Screenshot 2026-10-09 210113.png | PNG | Gray cliff face between cherry-covered slopes, dark entrance at its base. Waterfall/cave approach and stepped rock geography. |
| Screenshot 2026-10-09 210141.png | PNG | Long narrow white/quartz-looking corridor, charcoal tiled floor/ceiling, wall torch, orange cat. Hall materials, pet and passage scale. |
| Screenshot 2026-10-09 210203.png | PNG | White hall leading toward stacked storage chests; dark floor, utility blocks on left. Storage/function cues. |
| Screenshot 2026-10-09 210220.png | PNG | Hall side room with storage chests and turquoise armor stands; white pillars and dark ceiling. Utility-room dressing. |
| Screenshot 2026-10-09 210243.png | PNG | Broader white hall with partitioned alcoves, windows/booths and small signs. Trading-hall visual vocabulary; exact signs not transcribed from contact sheet. |
| Screenshot 2026-10-09 210301.png | PNG | Intersecting white partitions and central doorway; pink sign/trim, chests along left. Hall entrance and subdivision. |
| Screenshot 2026-10-09 210336.png | PNG | Garden pond, bamboo, cherry tree, timber pergola/path and pink/dark building beyond. House garden, water and planting. |
| Screenshot 2026-10-09 210358.png | PNG | Garden from another angle, shallow blue water, grass/flowers, timber frames and pink house walls. Garden relationship to house. |
| Screenshot 2026-10-09 210414.png | PNG | Frontal tall steep-gabled house: dark/charcoal framing, pink infill, pale stone base/steps, central doorway and layered windows. Primary recognizable house silhouette. |
| Screenshot 2026-10-09 210430.png | PNG | Side/aerial house: deep red-pink roof slope with dark outline, tall gabled profile, nearby timber paths and cherry hill. Roof pitch and house proportions. |
| Screenshot 2026-10-09 210455.png | PNG | Large glass-fronted stacked green farm with white frame by a ravine/watercourse; pagoda higher on opposite slope. Sugar-cane farm exterior and height relationship. |
| Screenshot 2026-10-09 210517.png | PNG | Frontal tall multi-level glass/white farm, repeated green bands and central dark vertical strip; bridge/wood platform near base. Compact stacked farm reconstruction. |
| Screenshot 2026-10-09 210542.png | PNG | Water spilling down a terraced rock face into a pool amid cherry trees; foreground brown utility/platform structure. Waterfall entrance and pond. |
| Screenshot 2026-10-09 210601.png | PNG | Inside wet cave: blue falling water/right foreground, gray stone, mossy green wall, torch-lit passage. Cave palette and clear waterfall landmark. |
| Screenshot 2026-10-09 210621.png | PNG | Deep excavated rectangular shaft/quarry, circular outline/pattern at bottom, rough stone walls and dark roof. Circular quarry motif; not enough evidence to assert mechanism or history. |
| Screenshot 2026-10-09 210649.png | PNG | Multi-tier pagoda with pale walls, dark wood/roof, pink trim and upturned roof silhouette above cherry-covered landscape. Secondary landmark. |
| Screenshot 2026-10-09 210709.png | PNG | Tall interior with large timber beams, pale walls, wood stairs, orange lattice/trapdoor-like entrance surround. Original warm house interior architecture. |
| Screenshot 2026-10-09 210728.png | PNG | Upper/interior view: wood floor/railings, lantern/chandelier, pale walls, pink decor, furnishings/armor stands. Cozy interior palette and furnishing cues. |

3D mapping: prioritize steep dark/pink house (210414/210430), quartz/charcoal hall (210141–210301), stacked glass sugar farm (210455/210517), water/moss cave (210113/210542/210601), circular quarry detail (210621), pagoda (210014/210649), and cherry valley/pond garden. Iron/mob/crop farm identities are narrative requirements, but these thumbnails do not establish every mechanism. Use compact readable original representations and do not describe unobserved machinery as an accurate reconstruction. The corrupted End and villain are original narrative environments, not claimed screenshot replicas.

## Character photo directory — 4 files

Directory: `assets/references/Photo of Guillermo and Anamiguela/`.

| File | Format | Visible reference / status |
| --- | --- | --- |
| 0bbee391-c4ee-4aa4-932c-3956ca6e3005.jpg | JPEG | Guillermo alone outdoors: dark medium-length center-parted hair, sunglasses, subtle mustache, black jacket over pale shirt; mosaic architecture/city backdrop. No geographic location asserted. Character silhouette and casual clothing reference. |
| IMG_0876.HEIC | HEIC | Not viewed; original preserved. Requires reliable conversion of a copy. |
| IMG_0971.HEIC | HEIC | Not viewed; original preserved. Requires reliable conversion of a copy. |
| IMG_1030.HEIC | HEIC | Not viewed; original preserved. Requires reliable conversion of a copy. |

The supplied written specification additionally establishes Anami's long light-brown hair and Halloween denim dress/red bandana, plus Guillermo's Terminator-inspired Halloween makeup. These outfit facts come from the brief, not unviewed HEIC images.

## UESS Fotos — 3 files

Directory name is `UESS Fotos`; story institution is written UEES as in the supplied narrative.

| File | Format | Visible reference / use |
| --- | --- | --- |
| Debate room layout.jpg | JPEG | Tiered wood desks with black chairs, large front projection screen/podium, warm wood walls, bright ceiling and colored side windows. Use specifically for debate room; photograph is a spatial reference, not proof of MUN year or exact session. |
| Dining hall.jpg | JPEG | Bright banquet-style room, round tables with pale tops/dark skirts, white slender chairs, marble/light floor, buffet and large windows. Use specifically for lunch. |
| Main auditorium where i got handed the diploma.jpg | JPEG | View from lectern/microphone toward steep rows of pale-gray seats, central/side stepped aisles, dark ceiling with linear lights and pale walls. Use specifically for awards, distinct from debate room. |

## Original runtime assets

Generated pixel environments/portraits and original procedural sprites, voxel blocks and music belong in runtime asset directories. Reference contact sheets belong in documentation only. Never import a reference screenshot as a voxel texture or reuse commercial HUD, skins, icons, block textures or character art. Generated design sheets may need cropping/alignment before use; assess actual runtime integration separately from this source inventory.

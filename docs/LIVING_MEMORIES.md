# Living memories

## Reference review

The requested `living_2d` folder is not present; reference images were found under the existing reference tree instead. All are private, ignored by `/assets/references/` and excluded by the export preset. They remain local.

Viewed Salinas pool and aerial club photographs: white open clubhouse, bright rectangular pool, ladders, blue umbrellas, white loungers, palms and marina immediately behind the promenade. These inform a connected pool wing, furnished waterfront seating and club bar without replacing the sunset waterfront painting.

Viewed UEES lobby photograph: bright glass atrium, diagonal stairs, social seating and clear circulation paths. It informs formal delegates, small groups and a recognizable pedestal drinking fountain while preserving the conference and debate layouts.

Viewed bedroom pixel-art reference: warm floor, quilt/cushions, wardrobe, mirror, desk and personal clutter. It informs an explorable preparation room. Reviewed the RPG character and object catalogues for proportions, distinct context poses, costume silhouettes and actual furniture. Reviewed phone UI reference for a framed, clipped conversation with incoming/outgoing bubbles; no stock watermark or interface image is copied.

Current character sheets and yacht/party backgrounds were inspected to preserve brown hair/glasses, Anami's denim dress/red bandana/white sneakers and Guillermo's clean-shaven Terminator costume. New assets use 32×48 character cells at 2× nearest-neighbor display, 64×64 object cells, binary transparency and limited palettes.

Formats present include JPEG/JPG, PNG, WebP, JPEG with `.jfif`, AVIF and an extensionless PNG. They are references, not runtime dependencies. AVIF and HEIC should be converted to PNG/JPEG if ever intentionally imported as game assets; JFIF and extensionless PNG should receive standard extensions. No personal photo conversion is needed for this feature.

## Asset provenance

Built-in image generation produced the original context/NPC/object/clothing atlases, a seated Guillermo atlas and two backgrounds, guided by existing character art. Prompts request crisp limited-palette top-down pixel sprites: phone/drink/sit/swim/dance/surprise/affection/outfit poses; eight distinct delegates, club guests, staff and costumes; sixteen furniture/objects; progressive costume and swimwear poses. Three localized edits remove Guillermo's cheek blush from his walking sheets. A second edit removes blush from the seated poses. Guillermo remains clean-shaven; the Halloween walking sheet keeps its one-eye makeup.

`tools/prepare_living_assets.py` registers baselines, reduces palettes without dithering and scales with nearest sampling. Originals remain in Codex's generated-image directory; generated source copies under `assets/art/concepts/living_*_source.png` make the preparation script reproducible from the repository. The existing `prepare_sprite_atlas.py` prepares Guillermo's corrected 4-direction sheets. Runtime PNGs live under `assets/art/living/` and the existing sprite paths. No reference photo is copied into public art. The AVIF walking reference and JPEG swimming reference were also viewed: staggered footfalls and distinct horizontal strokes guide the animation choice; their characters are not copied.

## Integration contracts

`LivingMemories` adds optional activities and semantic snapshots to the existing `MemoryWorld`, without changing minigame scoring or voxel code. Phone dialogue and activity state use additive chapter checkpoint keys; old saves default safely. NPC routes have independent pauses and speeds, do not block player movement, and consult the same world collision rules. The pool wing constrains walking/swimming separately; changing back is required before returning to the promenade.

## Validation and release

Nine suites pass 2,174 checks, including 89 focused living-activity checks. They cover repeated phone toggles/history replay, activity saves, sitting/drinks, swimwear/water bounds/ladder exits, fountain pause recovery, staged footstep, outfit failure/retry/partial saves, actual sprite changes, party NPC routes, album unlocks and romantic pose restoration. The story reaches credits through 17 scenes and the preserved 3D rescue, with 219 dialogue steps. Existing minigame scoring/data are unchanged.

Native Godot source and Windows export captures verify keyboard P, mouse phone reopening, navigation plus E outfit collection, and pool bounds. They are rendered game screenshots, not asset mockups. The preserved pre-overhaul PCK supplies comparable before views without a checkout reset. See `living/README.md`. Export excludes personal references and concept sources; ZIP CRC and required runtime files are checked by `tools/package_living_release.py`.

Windows executable: `builds/living-2d-memories/One More Adventure Amor.exe`. Matching ZIP: `builds/One More Adventure Amor Living 2D Memories.zip`. Prior releases remain intact.

Limits: the 55 party actors use lightweight patrol/social/dance loops and four costume families plus staff; this suggests a busy party without 100 unique people. Swimming has one stroke set and the pool wing has no independent swimmer AI. Preparation uses a fixed dressing sequence and one wardrobe distractor. Extra dance feedback is playful and nonblocking; Guillermo reuses step frames. Ambient dialogue appears as a brief nonmodal caption rather than voiced chatter. The album stores optional game captures, not historical photos. Formal fountain animation and action transitions can benefit from further artist cleanup. Manual verification used injected native mouse/keyboard events and screenshot inspection; a human pacing pass and lower-end performance tests remain outstanding. Existing letter/music content requirements remain.

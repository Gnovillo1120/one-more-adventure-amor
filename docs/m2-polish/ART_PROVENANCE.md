# Original polish assets

Private photographs were inspected locally. No private reference was supplied to imagegen, copied into generated art, or committed. Local sources: all eight cookie-level PNGs; UESS dining, auditorium and lobby photos; Moncayo and presidency photos; the existing character/pose catalogues. Their environmental structure and observed character features informed original interpretations, not historical reproductions.

Four built-in imagegen requests produced original transparent raster source sheets, retained under `assets/art/concepts/polish_*_source.png` and excluded from export. Prompt summaries:

* Cast: crisp nostalgic top-down pixel RPG, 4 columns × 3 rows, twelve isolated full-body young adults; eight different student hair/skin/clothing silhouettes; a youthful tan man with short curly dark hair, rectangular glasses, subtle beard and navy sweater; a youthful presidency figure with glasses, dark suit and red tie; green-apron catering server; black-waistcoat restaurant waiter. No photos, labels or external sprites.
* Moncayo: the same navy sweater/tan-trouser design, 4 columns × 4 rows; four down-facing walking frames, four left, four right, four back; stable outfit/proportions and alternating feet. No photos supplied. The returned sheet was inspected to confirm that rows retain one direction throughout.
* Menu: six original icons, 2 columns × 3 rows: ceramic green tea, lemonade with ice/lemon/straw, chicken katsu/rice/cabbage, California maki, salmon maki and shoyu ramen. Only the existing original game sushi/ramen icons were provided as style references. No private photographs. All six cells were inspected, then cropped to matching 32×32 runtime icons with a restrained palette.

* Ingredients: nine original open containers in a 3-by-3 sheet, normalized to 64×80: flour bag, white-sugar canister, brown-sugar bag, oat jar, cinnamon jar, baking-soda carton, salt jar, vanilla bottle and butter plate. Only the existing original jar/bowl props were style references. Verified alpha bands preserve the tall vanilla neck; runtime mouth pivots align the pouring stream with each opening.

`tools/normalize_polish_cast.py` performs crops, nearest-neighbor scaling, baseline registration, binary alpha and 24-color normalization. It invents no anatomy. Cast runtime frames are 32×48; portraits are matched 26×26 head/shoulder crops. The Moncayo sheet is 128×192 with 32×48 cells. It replaces the cast’s initial Moncayo frame to maintain one design. Other cast members use subtle code-native lower-leg, seated and hand rigs. They are not sixteen-frame directional atlases.

`meal.svg` and `neutral.svg` are original editable crisp-edge SVG assets. Dining architecture, round tables, ingredient particles, bowl textures and action choreography extend the project’s existing code-native pixel rendering. Existing kitchen raster props remain in use; shell halves are cropped from the actual egg asset. Existing hero sprites/portraits, clean-shaven neutral-cheek Guillermo and Anami’s outfits are preserved.

`cast_review.png`, `moncayo_atlas_review.png` and `ingredient_review.png` are asset review contact sheets, **not** gameplay evidence. Native source/export viewport frames and GIFs are separately recorded in the evidence directories. Generated concept sheets are not evidence of gameplay implementation.

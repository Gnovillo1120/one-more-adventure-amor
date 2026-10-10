"""Normalize generated four-direction atlases into crisp, aligned game sprites.

Usage: python tools/prepare_sprite_atlas.py source.png anami
The original source is preserved; all outputs go to sprites-v2.
"""
from pathlib import Path
import argparse
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "assets/art/sprites-v2"


def prepare(source: Path, name: str, wardrobe=False, outfit="casual"):
    row_count = 8 if wardrobe else 4
    src = Image.open(source).convert("RGBA")
    if src.getextrema()[3][0] == 255:
        raise ValueError("Source has no transparent pixels; regenerate with genuine alpha.")
    # Generated canvases can have unequal outer padding. Locate the four actual
    # sprite bands so neighboring heads never leak into the preceding row.
    mask = src.getchannel("A").point(lambda p: 255 if p >= 160 else 0)
    occupied = []
    for y in range(src.height):
        count = sum(1 for a in mask.crop((0, y, src.width, y + 1)).get_flattened_data() if a)
        if count > max(8, src.width // 100):
            occupied.append(y)
    bands = []
    for y in occupied:
        if not bands or y - bands[-1][1] > 5:
            bands.append([y, y])
        else:
            bands[-1][1] = y
    bands = sorted(sorted(bands, key=lambda b: b[1] - b[0], reverse=True)[:row_count])
    if len(bands) != row_count:
        raise ValueError(f"Could not identify {row_count} separate direction rows.")
    frames = []
    boxes = []
    for row in range(row_count):
        for col in range(4):
            frame = src.crop((round(col * src.width / 4), max(0, bands[row][0] - 2),
                              round((col + 1) * src.width / 4), min(src.height, bands[row][1] + 3)))
            alpha = frame.getchannel("A").point(lambda p: 255 if p >= 160 else 0)
            frame.putalpha(alpha)
            bounds = alpha.getbbox()
            if bounds is None:
                raise ValueError(f"Empty frame {row}, {col}.")
            frames.append(frame.crop(bounds))
            boxes.append(bounds)
    scale = min(26 / max(f.width for f in frames), 38 / max(f.height for f in frames))
    out = Image.new("RGBA", (128, row_count * 48))
    for index, frame in enumerate(frames):
        w, h = max(1, round(frame.width * scale)), max(1, round(frame.height * scale))
        small = frame.resize((w, h), Image.Resampling.NEAREST)
        small = small.crop(small.getchannel("A").getbbox())
        w, h = small.size
        x = (index % 4) * 32 + (32 - w) // 2
        y = (index // 4) * 48 + 46 - h
        out.alpha_composite(small, (x, y))
    outfits = ["formal", "halloween"] if wardrobe else [outfit]
    for index, outfit in enumerate(outfits):
        save_sheet(out.crop((0, index * 192, 128, (index + 1) * 192)), source, name, outfit, scale)


def save_sheet(out, source, name, outfit, scale):
    opaque_colors = [pixel[:3] for pixel in out.get_flattened_data() if pixel[3] > 0]
    training = Image.new("RGB", (len(opaque_colors), 1))
    training.putdata(opaque_colors)
    protected = [(218, 31, 35), (130, 147, 169)] if name == "guillermo" and outfit == "halloween" else []
    palette = training.quantize(colors=24 - len(protected), method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
    if protected:
        entries = palette.getpalette()[:(24 - len(protected)) * 3]
        for color in protected:
            entries.extend(color)
        entries.extend(entries[:3] * ((768 - len(entries)) // 3))
        palette.putpalette(entries)
    rgb = out.convert("RGB").quantize(palette=palette, dither=Image.Dither.NONE).convert("RGB")
    rgb.putalpha(out.getchannel("A"))
    DEST.mkdir(parents=True, exist_ok=True)
    path = DEST / f"{name}_{outfit}.png"
    rgb.save(path)
    preview_suffix = "" if outfit == "casual" else "_" + outfit
    rgb.resize((512, 768), Image.Resampling.NEAREST).save(DEST / f"{name}{preview_suffix}_preview.png")
    colors = {pixel[:3] for pixel in rgb.get_flattened_data() if pixel[3]}
    assert len(colors) <= 24
    assert set(rgb.getchannel("A").get_flattened_data()) <= {0, 255}
    frame_bounds = []
    for row in range(4):
        for col in range(4):
            bounds = rgb.crop((col * 32, row * 48, (col + 1) * 32, (row + 1) * 48)).getchannel("A").getbbox()
            assert bounds is not None and bounds[3] == 46
            frame_bounds.append(bounds)
    report = {"source": str(source), "size": [128, 192], "cell": [32, 48],
              "rows": ["down", "left", "right", "back"],
              "columns": ["idle", "walk_a", "idle", "walk_b"],
              "colors": len(colors), "binary_alpha": True, "baseline": 46,
              "common_scale": scale, "frame_bounds": frame_bounds}
    (DEST / f"{name}{preview_suffix}_validation.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(f"{path}: 16 aligned frames, {len(colors)} opaque colors, binary alpha")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("name", choices=["anami", "guillermo"])
    parser.add_argument("--wardrobe", action="store_true")
    parser.add_argument("--outfit", choices=["casual", "formal", "halloween"], default="casual")
    args = parser.parse_args()
    prepare(args.source, args.name, args.wardrobe, args.outfit)

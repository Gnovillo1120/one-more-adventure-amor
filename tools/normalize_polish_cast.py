"""Crop/normalize accepted original generated art; never reads private photographs."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/art/polish"
OUT.mkdir(exist_ok=True)

def palette(image):
    result = image.convert("RGB").quantize(24).convert("RGBA")
    result.putalpha(image.getchannel("A").point(lambda a: 255 if a >= 128 else 0))
    return result

def cells(path, columns, rows):
    image = Image.open(path).convert("RGBA")
    w, h = image.size
    result = []
    for y in range(rows):
        for x in range(columns):
            cell = image.crop((x*w//columns, y*h//rows, (x+1)*w//columns, (y+1)*h//rows))
            box = cell.getchannel("A").point(lambda a: 255 if a > 100 else 0).getbbox()
            if box is None:
                raise ValueError("Empty generated sprite cell")
            result.append(cell.crop(box))
    return result

for i, cell in enumerate(cells(ROOT / "assets/art/concepts/polish_cast_source.png", 4, 3)):
    cell.thumbnail((30, 46), Image.Resampling.NEAREST)
    frame = Image.new("RGBA", (32, 48))
    frame.alpha_composite(cell, ((32-cell.width)//2, 47-cell.height))
    frame = palette(frame)
    frame.save(OUT / f"cast_{i}.png")
    frame.crop((3, 0, 29, 26)).save(OUT / f"portrait_{i}.png")

frames = cells(ROOT / "assets/art/concepts/polish_moncayo_source.png", 4, 4)
scales = [min(30/max(c.width for c in frames[r*4:r*4+4]), 46/max(c.height for c in frames[r*4:r*4+4])) for r in range(4)]
atlas = Image.new("RGBA", (128, 192))
for i, frame in enumerate(frames):
    scale = scales[i//4]
    frame = frame.resize((round(frame.width*scale), round(frame.height*scale)), Image.Resampling.NEAREST)
    atlas.alpha_composite(palette(frame), ((i%4)*32+(32-frame.width)//2, (i//4)*48+47-frame.height))
atlas.save(OUT / "moncayo_walk.png")
front = atlas.crop((0, 0, 32, 48))
front.save(OUT / "cast_8.png")
front.crop((3, 0, 29, 29)).resize((26, 26), Image.Resampling.NEAREST).save(OUT / "portrait_8.png")
print("Normalized 12 cast sprites, 12 portrait crops and the directional Moncayo atlas.")

for name, cell in zip(["te_verde", "limonada", "katsu", "california", "salmon_roll", "shoyu"], cells(ROOT / "assets/art/concepts/polish_menu_source.png", 2, 3)):
    cell.thumbnail((30, 30), Image.Resampling.NEAREST)
    frame = Image.new("RGBA", (32, 32))
    frame.alpha_composite(cell, ((32-cell.width)//2, 31-cell.height))
    palette(frame).save(OUT / ("menu_"+name+".png"))

# Actual alpha bands avoid cutting the taller vanilla neck at a grid boundary.
import json
source = Image.open(ROOT / "assets/art/concepts/polish_ingredients_source.png").convert("RGBA")
bands = [[(65,520),(540,935),(975,1320)],[(95,520),(565,930),(935,1320)],[(90,525),(530,940),(1000,1310)]]
ids = ["flour","white_sugar","brown_sugar","oats","cinnamon","soda","salt","vanilla","butter"]
metadata = {}
review = Image.new("RGBA", (384,480), "#57443c")
for i, name in enumerate(ids):
    col,row=i%3,i//3
    y0,y1=bands[col][row]
    cell=source.crop((col*source.width//3,y0,(col+1)*source.width//3,y1))
    box=cell.getchannel("A").point(lambda a:255 if a>100 else 0).getbbox()
    cell=cell.crop(box)
    cell.thumbnail((44,60) if name in ["cinnamon","soda","salt"] else (60,76),Image.Resampling.NEAREST)
    frame=Image.new("RGBA",(64,80)); left=(64-cell.width)//2; top=79-cell.height
    frame.alpha_composite(cell,(left,top)); frame=palette(frame)
    frame.save(OUT / ("ingredient_"+name+".png"))
    mouth=[32, top+max(2,round(cell.height*(.19 if name in ["flour","brown_sugar","soda"] else .10)))]
    if name=="vanilla":mouth=[32,top+2]
    if name=="butter":mouth=[left+cell.width-6,top+8]
    metadata[name]={"art":"res://assets/art/polish/ingredient_"+name+".png","mouth":mouth}
    review.alpha_composite(frame.resize((128,160),Image.Resampling.NEAREST),(col*128,row*160))
(ROOT/"data/baking_containers.json").write_text(json.dumps(metadata,indent=2)+"\n")
review.convert("RGB").save(ROOT/"docs/m2-polish/ingredient_review.png")

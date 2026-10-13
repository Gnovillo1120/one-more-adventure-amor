"""Register generated replacement animations; no personal photographs are read."""
from pathlib import Path
from PIL import Image
import json
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/art/living'
def prepare(name, rows, cell, row_bounds, col_bounds):
    src=Image.open(ROOT/'assets/art/concepts'/name).convert('RGBA')
    frames=[]
    for row in range(rows):
        for col in range(4):
            frame=src.crop((col_bounds[col],row_bounds[row],col_bounds[col+1],row_bounds[row+1]))
            frame.putalpha(frame.getchannel('A').point(lambda a:255 if a>=160 else 0))
            box=frame.getchannel('A').getbbox()
            assert box is not None
            frames.append(frame.crop(box))
    scale=min((cell[0]-4)/max(f.width for f in frames),(cell[1]-4)/max(f.height for f in frames))
    sheet=Image.new('RGBA',(cell[0]*4,cell[1]*rows))
    for i,frame in enumerate(frames):
        frame=frame.resize((round(frame.width*scale),round(frame.height*scale)),Image.Resampling.NEAREST)
        rgb=frame.convert('RGB').quantize(colors=24,dither=Image.Dither.NONE).convert('RGB')
        rgb.putalpha(frame.getchannel('A'))
        # Same baseline and scale for all directions; water poses float above feet.
        y=cell[1]-2-rgb.height if cell[0]==32 or i//4==5 else (cell[1]-rgb.height)//2
        sheet.alpha_composite(rgb,((i%4)*cell[0]+(cell[0]-rgb.width)//2,(i//4)*cell[1]+y))
    return sheet
prepare('animation_swimwear_source.png',4,(32,48),[0,318,629,938,1278],[0,307,615,922,1230]).save(OUT/'anami_swimwear.png')
prepare('animation_swimming_source.png',6,(48,48),[0,292,507,727,990,1188,1536],[0,282,517,780,1024]).save(OUT/'anami_swimming.png')
metadata=json.loads((OUT/'atlas.json').read_text())
metadata['swimwear']={'cell':[32,48],'rows':['down','left','right','up'],'columns':['idle','step_a','passing','step_b']}
metadata['swimming']={'cell':[48,48],'rows':['swim_down','swim_left','swim_right','swim_up','swim_idle','ladder'],'columns':4,'exit':'reverse ladder frames'}
(OUT/'atlas.json').write_text(json.dumps(metadata,indent=2))
print('Prepared coherent four-direction walking and swimming atlases')

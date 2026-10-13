"""Assemble a review GIF from unaltered Godot viewport crops, not asset artwork."""
from pathlib import Path
from PIL import Image, ImageDraw
import json
import sys
folder=Path(sys.argv[1])
walk=Image.open(folder/'walk_directions.png').convert('RGB')
swim=Image.open(folder/'swim_directions.png').convert('RGB')
frames=[]
for frame in range(8):
    canvas=Image.new('RGB',(390,720),'#182b38')
    draw=ImageDraw.Draw(canvas)
    draw.text((88,10),'LAND / SWIMWEAR',fill='white')
    draw.text((245,10),'SWIMMING',fill='white')
    for row,direction in enumerate(['DOWN','LEFT','RIGHT','UP']):
        draw.text((5,95+row*170),direction,fill='#ffe0af')
        for column,sheet in enumerate([walk,swim]):
            canvas.paste(sheet.crop((frame*140,row*170,(frame+1)*140,(row+1)*170)),(80+column*155,35+row*170))
    frames.append(canvas)
frames[0].save(folder/'four_directions.gif',save_all=True,append_images=frames[1:],duration=100,loop=0)
data=json.loads((folder/'frames.json').read_text())
for mode in ['walk','swim']:
    for direction in range(4):
        samples=[f for f in data if f['mode']==mode and f['direction']==direction]
        assert len(samples)==8 and {f['row'] for f in samples}=={direction}
        assert len({f['frame'] for f in samples})>=3
        assert samples[0]['position']!=samples[-1]['position']
print('64 rendered movement samples: correct rows, changing frames, actual movement; GIF assembled')

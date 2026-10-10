"""Split generated atlas into separate, palette-limited 64px portrait assets.
User explicitly requested programmatic cropping, frame alignment and pixel cleanup.
No reference photographs are included in output assets.
"""
from pathlib import Path
from PIL import Image
import argparse

p=argparse.ArgumentParser()
p.add_argument('source');p.add_argument('--outfit',default='casual')
a=p.parse_args()
root=Path(__file__).resolve().parents[1]
out=root/'assets/art/portraits';out.mkdir(parents=True,exist_ok=True)
source=Image.open(a.source).convert('RGBA')
expressions=['neutral','happy','playful','embarrassed','surprised','affectionate','worried','frightened']
palette_source=source.convert('RGB').quantize(colors=32,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE)
palette=palette_source.getpalette()
palette_image=Image.new('P',(1,1));palette_image.putpalette(palette)
for person_index,person in enumerate(['anami','guillermo']):
    for i,expression in enumerate(expressions):
        col=i%4;row=person_index*2+i//4
        cell=source.crop((round(col*source.width/4),round(row*source.height/4),round((col+1)*source.width/4),round((row+1)*source.height/4)))
        cell=cell.resize((64,64),Image.Resampling.NEAREST)
        rgb=cell.convert('RGB').quantize(palette=palette_image,dither=Image.Dither.NONE).convert('RGBA')
        alpha=cell.getchannel('A').point(lambda v:255 if v>=128 else 0)
        rgb.putalpha(alpha)
        name=f'{person}_{expression}' + ('' if a.outfit=='casual' else '_'+a.outfit)
        rgb.save(out/(name+'.png'))
print(f'Prepared 16 {a.outfit} portraits: 64x64, <=32 colors, binary alpha.')

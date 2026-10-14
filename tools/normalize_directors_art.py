"""Crop generated raster assets; nearest sampling and bounded palettes only."""
from pathlib import Path
from PIL import Image
import argparse
r=Path(__file__).resolve().parents[1]
out=r/'assets/art/directors';out.mkdir(parents=True,exist_ok=True)
source=Path('C:/Users/gsnov/.codex/generated_images/01a12398-aa13-7940-9736-9b23c3038753')
room=Image.open(source/'exec-3b22891d-d408-4991-be16-831198ccce21.png').convert('RGB')
room=room.resize((640,360),Image.Resampling.NEAREST).quantize(colors=128).convert('RGB').resize((1280,720),Image.Resampling.NEAREST)
room.save(out/'memory_room.png')
atlas=Image.open(source/'exec-00fc8016-ca0d-4e0d-b3cf-0421aedfdb31.png').convert('RGBA')
def sprite(image,path):
    bbox=image.getbbox();assert bbox
    image=image.crop(bbox)
    image.thumbnail((96,96),Image.Resampling.NEAREST)
    image=image.quantize(colors=48,method=Image.Quantize.FASTOCTREE).convert('RGBA')
    canvas=Image.new('RGBA',(112,112));canvas.alpha_composite(image,((112-image.width)//2,(112-image.height)//2));canvas.save(out/(path+'.png'))
for x,y,name in [(0,0,'book_closed'),(1,0,'book_open'),(0,1,'recipe_card'),(2,1,'locked_photo')]:
    sprite(atlas.crop((x*atlas.width//4,y*atlas.height//2,(x+1)*atlas.width//4,(y+1)*atlas.height//2)),name)
parser=argparse.ArgumentParser();parser.add_argument('--keepsakes');args=parser.parse_args()
if args.keepsakes:
    atlas=Image.open(args.keepsakes).convert('RGBA')
    for i,name in enumerate(['box_closed','box_open','yoda_keychain','a_necklace','first_photo','mun_diploma']):
        x=i%3;y=i//3
        sprite(atlas.crop((x*atlas.width//3,y*atlas.height//2,(x+1)*atlas.width//3,(y+1)*atlas.height//2)),name)
print('Normalized runtime art:',', '.join(p.name for p in out.glob('*.png')))

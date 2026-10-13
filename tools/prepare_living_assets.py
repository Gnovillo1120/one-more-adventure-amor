"""Normalize generated atlases to registered, binary-alpha pixel game assets.
Never reads personal reference photos. Originals remain untouched.
"""
from pathlib import Path
from PIL import Image
import json
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/art/living';OUT.mkdir(parents=True,exist_ok=True)
SOURCE=ROOT/'assets/art/concepts'
SOURCES={
 'exec-faa1c46c-471f-416a-9db6-87ae6a7f32a1.png':'living_anami_actions_source.png',
 'exec-1886df67-ad2c-4ea7-87ac-f28a51261d8c.png':'living_people_source.png',
 'exec-0270f52e-5c3f-4145-a1d2-ddbc8f369f01.png':'living_objects_source.png',
 'exec-291d2c73-b1ff-4b94-8ef7-ee7c1ab7eaa0.png':'living_anami_outfits_source.png',
 'exec-410f332d-91a4-4925-a9e9-cc74366fcdbb.png':'living_guillermo_affection_source.png',
 'exec-e7e29e55-4d42-4adf-98b0-ff5f71f60888.png':'living_bedroom_source.png',
 'exec-1f3d7898-a5bc-4a11-9731-10ceeabb1abd.png':'living_club_pool_source.png'}
def atlas(filename,rows,cell,bounds=None,columns=None,fit=None):
    src=Image.open(SOURCE/SOURCES[filename]).convert('RGBA');frames=[]
    for row in range(rows):
        for col in range(4):
            f=src.crop((columns[col] if columns else col*src.width//4,bounds[row] if bounds else row*src.height//rows,columns[col+1] if columns else (col+1)*src.width//4,bounds[row+1] if bounds else (row+1)*src.height//rows))
            f.putalpha(f.getchannel('A').point(lambda a:255 if a>=160 else 0))
            box=f.getchannel('A').getbbox();assert box is not None
            frames.append(f.crop(box))
    sheet=Image.new('RGBA',(cell[0]*4,cell[1]*rows))
    for i,f in enumerate(frames):
        group=frames[(i//4)*4:(i//4+1)*4]
        dimensions=fit or (cell[0]-4,cell[1]-4)
        scale=min(dimensions[0]/max(g.width for g in group),dimensions[1]/max(g.height for g in group))
        small=f.resize((max(1,round(f.width*scale)),max(1,round(f.height*scale))),Image.Resampling.NEAREST)
        rgb=small.convert('RGB').quantize(colors=24,dither=Image.Dither.NONE).convert('RGB');rgb.putalpha(small.getchannel('A'))
        sheet.alpha_composite(rgb,((i%4)*cell[0]+(cell[0]-rgb.width)//2,(i//4)*cell[1]+cell[1]-2-rgb.height))
    return sheet
atlas('exec-faa1c46c-471f-416a-9db6-87ae6a7f32a1.png',8,(32,48),[0,213,416,615,767,982,1170,1332,1536],[0,272,502,746,1024]).save(OUT/'anami_actions.png')
atlas('exec-1886df67-ad2c-4ea7-87ac-f28a51261d8c.png',8,(32,48),[0,210,400,593,784,986,1156,1340,1536],[145,325,510,695,890]).save(OUT/'ambient_people.png')
extra=atlas('exec-291d2c73-b1ff-4b94-8ef7-ee7c1ab7eaa0.png',7,(32,48),[0,232,434,644,848,1060,1270,1536])
swim=Image.new('RGBA',(128,192))
for row in range(3):swim.alpha_composite(extra.crop((0,row*48,128,(row+1)*48)),(0,row*48))
for col in range(4):swim.alpha_composite(extra.crop((96,96,128,144)),(col*32,144))
swim.save(OUT/'anami_swimwear.png')
extra.crop((0,144,128,288)).save(OUT/'anami_outfits.png')
extra.crop((0,288,128,336)).save(OUT/'anami_fountain.png')
atlas('exec-410f332d-91a4-4925-a9e9-cc74366fcdbb.png',1,(32,48),fit=(28,34)).save(OUT/'guillermo_affection.png')
objects=atlas('exec-0270f52e-5c3f-4145-a1d2-ddbc8f369f01.png',4,(64,64))
names=['fountain','fountain_flow','bench','phone','bar','drink','changing_room','ladder','lounger','umbrella','bed','wardrobe','mirror','desk','dress','sneakers']
for i,name in enumerate(names):objects.crop(((i%4)*64,(i//4)*64,(i%4+1)*64,(i//4+1)*64)).save(OUT/(name+'.png'))
(OUT/'atlas.json').write_text(json.dumps({'cell':[32,48],'columns':4,'actions':['phone','drink','sit','swim','dance','surprise','affection','outfit'],'npcs':['delegate_woman','delegate_man','club_guest','bartender','witch','ghost','vampire','pirate'],'objects':names},indent=2))
for filename,name in [('exec-e7e29e55-4d42-4adf-98b0-ff5f71f60888.png','bedroom'),('exec-1f3d7898-a5bc-4a11-9731-10ceeabb1abd.png','club_pool')]:
    Image.open(SOURCE/SOURCES[filename]).convert('RGB').resize((1280,720),Image.Resampling.NEAREST).save(OUT/(name+'.png'))
print('Prepared 64 character frames and 16 object sprites, registered baseline, binary alpha')
if (SOURCE/'animation_swimwear_source.png').exists():
    # Apply the focused animation correction after the historical asset pipeline.
    import runpy
    runpy.run_path(str(ROOT/'tools/prepare_animation_assets.py'))

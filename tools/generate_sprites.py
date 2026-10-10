"""Original pixel sprites. 32x48 cells; columns idle/walk A/center/walk B;
rows down/left/right/up. No source photograph pixels are reused."""
from pathlib import Path
from PIL import Image, ImageDraw
OUT=Path('assets/art/sprites'); OUT.mkdir(parents=True,exist_ok=True)
PAL={'outline':'#302c46','skin':'#eac097','shade':'#c58970','hair_g':'#674938','hair_a':'#9b704e','hair_light':'#bb8a5e','teal':'#559c9b','lavender':'#b2a5d1','amber':'#e7b775','red':'#b45360','denim':'#557a99','dark':'#42455f','cream':'#f1e5c6'}
def frame(person,outfit,direction,phase):
    im=Image.new('RGBA',(32,48)); d=ImageDraw.Draw(im)
    def box(rect,c): d.rectangle(rect,fill=PAL.get(c,c))
    hair='hair_a' if person=='anami' else 'hair_g'
    bob=1 if phase in (1,3) else 0
    y=7+bob
    # Long hair silhouette, asymmetric side silhouettes for profile directions.
    box((9,y,22,y+13),'outline'); box((10,y,21,y+12),hair)
    if person=='anami':
        box((8,y+6,11,y+25),hair); box((21,y+6,24,y+25),hair)
        box((9,y+11,10,y+24),'hair_light')
    if direction!=3:
        box((11,y+5,20,y+13),'skin'); box((12,y+14,19,y+15),'shade')
        box((10,y+3,21,y+5),hair)
        if person=='guillermo':
            box((15,y,16,y+4),'skin')
        else: box((10,y+1,20,y+3),'hair_light')
        if direction==0:
            box((12,y+8,13,y+9),'outline'); box((18,y+8,19,y+9),'outline')
        elif direction==1: box((11,y+8,12,y+9),'outline'); box((10,y+10,11,y+11),'skin')
        else: box((19,y+8,20,y+9),'outline'); box((20,y+10,21,y+11),'skin')
    else: box((11,y+2,20,y+12),hair)
    color='lavender' if person=='anami' else 'teal'
    if outfit=='formal': color='cream' if person=='anami' else 'dark'
    if outfit=='halloween': color='denim' if person=='anami' else 'dark'
    box((10,y+17,21,y+29),'outline'); box((11,y+17,20,y+28),color)
    box((8,y+19,10,y+28),color); box((21,y+19,23,y+28),color)
    box((8,y+29,10,y+31),'skin'); box((21,y+29,23,y+31),'skin')
    if person=='anami': box((9,y+27,22,y+32),color)
    if outfit=='formal' and person=='guillermo': box((15,y+18,16,y+25),'amber')
    if outfit=='halloween' and person=='anami':
        box((10,y+3,21,y+5),'red'); box((20,y+1,24,y+3),'red'); box((22,y+4,24,y+6),'red')
    if outfit=='halloween' and person=='guillermo' and direction!=3:
        box((18,y+7,20,y+11),'shade'); box((19,y+8,20,y+8),'red')
    left=1 if phase==1 else (-1 if phase==3 else 0)
    box((11,y+33,14,y+37+left),'dark'); box((17,y+33,20,y+37-left),'dark')
    box((10,y+38+left,14,y+40+left),'outline'); box((17,y+38-left,21,y+40-left),'outline')
    return im
for person in ['anami','guillermo']:
    for outfit in ['casual','formal','halloween']:
        sheet=Image.new('RGBA',(128,192))
        for row in range(4):
            for col in range(4): sheet.paste(frame(person,outfit,row,col),(col*32,row*48))
        sheet.save(OUT/f'{person}_{outfit}.png')
for name in ['diploma','gyoza','bandana','cookie','sword','fish']:
    im=Image.new('RGBA',(32,32)); d=ImageDraw.Draw(im)
    if name=='diploma':
        d.rectangle((5,9,26,23),fill=PAL['cream'],outline=PAL['outline'],width=2); d.rectangle((15,9,18,23),fill=PAL['red'])
    elif name=='gyoza':
        d.polygon([(4,22),(7,12),(14,8),(22,10),(28,22)],fill=PAL['cream'],outline=PAL['outline']);
        for x in [9,14,19,24]: d.line((x,12,x-2,19),fill=PAL['amber'],width=2)
    elif name=='bandana': d.polygon([(4,8),(28,8),(16,27)],fill=PAL['red'],outline=PAL['outline'])
    elif name=='cookie':
        d.ellipse((4,4,27,27),fill=PAL['amber'],outline=PAL['outline'],width=2)
        for x,y in [(10,10),(20,9),(16,16),(9,21),(23,20)]: d.rectangle((x,y,x+2,y+2),fill=PAL['hair_g'])
    elif name=='sword':
        d.polygon([(24,3),(27,7),(14,22),(10,18)],fill='#bad8dd',outline=PAL['outline']); d.line((8,15,18,25),fill=PAL['amber'],width=3); d.line((12,21,5,28),fill=PAL['hair_g'],width=4)
    else:
        d.ellipse((4,10,23,23),fill=PAL['teal'],outline=PAL['outline']); d.polygon([(22,16),(29,9),(29,24)],fill=PAL['teal']); d.rectangle((8,14,9,15),fill=PAL['outline'])
    im.save(OUT/(name+'.png'))
print('Generated six 128x192 character sheets and six 32x32 keepsake icons')

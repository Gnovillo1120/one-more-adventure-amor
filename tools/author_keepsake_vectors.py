"""Author transparent, integer-grid SVG game sprites (no raster editing).

The image service rejected the item atlas; these small icons are native vector
assets with square pixel shapes, a limited palette and exact 2x import dimensions.
"""
from pathlib import Path
import json
r=Path(__file__).resolve().parents[1];out=r/'assets/art/directors'
INK='#342c32';GOLD='#d4a647';LIGHT='#f4d779';GREEN='#86a75e';DARK='#557345';BROWN='#836448';CREAM='#ead4a7'
def rect(x,y,w,h,c):return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{c}"/>'
def panel(x,y,w,h,c):return rect(x,y,w,h,INK)+rect(x+1,y+1,w-2,h-2,c)
def sage(x,y):
    return ''.join([rect(x+2,y,6,1,'#a5acaf'),rect(x+1,y+1,1,4,'#a5acaf'),rect(x+8,y+1,1,4,'#a5acaf'),rect(x+2,y+5,6,1,'#a5acaf'),rect(x+4,y+6,2,3,'#c6d0cf'),rect(x-4,y+11,18,3,INK),rect(x-3,y+12,16,1,GREEN),panel(x,y+9,10,9,GREEN),rect(x+1,y+10,8,2,'#abc877'),rect(x+2,y+13,1,2,INK),rect(x+7,y+13,1,2,INK),rect(x+4,y+16,3,1,DARK),panel(x,y+18,10,12,BROWN),rect(x+4,y+19,2,9,CREAM),rect(x+1,y+28,8,2,'#a48361'),rect(x+1,y+30,3,3,INK),rect(x+6,y+30,3,3,INK)])
def robot(x,y):
    return panel(x,y,9,16,'#dbded9')+rect(x+1,y+1,7,3,'#708b9b')+rect(x+3,y+2,3,2,'#3e607c')+rect(x+2,y+7,5,2,'#3e607c')+rect(x+3,y+10,3,4,'#6f9fba')+rect(x-2,y+7,2,11,'#cccfc9')+rect(x+9,y+7,2,11,'#cccfc9')
def knight(x,y):
    return rect(x,y+3,11,15,INK)+rect(x+2,y,7,10,'#242733')+rect(x+3,y+1,5,2,'#454957')+rect(x+3,y+5,2,1,'#727783')+rect(x+7,y+5,2,1,'#727783')+rect(x+4,y+12,3,3,'#727783')+rect(x+5,y+12,1,1,'#af674c')
def box(opened):
    s=panel(9,28,38,20,'#90663f')+rect(10,30,36,3,'#b9854c')+rect(10,43,36,2,'#6c4a36')+panel(24,36,8,6,GOLD)+rect(27,38,2,2,INK)
    if opened:
        s=panel(9,5,38,17,'#ac7d4c')+rect(12,8,32,10,'#795237')+panel(9,21,38,15,'#51413b')+s
        s+=panel(14,23,6,11,'#dbded9')+rect(15,24,4,2,'#6f9fba')+rect(16,28,2,4,'#3e607c')
        s+=rect(24,24,7,11,INK)+rect(25,22,5,7,'#242733')+rect(26,25,3,1,'#727783')+rect(26,31,2,2,'#727783')
        s+=rect(37,18,3,1,'#c6d0cf')+rect(36,19,1,3,'#c6d0cf')+rect(40,19,1,3,'#c6d0cf')+rect(37,22,3,1,'#c6d0cf')+rect(38,23,1,2,'#c6d0cf')
        s+=rect(32,27,13,2,DARK)+panel(35,25,7,6,GREEN)+rect(37,27,1,1,INK)+rect(40,27,1,1,INK)+panel(35,31,7,8,BROWN)+rect(38,32,1,5,CREAM)
        s+=rect(37,17,1,3,LIGHT)+rect(35,18,5,1,LIGHT)
    else:s+=panel(8,16,40,15,'#b4824c')+rect(10,18,36,2,'#d49d5d')+rect(10,28,36,2,'#6c4a36')
    return s
def necklace():
    coords=[(14,8),(12,10),(11,13),(10,16),(10,19),(11,22),(12,25),(14,28),(17,30),(20,32),(23,33),(28,33),(31,32),(34,30),(37,28),(39,25),(40,22),(41,19),(41,16),(40,13),(39,10),(37,8)]
    s=''.join(rect(x,y,2,2,GOLD)+rect(x,y,1,1,LIGHT) for x,y in coords)
    s+=rect(24,34,4,2,GOLD)+rect(25,35,2,2,LIGHT)
    for y,row in enumerate(['0011100','0110110','1100011','1100011','1111111','1100011','1100011']):
        for x,pixel in enumerate(row):
            if pixel=='1':s+=rect(23+x,38+y,1,1,LIGHT if y==0 else GOLD)
    s+=rect(40,15,1,5,'#fff0b0')+rect(38,17,5,1,'#fff0b0')
    return s
def photograph():
    s=panel(7,4,42,48,CREAM)+rect(11,8,34,33,'#73818a')+rect(11,8,34,9,'#97a3a4')
    s+=rect(16,31,25,10,'#252b35')+rect(20,28,17,10,'#303b43')+rect(26,28,6,5,'#cd916a')
    s+=rect(20,17,18,12,'#d4a17a')+rect(22,14,16,14,'#e2b288')+rect(24,27,11,3,'#d4a17a')
    s+=rect(18,15,4,8,'#674830')+rect(20,11,16,6,'#593c2d')+rect(24,9,14,4,'#745032')+rect(19,13,11,4,'#875c36')+rect(30,12,9,6,'#674830')+rect(36,17,3,5,'#674830')
    s+=rect(24,20,3,1,INK)+rect(33,20,3,1,INK)+rect(25,21,1,2,INK)+rect(33,21,1,2,INK)+rect(29,25,3,1,'#8f674b')
    s+=rect(12,44,17,1,'#ac9779')+rect(12,47,29,1,'#ac9779')
    return s
def diploma():
    s=panel(3,10,50,33,CREAM)+rect(6,13,44,1,GOLD)+rect(6,39,44,1,GOLD)+rect(6,14,1,25,GOLD)+rect(49,14,1,25,GOLD)
    s+=rect(14,17,28,2,'#75685f')+rect(11,22,34,1,'#ab9580')+rect(14,25,28,1,'#ab9580')+rect(18,28,20,1,'#ab9580')
    s+=rect(25,31,7,7,GOLD)+rect(24,32,9,5,GOLD)+rect(27,32,3,4,LIGHT)+rect(25,38,3,9,'#456379')+rect(29,38,3,9,'#456379')
    return s
for name,body in [('box_closed',box(False)),('box_open',box(True)),('yoda_keychain',sage(23,9)),('a_necklace',necklace()),('first_photo',photograph()),('mun_diploma',diploma())]:
    (out/(name+'.svg')).write_text('<svg xmlns="http://www.w3.org/2000/svg" width="112" height="112" viewBox="0 0 56 56" shape-rendering="crispEdges">'+body+'</svg>\n',encoding='utf-8')
p=r/'data/directors_cut.json';data=json.loads(p.read_text(encoding='utf-8'))
names=['box_closed','box_open','yoda_keychain','a_necklace','first_photo','mun_diploma']
for entry in data['keepsakes']:
    if entry['id']!='oatmeal_recipe':entry['art']=entry['art'].replace('.png','.svg')
p.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
for p in [r/'scripts/directors_cut.gd',r/'scripts/voxel_world.gd']:
    s=p.read_text(encoding='utf-8')
    for name in names:s=s.replace(name+'.png',name+'.svg')
    if p.name=='voxel_world.gd':s=s.replace('"res://assets/art/directors/%s.png" % ["mun_diploma","first_photo","yoda_keychain","recipe_card"][int(key.trim_prefix("memory"))]','"res://assets/art/directors/%s" % ["mun_diploma.svg","first_photo.svg","yoda_keychain.svg","recipe_card.png"][int(key.trim_prefix("memory"))]')
    p.write_text(s,encoding='utf-8')
print('Six authored SVG assets saved')

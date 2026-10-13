"""Assemble only actual Godot viewport captures; never concept-art proof."""
from pathlib import Path
from PIL import Image
import json
r=Path(__file__).resolve().parents[1]/'docs/directors'
for build in ['source','export']:
    p=r/build
    if (p/'proof.json').exists():
        proof=json.loads((p/'proof.json').read_text(encoding='utf-8'));assert proof['native_walk_ok'] and proof['native_e_book_ok'] and proof['capture_complete']
    for prefix in ['intro','page']:
        frames=[Image.open(f).convert('RGB').resize((640,360),Image.Resampling.NEAREST) for f in sorted(p.glob(prefix+'_*.png'))]
        if not frames:continue
        assert len(frames)>=8
        assert len({f.tobytes() for f in frames})>2,'Animation evidence must contain distinct rendered frames'
        frames[0].save(p/(prefix+'.gif'),save_all=True,append_images=frames[1:],duration=390 if prefix=='intro' else 350,loop=0)
    frames=[Image.open(p/f).convert('RGB').resize((640,360),Image.Resampling.NEAREST) for f in ['03_yoda_closed.png','04_yoda_box_open.png','05_yoda_keychain.png'] if (p/f).exists()]
    if len(frames)==3:frames[0].save(p/'yoda_box.gif',save_all=True,append_images=frames[1:],duration=[700,1300,1300],loop=0)
    if (p/'02_hub.png').exists():
        names=['02_hub.png','05_yoda_keychain.png','keepsake_1.png','keepsake_2.png']
        sheet=Image.new('RGB',(1280,720))
        for i,name in enumerate(names):sheet.paste(Image.open(p/name).resize((640,360),Image.Resampling.NEAREST),((i%2)*640,(i//2)*360))
        sheet.save(p/'overview.png')
print('Rendered-frame evidence assembled')

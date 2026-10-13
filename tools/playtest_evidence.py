"""Build before/after comparisons and action GIFs from actual viewport captures."""
from pathlib import Path
from PIL import Image
import json
r=Path(__file__).resolve().parents[1]/'docs/playtest'
for build in ['source','export']:
    p=r/build
    if not (p/'proof.json').exists():continue
    proof=json.loads((p/'proof.json').read_text(encoding='utf-8'));assert proof['native_photo_unlocked'] and proof['card_interaction'] and proof['complete']
    assert [proof['pose_'+str(t)]['frame'] for t in [12,45,90,132,180]]==[0,1,2,3,4]
    assert not proof['pose_90']['unlocked'] and proof['pose_132']['unlocked'] and not proof['pose_229']['busy']
    for name in ['02_lobby_after_room','03_document_prompt','07_beach_card','quiz_4','quiz_8']:
        before=Image.open(r/'before'/f'{name}.png').convert('RGB').resize((640,360),Image.Resampling.NEAREST)
        after=Image.open(p/f'{name}.png').convert('RGB').resize((640,360),Image.Resampling.NEAREST)
        sheet=Image.new('RGB',(1280,360));sheet.paste(before,(0,0));sheet.paste(after,(640,0));sheet.save(p/(name+'_comparison.png'))
    frames=[Image.open(p/('photo_'+str(t)+'.png')).convert('RGB') for t in [12,45,90,132,180,229]]
    # Both full environment focus and close-up authored pose evidence.
    for close in [False,True]:
        images=[f.crop((950,460,1095,610)).resize((580,600),Image.Resampling.NEAREST) if close else f.resize((640,360),Image.Resampling.NEAREST) for f in frames]
        images[0].save(p/('photo_close.gif' if close else 'photo.gif'),save_all=True,append_images=images[1:],duration=[330,450,420,480,490,650],loop=0)
print('Real viewport comparisons and photography GIFs assembled')

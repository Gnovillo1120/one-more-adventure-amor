"""Package the validated release separately from the PRIVATE local music overlay."""
from pathlib import Path
import hashlib
import json
import re
import shutil
import zipfile
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
proof=ROOT/'docs/final-music-letter'
public=ROOT/'builds/final-music-letter'
local=ROOT/'builds/final-music-letter-local'
pack=public/'One More Adventure Amor.pck'
manifest=json.loads((ROOT/'data/audio_tracks.json').read_text(encoding='utf-8'))
integrity=json.loads((ROOT/'data/final_letter_integrity.json').read_text(encoding='utf-8'))
story=json.loads((ROOT/'data/story.json').read_text(encoding='utf-8'))

def require(ok,reason):
    if not ok:raise RuntimeError(reason)

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()

letter='\n\n'.join(story['personal_letter']['paragraphs'])
require(hashlib.sha256(letter.encode('utf-8')).hexdigest()==integrity['sha256_utf8'],'Letter differs from supplied text')
require(story['chapters'][5]['scenes'][1]['lines'][0]['text']==letter,'Scene letter differs')
results={}
for folder,without in [('source',False),('windows',False),('windows-without-music',True)]:
    path=proof/folder/'FINAL_INTEGRATION_TRACE.json'
    trace=json.loads(path.read_text(encoding='utf-8'))
    require(trace['failures']==0 and trace['without_recordings']==without,'Integration failure: '+folder)
    require(trace['letter_sha256']==integrity['sha256_utf8'],'Runtime letter mismatch')
    require(len(trace['tracks'])==11 and all(t['available']!=without for t in trace['tracks']),'Missing soundtrack coverage')
    if not without:require(all(t.get('mixer_peak',0)>0 for t in trace['tracks']),'Actual mixer output missing')
    if folder!='source':require(path.stat().st_mtime>pack.stat().st_mtime,'Windows evidence predates PCK')
    require(any(e.get('physical_key')=='E' and e.get('pressed') for e in trace['events']),'No real E events')
    results[folder]={'checks':trace['checks'],'failures':0,'tracks':len(trace['tracks']),'without_recordings':without}
headless={}
for path in sorted((proof/'qa').glob('*_test.log')):
    text=path.read_text(encoding='utf-8-sig',errors='replace')
    m=re.findall(r'([A-Z0-9_]+_QA):\s*(\d+) checks;\s*(\d+) failures',text)
    require(m and int(m[-1][2])==0 and 'SCRIPT ERROR' not in text,'Failed suite: '+path.stem)
    headless[path.stem]={'checks':int(m[-1][1]),'failures':0}
require(len(headless)==15,'All fifteen existing suites required')

credits='# Soundtrack credits and distribution\n\nMusic selected and supplied by Guillermo. Artist, title, source and license metadata were absent from the recordings. No authorship or redistribution rights are claimed. This distributable intentionally contains no supplied recordings. The separate local-only overlay is for private use until the necessary rights and attribution are established.\n\n'
credits+='\n'.join(f'- `{c["original_filename"]}` → `{c["file"]}`: {c["scene"]}.' for c in manifest['tracks'].values())+'\n'
(public/'music').mkdir(exist_ok=True)
(public/'music/CREDITS.md').write_text(credits,encoding='utf-8')
(public/'music/SOUNDTRACK_MANIFEST.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
readme='''# One More Adventure, Amor — final music and letter pass

Windows x64, Godot 4.7.2 GL Compatibility. Keep the EXE and PCK together.
WASD walks, E interacts, Escape pauses. Existing saves remain compatible.

This distributable has sound effects but no user-supplied recordings because
redistribution authorization has not been provided. For private local playback,
extract the separate LOCAL ONLY soundtrack overlay beside the EXE so music/
contains all eleven normalized recordings and tracks.json. Settings provides
music volume (zero mutes) and “Recargar archivos de música”.

The exact anniversary letter appears on the sunset beach. Read at your pace;
wheel, arrows, Page Up/Down and Home/End scroll. E or Continue closes it.
Credits offers “Leer la carta de nuevo”; chapter replay remains available.

Credits and recording mappings: music/CREDITS.md and SOUNDTRACK_MANIFEST.json.
Private source photographs and original recordings are never in this package.
'''
for target in [public,local]:
    (target/'README.md').write_text(('LOCAL PRIVATE PLAYBACK FOLDER: the soundtrack overlay is already installed here. Do not redistribute these recordings without permission.\n\n' if target==local else '')+readme,encoding='utf-8')
    shutil.copyfile(ROOT/'.tools/GODOT_LICENSE.txt',target/'GODOT_LICENSE.txt')
    shutil.copyfile(ROOT/'.tools/GODOT_THIRD_PARTY_NOTICES.txt',target/'GODOT_THIRD_PARTY_NOTICES.txt')
    shutil.copyfile(ROOT/'assets/fonts/OFL.txt',target/'PIXELIFY_FONT_LICENSE.txt')
for c in manifest['tracks'].values():
    require(not (public/'music'/c['file']).exists(),'Recording leaked into public package')
    require(sha(local/'music'/c['file'])==sha(ROOT/'music'/c['file']),'Local runtime recording changed')
data=pack.read_bytes()
for c in manifest['tracks'].values():
    require(('music/'+c['file']).encode() not in data,'Recording leaked into PCK')
for forbidden in [b'music/originals/',b'assets/references/',b'docs/final-music-letter/']:
    require(forbidden not in data,'Private/development content in PCK')
require(sha(local/'One More Adventure Amor.pck')==sha(pack),'Local/public game PCKs differ')

archive=ROOT/'builds/One More Adventure Amor Final Music and Letter.zip'
overlay=ROOT/'builds/LOCAL ONLY - One More Adventure Amor Soundtrack Overlay.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
    for p in sorted(public.rglob('*')):
        if p.is_file():z.write(p,p.relative_to(public))
with zipfile.ZipFile(overlay,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
    for p in sorted((local/'music').glob('*')):
        if p.is_file():z.write(p,p.relative_to(local))
for path in [archive,overlay]:
    with zipfile.ZipFile(path) as z:require(z.testzip() is None,'ZIP integrity failure')
with zipfile.ZipFile(archive) as z:
    require(not any(n.lower().endswith(('.ogg','.flac','.wav')) for n in z.namelist()),'Recording in distributable ZIP')

# Only actual exported viewport images, with enough time to read each endpoint.
files=[proof/'windows'/n for n in ['05_letter_prompt.png','06_letter_top.png','07_letter_bottom.png','08_credits.png']]
require(all(p.stat().st_mtime>pack.stat().st_mtime for p in files),'Stale viewport evidence')
frames=[Image.open(p).convert('RGB').resize((960,540),Image.Resampling.NEAREST) for p in files]
frames[0].save(proof/'letter_and_credits.gif',save_all=True,append_images=frames[1:],duration=[1000,3000,3000,2000],loop=0)
report={'branch':'feature/final-music-and-letter','base_main':'80a5dc6','letter':integrity,'native_runs':results,'headless_suites':headless,'headless_checks':sum(v['checks'] for v in headless.values()),'recordings_in_public_git_or_pck':False,'files':{}}
for p in [public/'One More Adventure Amor.exe',pack,archive,overlay]:report['files'][str(p.relative_to(ROOT))]={'bytes':p.stat().st_size,'sha256':sha(p)}
(proof/'BUILD_VERIFICATION.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report,indent=2))

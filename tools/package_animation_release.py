"""Package animation polish separately, preserving every earlier release."""
from pathlib import Path
import hashlib
import shutil
import zipfile
root=Path(__file__).resolve().parents[1]
release=root/'builds/2d-animation-polish'
for name in ['One More Adventure Amor.exe','One More Adventure Amor.pck']:
    assert (release/name).is_file(),f'Export first: {name}'
for name in ['GODOT_LICENSE.txt','GODOT_THIRD_PARTY_NOTICES.txt','PIXELIFY_FONT_LICENSE.txt']:
    shutil.copyfile(root/'builds/living-2d-memories'/name,release/name)
(release/'music').mkdir(exist_ok=True)
shutil.copyfile(root/'builds/living-2d-memories/music/README.md',release/'music/README.md')
(release/'README.md').write_text('''# One More Adventure, Amor — 2D Animation Polish

Open One More Adventure Amor.exe; keep its matching .pck beside it.
WASD move, E interact, P phone, Escape pause, Space optional dance beat.
Change in the yacht pool hut, then E at the ladder to enter/exit the water.
Ladder animation briefly locks movement; swimming activates afterward.
Swimwear walking and swimming now have distinct coherent four-direction frames.
Standing holds an idle frame; stopping in water plays gentle front-facing treading.
Saving during the ladder animation reloads safely on the destination side.

All chapters, environments, minigames, story dialogue and voxel gameplay preserved.
Guillermo remains clean-shaven without cheek blush. Older saves remain compatible.
Godot 4.7.2 Windows x86_64 GL Compatibility; license notices included.
Private reference images, development tools and preview scene excluded.
Known limits: front-facing tread only; exit reverses entry climbing art;
NPC variation uses existing poses, not new full directional NPC atlases.
Human pacing/lower-end playtesting and personal letter/music content remain.
''',encoding='utf-8')
pack=(release/'One More Adventure Amor.pck').read_bytes()
for path in ['assets/art/living/anami_swimming.png','scripts/character_animation.gd','data/mun_debate.json','data/ikura_order.json','data/guillermo_quiz.json','data/oatmeal_cookie_recipe.json']:
    assert path.encode() in pack,f'Missing runtime asset: {path}'
for excluded in [b'assets/references/',b'assets/art/concepts/',b'scripts/dev/',b'scenes/dev/']:
    assert excluded not in pack,f'Private/developer content in pack: {excluded}'
archive=root/'builds/One More Adventure Amor 2D Animation Polish.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as output:
    for path in sorted(release.rglob('*')):
        if path.is_file():output.write(path,path.relative_to(release))
with zipfile.ZipFile(archive) as output:assert output.testzip() is None
print(f'ZIP: {archive}\nBytes: {archive.stat().st_size}\nSHA256: {hashlib.sha256(archive.read_bytes()).hexdigest()}')

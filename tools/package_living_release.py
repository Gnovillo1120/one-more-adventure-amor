"""Package the exported living-memory build; older releases remain untouched."""
from pathlib import Path
import hashlib
import shutil
import zipfile
root=Path(__file__).resolve().parents[1]
release=root/'builds/living-2d-memories'
for name in ['One More Adventure Amor.exe','One More Adventure Amor.pck']:
    assert (release/name).is_file(), f'Export first: {name}'
for name in ['GODOT_LICENSE.txt','GODOT_THIRD_PARTY_NOTICES.txt','PIXELIFY_FONT_LICENSE.txt']:
    shutil.copyfile(root/'builds/interactive-memory-minigames'/name,release/name)
(release/'music').mkdir(exist_ok=True)
shutil.copyfile(root/'builds/interactive-memory-minigames/music/README.md',release/'music/README.md')
(release/'README.md').write_text('''# One More Adventure, Amor — Living 2D Memories

Open One More Adventure Amor.exe and keep the matching .pck beside it.
WASD walk, E interact/dialogue, Escape pause. P or the phone button opens the
handheld conversation; wheel/Page Up/Page Down/Home/End scroll messages.

The yacht club now has seating, a fictional club drink and a connected pool wing.
Change before swimming, use the ladder to enter/leave, then change back before
returning to the promenade. Movement stays within the pool while swimming.
The invitation is creatively staged in Anami's bedroom: find the denim dress,
then the red bandana, then white sneakers with WASD and E within 75 seconds.
Failure permits a retry at the mirror and preserves the rest of the chapter.
Optional photos unlock a recreated game image in the pause album. Extra dancing
uses Space near the beat and never blocks the story. Guillermo has no cheek blush.

All six chapters remain playable, including the preserved 3D voxel adventure.
Existing debate, exact food order, Guillermo quiz and cookie scoring are intact.
Activity states and messages are additive save keys; old saves remain accepted.

Godot 4.7.2, Windows x86_64, GL Compatibility. License/font notices included.
Private reference photographs and development material are excluded.
The personal letter and final instrumental recordings still await user content.
NPC behavior is lightweight, costume preparation has a fixed dressing sequence,
and lower-end laptop performance and human pacing still need playtesting.
''',encoding='utf-8')
pack=(release/'One More Adventure Amor.pck').read_bytes()
for path in ['data/mun_debate.json','data/ikura_order.json','data/guillermo_quiz.json','data/oatmeal_cookie_recipe.json','assets/art/living/anami_actions.png','assets/art/living/guillermo_affection.png']:
    assert path.encode() in pack, f'Missing runtime asset: {path}'
assert b'assets/references/' not in pack
assert b'assets/art/concepts/' not in pack
archive=root/'builds/One More Adventure Amor Living 2D Memories.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as output:
    for path in sorted(release.rglob('*')):
        if path.is_file():output.write(path,path.relative_to(release))
with zipfile.ZipFile(archive) as output:assert output.testzip() is None
print(f'ZIP: {archive}\nBytes: {archive.stat().st_size}\nSHA256: {hashlib.sha256(archive.read_bytes()).hexdigest()}')

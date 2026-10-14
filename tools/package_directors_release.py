"""Package the separate Director's Cut milestone; preserve earlier releases."""
from pathlib import Path
import hashlib,shutil,zipfile
r=Path(__file__).resolve().parents[1];release=r/'builds/directors-cut-milestone-1';old=r/'builds/2d-animation-polish'
for name in ['One More Adventure Amor.exe','One More Adventure Amor.pck']:assert (release/name).is_file()
for name in ['GODOT_LICENSE.txt','GODOT_THIRD_PARTY_NOTICES.txt','PIXELIFY_FONT_LICENSE.txt']:shutil.copyfile(old/name,release/name)
(release/'music').mkdir(exist_ok=True);shutil.copyfile(old/'music/README.md',release/'music/README.md')
(release/'README.md').write_text('''# One More Adventure, Amor — Director's Cut milestone 1

DEVELOPMENT BUILD: the final personal letter is still an editable placeholder,
and final instrumental recordings are pending. This is not the final gift release.
Keep the matching .pck beside the executable. Windows x64, Godot 4.7.2,
GL Compatibility. Previous releases and saves remain available/compatible.

WASD moves, E interacts, P opens the phone, Esc pauses. Space/E/Esc skips
the new opening/page transition. Reduced motion is in Settings.
The Memory Room opens before the first chapter and between recovered chapters.
Five optional personal objects: Yoda keychain, gold A necklace, Guillermo photo
(pixel illustration, not the original), MUN diploma, oatmeal-cookie recipe.
Open the box on Yoda's page; optional objects never gate the ending.
Completed chapter replay returns to the room; use the return button to abort.
Baking notes distinguish first/latest completed scores in this playthrough.
The bandana stays in Halloween clothing, never as a featured symbolic keepsake.

Milestones 2–4 remain: 2D cinematic polish, visible Minecraft kidnapping and
rescue staging, final beach/letter/audio production. Existing complete story,
minigames, swimming, clean-shaven no-blush Guillermo and voxel gameplay remain.
Private reference photographs, concepts, tests and tools are excluded.
''',encoding='utf-8')
pack=(release/'One More Adventure Amor.pck').read_bytes()
for path in ['data/directors_cut.json','scripts/directors_cut.gd','scripts/memory_room.gd','assets/art/directors/yoda_keychain.svg','assets/art/directors/a_necklace.svg','assets/art/directors/first_photo.svg','assets/art/directors/mun_diploma.svg','assets/art/directors/recipe_card.png','assets/art/directors/memory_room.png','data/oatmeal_cookie_recipe.json']:
    assert path.encode() in pack,'Missing runtime asset: '+path
for path in [b'assets/references/',b'assets/art/concepts/',b'scripts/dev/',b'scenes/dev/',b'scripts/directors_cut_test.gd',b'docs/directors/']:assert path not in pack,'Private/development content included: '+repr(path)
archive=r/'builds/One More Adventure Amor Directors Cut Milestone 1.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
    for path in sorted(release.rglob('*')):
        if path.is_file():z.write(path,path.relative_to(release))
with zipfile.ZipFile(archive) as z:assert z.testzip() is None
print(f'ZIP: {archive}\nBytes: {archive.stat().st_size}\nSHA256: {hashlib.sha256(archive.read_bytes()).hexdigest()}')

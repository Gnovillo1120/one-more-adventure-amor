"""Package the corrected milestone beside, without replacing, the previous build."""
from pathlib import Path
import shutil,zipfile,hashlib
r=Path(__file__).resolve().parents[1];release=r/'builds/directors-cut-playtest-fixes';old=r/'builds/directors-cut-milestone-1'
for name in ['One More Adventure Amor.exe','One More Adventure Amor.pck']:assert (release/name).is_file()
for name in ['GODOT_LICENSE.txt','GODOT_THIRD_PARTY_NOTICES.txt','PIXELIFY_FONT_LICENSE.txt']:shutil.copyfile(old/name,release/name)
(release/'music').mkdir(exist_ok=True);shutil.copyfile(old/'music/README.md',release/'music/README.md')
(release/'README.md').write_text('''# One More Adventure, Amor — Milestone 1 playtest fixes

Keep the matching .pck beside the executable. Godot 4.7.2, Windows x64,
GL Compatibility. Previous builds are preserved. Saves remain compatible.
WASD moves, E interacts, P phone, Esc pause. Space skips book cinematics.

Decorative keepsake art is absent from normal memory/voxel HUDs.
The lobby bench is removed; generic signposts become contextual E prompts.
Optional conference photography has pocket/hold/aim/shutter/lower poses,
brief focus, subtle subject flash and an original shutter sound. Reduced
Motion disables the focus/flash. Movement locks for 2.1 seconds during a shot.
The shot unlocks in Book → Fotos de la partida, separate from Guillermo's
Instagram-photo keepsake. Repeated shots do not duplicate the album entry.
Quiz Q4: five cities; Q8: Xbox 360. Both use answer C. Existing 10 questions,
Hard Mode and 8/10 threshold remain. Active old quizzes update cached
feedback/score to corrected facts; completed chapter progress is preserved.
Beach card and its HUD prompt leave both characters unobstructed.

DEVELOPMENT BUILD: the personal letter is still an editable placeholder;
final licensed music and Director's Cut milestones 2–4 remain unfinished.
No personal reference photographs, source concepts or developer tools included.
''',encoding='utf-8')
pack=(release/'One More Adventure Amor.pck').read_bytes()
for name in ['data/guillermo_quiz.json','scripts/photo_action.gd','assets/art/living/photo_phone_poses.svg','assets/audio/camera_shutter.wav','scripts/directors_cut.gd','data/directors_cut.json']:assert name.encode() in pack,name
for name in [b'assets/references/',b'assets/art/concepts/',b'tools/playtest_capture',b'docs/playtest/',b'scripts/playtest_fixes_test.gd']:assert name not in pack,name
archive=r/'builds/One More Adventure Amor Directors Cut Playtest Fixes.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
    for p in sorted(release.rglob('*')):
        if p.is_file():z.write(p,p.relative_to(release))
with zipfile.ZipFile(archive) as z:assert z.testzip() is None
print(f'ZIP: {archive}\nBytes: {archive.stat().st_size}\nSHA256: {hashlib.sha256(archive.read_bytes()).hexdigest()}')

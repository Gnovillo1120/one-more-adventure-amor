"""Package the already-exported Windows minigame release without touching old builds."""
from pathlib import Path
import hashlib
import shutil
import zipfile

root=Path(__file__).resolve().parents[1]
release=root/"builds/interactive-memory-minigames"
for name in ["One More Adventure Amor.exe","One More Adventure Amor.pck"]:
    assert (release/name).is_file(), f"Export first: {name}"
for name in ["GODOT_LICENSE.txt","GODOT_THIRD_PARTY_NOTICES.txt","PIXELIFY_FONT_LICENSE.txt"]:
    shutil.copyfile(root/"builds/redesign-phase-a"/name,release/name)
(release/"music").mkdir(exist_ok=True)
shutil.copyfile(root/"builds/redesign-phase-a/music/README.md",release/"music/README.md")
(release/"README.md").write_text("""# One More Adventure, Amor — Interactive Memory Minigames

Open One More Adventure Amor.exe. Keep the matching .pck beside it.

Six chapters remain playable, including Claude's rebuilt voxel world. MUN requires
7/10; Ikura requires gyozas + Guillermo's miso ramen + Anami's sushi; the new
Guillermo quiz requires 8/10. Cookies are one continuous memory with a 0–100%
tastiness result and no failure state. Retry affects only the failed challenge.

WASD walk; E interact/dialogue; Escape pause. Challenge answers: click or 1–5,
Tab/arrows and Enter/Space. Ordering: Q/W/R category, 1–6 dish, Enter submit.
Pantry: click/Space toggle focused ingredient; Enter gather. Long lists scroll.
Phone: wheel/Page Up/Page Down/Home/End. 3D: mouse look, WASD, left-click sword.

Challenge phases, selections, scores and exploration survive saves and pauses.
Prior v1 saves remain loadable; incomplete older food/baking attempts start the
new challenge. Restart Chapter intentionally restarts that chapter's objectives.

Godot 4.7.2, Windows x86_64, GL Compatibility. Godot/font notices included.
Personal letter and final instrumental recordings still need user content.
Kitchen actions use a decision UI with semantic hooks for future animation.
Human pacing and lower-end laptop performance still need playtesting.
Private reference photos, developer screenshots, tools and tests are excluded.
""",encoding="utf-8")
pack=(release/"One More Adventure Amor.pck").read_bytes()
for path in ["data/mun_debate.json","data/ikura_order.json","data/guillermo_quiz.json","data/oatmeal_cookie_recipe.json"]:
    assert path.encode() in pack, f"Missing runtime bank: {path}"
assert b"assets/references/" not in pack
archive=root/"builds/One More Adventure Amor Interactive Memory Minigames.zip"
with zipfile.ZipFile(archive,"w",zipfile.ZIP_DEFLATED,compresslevel=6) as output:
    for path in sorted(release.rglob("*")):
        if path.is_file():output.write(path,path.relative_to(release))
with zipfile.ZipFile(archive) as output:assert output.testzip() is None
print(f"ZIP: {archive}\nBytes: {archive.stat().st_size}\nSHA256: {hashlib.sha256(archive.read_bytes()).hexdigest()}")

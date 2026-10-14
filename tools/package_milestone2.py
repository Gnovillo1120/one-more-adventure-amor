"""Package the separately validated M2 release; preserve earlier binaries."""
from pathlib import Path
import hashlib
import json
import shutil
import zipfile
from PIL import Image

root = Path(__file__).resolve().parents[1]
release = root / "builds/directors-cut-milestone-2"
old = root / "builds/directors-cut-playtest-fixes"
evidence = root / "docs/milestone2"
for name in ["One More Adventure Amor.exe", "One More Adventure Amor.pck"]:
    assert (release / name).is_file(), name
for name in ["GODOT_LICENSE.txt", "GODOT_THIRD_PARTY_NOTICES.txt", "PIXELIFY_FONT_LICENSE.txt"]:
    shutil.copyfile(old / name, release / name)
(release / "music").mkdir(exist_ok=True)
shutil.copyfile(old / "music/README.md", release / "music/README.md")
(release / "README.md").write_text("""# One More Adventure, Amor — Director’s Cut milestone 2

DEVELOPMENT BUILD. Final personal letter and licensed music remain pending.
Windows x64, Godot 4.7.2, GL Compatibility. Keep the matching PCK beside the EXE.
Existing M1 saves, five keepsakes, corrected quiz facts and voxel route remain.
Private references and development documents/tests are excluded from the pack.

WASD walks; E interacts; Esc pauses. Space/E/Esc skips concise 2D staging.
Reduced Motion is in Settings. Cookie prep starts with three warm-up questions,
then walk to pantry/fridge/sink/counter/oven/rack. Tab leaves a close-up; F1 shows
the actual recipe. Pantry arrows select, Space toggles, Enter finishes gathering.
Measure with held Space/mouse pour, R empties, Enter adds. Mix by circular mouse
motion or held Space; Enter can finish with the current texture after some mixing.
Eggs: G grab, T tap twice, Enter crack. Add dry/oat portions with A, then mix.
Chill in fridge; choose temperature with 1/2/3, Enter preheats. Tray: S spray,
click portions or Enter places suggested positions, R resets. Fork: D dips,
arrows choose, Enter presses. Oven: Enter inserts, M mitts, S swaps after four
minutes, Enter removes. 8–10 recipe minutes is about 32–40 real seconds. You may
leave the close-up while it bakes; pause freezes time. Cool on tray, then rack,
then taste. Imperfect batches always advance and retain the cookie keepsake.
Old active recipes adapt; new partial physical actions survive saves and resume
at their station. Completed first/latest scores remain in the memory book.

Previous builds remain preserved. This build prioritizes 2D memories and baking;
final Minecraft cinematic and beach/letter/music production remain later work.
""", encoding="utf-8")

pack = (release / "One More Adventure Amor.pck").read_bytes()
for path in ["scripts/baking_session.gd", "scripts/baking_view.gd", "scripts/memory_cinematic.gd", "assets/art/baking/home_kitchen.png", "assets/art/baking/counter.png", "assets/art/baking/bowl.png", "assets/art/baking/jar.png", "data/oatmeal_cookie_recipe.json"]:
    assert path.encode() in pack, "Missing runtime: " + path
for path in [b"assets/references/", b"assets/art/concepts/", b"scripts/milestone2_test.gd", b"docs/milestone2/"]:
    assert path not in pack, "Private/development content: " + repr(path)
assert "MILESTONE2_CAPTURE: native source/export interaction and skip checks passed" in (evidence / "export_capture_stdout.txt").read_text()
assert not (evidence / "export_capture_stderr.txt").read_text().strip()

expected = sorted(p.name for p in (evidence / "source").glob("*.png"))
assert len(expected) == 23
for name in expected:
    for version in ["source", "export"]:
        with Image.open(evidence / version / name) as im:
            assert im.size == (1280, 720), (version, name, im.size)
            assert im.convert("RGB").getpixel((10, 350)) != (255, 255, 255), "White counter regression"
for name, frames, duration in [
    ("baking", ["01_kitchen", "04_measuring", "06_egg", "09_fork", "10_oven", "12_result"], 1100),
    ("mixing", [f"05_mix_{i}" for i in range(5)], 260),
    ("first_kiss", ["15_pool_seated", "16_pool_lean", "17_first_kiss"], 900),
]:
    images = [Image.open(evidence / "export" / (frame + ".png")).convert("RGB") for frame in frames]
    assert len({hashlib.sha256(im.tobytes()).hexdigest() for im in images}) == len(images)
    images[0].save(evidence / (name + ".gif"), save_all=True, append_images=images[1:], duration=duration, loop=0)

archive = root / "builds/One More Adventure Amor Directors Cut Milestone 2.zip"
with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as z:
    for path in sorted(release.rglob("*")):
        if path.is_file():
            z.write(path, path.relative_to(release))
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
verification = {"engine": "Godot 4.7.2 GL Compatibility", "qa_checks": 2603, "suites": 13, "native_source_frames": 23, "native_export_frames": 23, "files": {}}
for path in [release / "One More Adventure Amor.exe", release / "One More Adventure Amor.pck", archive]:
    verification["files"][str(path.relative_to(root))] = {"bytes": path.stat().st_size, "sha256": hashlib.sha256(path.read_bytes()).hexdigest()}
legacy_zip = root / "builds/One More Adventure Amor Directors Cut Playtest Fixes.zip"
assert hashlib.sha256(legacy_zip.read_bytes()).hexdigest() == "b7b4b2d442c18d2cfc6b9bb64c0ed143d5c8ee88e1bf67a1ee0a48a669b9f503", "Previous build changed"
(evidence / "BUILD_VERIFICATION.json").write_text(json.dumps(verification, indent=2) + "\n", encoding="utf-8")
print(json.dumps(verification, indent=2))

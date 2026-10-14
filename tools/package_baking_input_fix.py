"""Verify the real-input Windows run and package its separately preserved release."""
from pathlib import Path
import hashlib
import json
import re
import shutil
import zipfile
from PIL import Image

root = Path(__file__).resolve().parents[1]
evidence = root / "docs/milestone2/input_fix"
release = root / "builds/directors-cut-milestone-2-input-fix"
previous = root / "builds/directors-cut-milestone-2"
stdout = root / "docs/milestone2/input_fix_export_stdout.txt"
assert "0 failures; complete workflow through Input.parse_input_event" in stdout.read_text()
assert not (root / "docs/milestone2/input_fix_export_stderr.txt").read_text().strip()
trace_path = evidence / "export/INPUT_TRACE.json"
assert trace_path.stat().st_mtime > (release / "One More Adventure Amor.pck").stat().st_mtime
trace = json.loads(trace_path.read_text())
assert trace["failures"] == 0
stations = [e for e in trace["input_events"] if "station" in e]
for name, ids, count in [("pantry", ["flour", "oats"], 10), ("fridge", ["eggs", "butter"], 12), ("sink", ["water"], 13)]:
    visit = next(e for e in stations if e["station"] == name)
    assert visit["prompt_target"] == "baking:" + name
    assert len(visit["inventory_after"]) == count and all(i in visit["inventory_after"] for i in ids)
assert any(e.get("physical_key") == "E" and e.get("pressed") for e in trace["input_events"])
assert any(e["station"] == "counter" and e["phase_after"] == "measure" for e in stations)
assert {e["station"] for e in stations} == {"pantry", "fridge", "sink", "counter", "oven", "rack"}

for filename in ["GODOT_LICENSE.txt", "GODOT_THIRD_PARTY_NOTICES.txt", "PIXELIFY_FONT_LICENSE.txt"]:
    shutil.copyfile(previous / filename, release / filename)
(release / "music").mkdir(exist_ok=True)
shutil.copyfile(previous / "music/README.md", release / "music/README.md")
(release / "README.md").write_text("""# Milestone 2 — cookie input progression fix

Windows x64 development build, Godot 4.7.2 GL Compatibility.
Keep this EXE and its matching PCK together. Existing saves are compatible,
including a cookie session saved at Reunir ingredientes; resume that session.

WASD walks; E interacts. After the three-question prep quiz:
E at pantry collects dry ingredients (10/13); E at fridge collects butter and
eggs (12/13); E at sink collects water/tools (13/13). E at the counter opens
measuring when ready. An incomplete counter visit explains what is missing.
The objective displays inventory progress. Repeated station visits are safe.

Counter: held Space/mouse pours, R empties, Enter adds. Circular mouse motion or
held Space mixes. A adds dry/oat portions. Eggs: G grab, T tap twice, Enter crack.
Tab returns to kitchen. E at fridge opens chilling, Enter skips one hour.
E at oven opens preheat, 2 chooses 190°C, Enter preheats. E at counter opens
tray; S sprays, Enter places six portions and proceeds, D dips fork, Enter
presses, repeated six times. E at oven opens baking; Enter inserts, M takes
mitts, S swaps after four recipe minutes, Enter pulls at 8–10 minutes (about
32–40 real seconds). Esc pauses the timer. E at rack opens cooling, Enter
transfers after five abbreviated seconds; E at rack then Enter tastes. Results
always advance. Existing keepsakes, quiz facts, animations and 3D are preserved.

Validated with actual Godot input events through the exported EXE, rather than
calling station methods. Original M2 build and earlier builds remain available.
Final personal letter and licensed music still remain pending.
""", encoding="utf-8")
pack = (release / "One More Adventure Amor.pck").read_bytes()
assert b"scripts/baking_input_runner.gd" in pack
for path in [b"assets/references/", b"scripts/baking_input_test.gd", b"docs/milestone2/"]:
    assert path not in pack
expected = sorted(p.name for p in (evidence / "source").glob("*.png"))
assert len(expected) == 35
for name in expected:
    with Image.open(evidence / "export" / name) as im:
        assert im.size == (1280, 720)
frames = [Image.open(evidence / "export" / (name + ".png")).convert("RGB") for name in ["01_pantry_before_E", "01_pantry_E_pressed", "02_fridge_E_pressed", "03_sink_E_pressed", "04_counter_E_pressed", "10_perfect_window", "12_result"]]
assert len({hashlib.sha256(im.tobytes()).hexdigest() for im in frames}) == len(frames)
frames[0].save(evidence / "actual_input_progression.gif", save_all=True, append_images=frames[1:], duration=1200, loop=0)

archive = root / "builds/One More Adventure Amor Directors Cut Milestone 2 Input Fix.zip"
with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as z:
    for path in sorted(release.rglob("*")):
        if path.is_file(): z.write(path, path.relative_to(release))
with zipfile.ZipFile(archive) as z: assert z.testzip() is None
old_zip = root / "builds/One More Adventure Amor Directors Cut Milestone 2.zip"
assert hashlib.sha256(old_zip.read_bytes()).hexdigest() == "71dcd7982ee95d0651f8c351b739ef8d8e099140cc5e82c77326ee7016d89df1"
verification = {"native_input_checks": trace["checks"], "native_input_failures": 0, "actual_input_events": len(trace["input_events"]), "export_frames": len(expected), "previous_m2_zip_unchanged": True, "files": {}}
for path in [release / "One More Adventure Amor.exe", release / "One More Adventure Amor.pck", archive]:
    verification["files"][str(path.relative_to(root))] = {"bytes": path.stat().st_size, "sha256": hashlib.sha256(path.read_bytes()).hexdigest()}
(evidence / "BUILD_VERIFICATION.json").write_text(json.dumps(verification, indent=2) + "\n", encoding="utf-8")
print(json.dumps(verification, indent=2))

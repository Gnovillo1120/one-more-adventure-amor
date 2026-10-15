"""Package only a validated Windows build; GIFs use actual captured viewport frames."""
from pathlib import Path
import hashlib
import json
import re
import shutil
import zipfile
from PIL import Image

root = Path(__file__).resolve().parents[1]
proof = root / "docs/m2-polish"
release = root / "builds/directors-cut-m2-polish"
pack = release / "One More Adventure Amor.pck"

def require(condition, message):
    if not condition:
        raise RuntimeError(message)

traces = {}
for label, directory, name in [("source_baking", "source", "INPUT_TRACE.json"),
                               ("source_polish", "uess-source", "POLISH_INPUT_TRACE.json"),
                               ("windows_baking", "export", "INPUT_TRACE.json"),
                               ("windows_imperfect", "export-imperfect", "INPUT_TRACE.json"),
                               ("windows_polish", "uess-export", "POLISH_INPUT_TRACE.json")]:
    path = proof / directory / name
    trace = json.loads(path.read_text(encoding="utf-8"))
    require(trace["failures"] == 0, label + " failed")
    if label.startswith("windows"):
        require(path.stat().st_mtime > pack.stat().st_mtime, label + " predates exported PCK")
    events = trace.get("input_events", trace.get("events", []))
    require(any(e.get("physical_key") == "E" and e.get("pressed") for e in events), label + " has no E key events")
    traces[label] = {"checks": trace["checks"], "events": len(events), "failures": 0}
    if "score" in trace:
        traces[label]["score"] = trace["score"]
    if "guillermo_meal_progress" in trace:
        progress=trace["guillermo_meal_progress"]
        require([entry["meal"] for entry in progress] == [0,1,2,3,4], label+" did not serve Guillermo independently")
        require(all(abs(entry["position"][0]-x)<2 for entry,x in zip(progress,[306,306,451,596,741])),label+" serving did not occur at real stations")
    if "fountain_frames" in trace:
        require(len(trace["fountain_frames"]) == 20, "four fountain approaches sampled")
        require(all(f["frame"] == 1 and f["row"] == 0 for f in trace["fountain_frames"]), "drinking directions changed")

require(traces["windows_baking"]["score"] >= 95, "excellent bake not reached")
require(traces["windows_imperfect"]["score"] < 60, "imperfect bake not exercised")
for name in ["windows_baking", "windows_imperfect"]:
    folder = "export" if name == "windows_baking" else "export-imperfect"
    trace = json.loads((proof / folder / "INPUT_TRACE.json").read_text())
    stations = [e for e in trace["input_events"] if "station" in e]
    for station, count in [("pantry", 10), ("fridge", 12), ("sink", 13)]:
        visit = next(e for e in stations if e["station"] == station)
        require(visit["prompt_target"] == "baking:"+station and len(visit["inventory_after"]) == count, "station routing / inventory")
    require(any(e.get("mouse") == "left" for e in trace["input_events"]), "actual mouse input missing")

suites = {}
for path in sorted((proof / "qa").glob("*_test.log")):
    text = path.read_text(encoding="utf-8-sig", errors="replace")
    matches = re.findall(r"([A-Z0-9_]+_QA):\s*(\d+) checks;\s*(\d+) failures", text)
    require(matches and all(int(m[2]) == 0 for m in matches), "QA suite failed: " + path.name)
    require("SCRIPT ERROR" not in text, "Script error in " + path.name)
    suites[path.stem] = {"checks": int(matches[-1][1]), "failures": 0}
require(len(suites) == 15, "all fifteen headless suites required")

def gif(name, files, delay=180):
    files = [file for file in files if file.stat().st_mtime > pack.stat().st_mtime]
    require(len(files) > 1, "missing motion evidence: " + name)
    frames = []
    for file in files:
        with Image.open(file) as image:
            require(image.size == (1280, 720), "capture is not native viewport size")
            frames.append(image.convert("RGB").resize((960, 540), Image.Resampling.NEAREST))
    frames[0].save(proof / (name+".gif"), save_all=True, append_images=frames[1:], duration=delay, loop=0)

native = proof / "export"
gif("ingredient_collection", [native/(station+suffix+".png") for station in ["01_pantry","02_fridge","03_sink"] for suffix in ["_before_E","_E_pressed","_after_E"]], 650)
for name, patterns in {"flour_transfer":["motion_pour_00_*.png", "motion_measure_00_*.png"],
                       "egg_cracking":["motion_crack_*.png"],
                       "mixing":["motion_mix_dry_*.png", "motion_mix_cream_*.png", "motion_mix_oats_*.png"],
                       "scoop_and_press":["motion_portion_*.png", "motion_dip_*.png", "motion_flatten_*.png"],
                       "oven_and_cooling":["motion_insert_*.png", "motion_pull_*.png", "motion_rack_*.png"],
                       "tasting":["motion_taste_*.png"]}.items():
    gif(name, [file for pattern in patterns for file in sorted(native.glob(pattern))])
uess = proof / "uess-export"
gif("catered_memory", [uess/(n+".png") for n in ["catering_0_prompt", "catering_0_delivered", "catering_1_response", "catering_1_delivered", "catering_2_delivered", "catering_3_delivered", "sitting_together_prompt", "couple_seated"]], 900)
gif("ceremony", sorted(uess.glob("ceremony_[0-9][0-9].png")), 500)
gif("plate_carrying", sorted(uess.glob("plate_direction_*.png")), 350)
gif("guillermo_catering", sorted(uess.glob("guillermo_serving_*.png")), 220)
gif("quiz_helper", sorted(native.glob("quiz_helper_*.png")), 220)
gif("fountain", [uess/("fountain_%02d.png"%i) for i in range(1,6)], 220)
gif("ikura_menu", [uess/"ikura_menu_page_1.png", uess/"ikura_menu_page_2.png"], 1700)

previous = root / "builds/directors-cut-milestone-2-input-fix"
for name in ["GODOT_LICENSE.txt", "GODOT_THIRD_PARTY_NOTICES.txt", "PIXELIFY_FONT_LICENSE.txt"]:
    shutil.copyfile(previous/name, release/name)
(release/"music").mkdir(exist_ok=True)
shutil.copyfile(previous/"music/README.md", release/"music/README.md")
(release/"README.md").write_text("""# One More Adventure, Amor — Director’s Cut M2 polish

Windows x64 development playtest, Godot 4.7.2 GL Compatibility.
Keep the EXE and matching PCK together. Previous saves remain compatible.

WASD walks, E interacts, Escape pauses, F1 opens the cooking recipe.
At the UESS serving line collect a plate, rice, menestra and meat before
choosing to sit beside Guillermo. At the ceremony, choose a seat first.
E / Space skips the announcement. Walk to Guillermo afterward.
Ikura: Q/W/R selects diner, arrows change menu page, 1–6 chooses a visible
dish, Enter confirms the three-part order. Incorrect orders can be retried.

Cookies: pantry/fridge/sink E collects ingredients; counter E opens baking.
Hold Space or mouse to pour; Enter transfers; R empties. Circle the mouse
over the bowl or hold Space to mix; A adds dry/oat portions. G takes an egg,
T taps the rim (twice for a clean crack), Enter opens it. Tab returns to the
kitchen. E at fridge chills; E at oven adjusts/preheats; 2 selects 190°C.
At the counter S sprays, click or Enter places six portions, D wets/sugars
the fork, Enter presses. Allow each short physical transfer to finish.
At oven Enter inserts, M takes mitts, S swaps after 4 recipe minutes.
Pull at 8–10 minutes, about 32–40 seconds of active baking; Escape pauses.
Rack E cools/transfers/tastes. Every result can complete the memory.

Private photos and source concepts are excluded. Final personal letter and
licensed music remain pending. Human pacing and ordinary-laptop playtesting
remain important; this is a development build, not the final gift release.
""", encoding="utf-8")
data = pack.read_bytes()
for forbidden in [b"assets/references/", b"docs/m2-polish/", b"polish_cast_source.png", b"polish_moncayo_source.png", b"polish_menu_source.png", b"polish_ingredients_source.png"]:
    require(forbidden not in data, "private/development material in export: " + str(forbidden))
require(b"assets/art/polish/moncayo_walk.png" in data, "new runtime art missing")
for ingredient in ["flour","white_sugar","brown_sugar","oats","cinnamon","soda","salt","vanilla","butter"]:
    require(("assets/art/polish/ingredient_"+ingredient+".png").encode() in data, "ingredient art missing: "+ingredient)
require(b"data/baking_containers.json" in data,"container pivots missing")
archive = root / "builds/One More Adventure Amor Directors Cut M2 Polish.zip"
with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as zipped:
    for file in sorted(release.rglob("*")):
        if file.is_file():zipped.write(file, file.relative_to(release))
with zipfile.ZipFile(archive) as zipped:require(zipped.testzip() is None, "corrupt ZIP")
old = root / "builds/One More Adventure Amor Directors Cut Milestone 2 Input Fix.zip"
require(hashlib.sha256(old.read_bytes()).hexdigest() == "639104809f8169e3e28a20796770cd0331a852939b8ede4e0415bd92d6cd5bd4", "previous input-fix ZIP changed")
manifest = {"branch":"feature/directors-cut-m2-polish", "headless_suites":suites,
            "headless_checks":sum(s["checks"] for s in suites.values()), "native_runs":traces,
            "private_references_excluded":True,"previous_input_fix_zip_unchanged":True,"files":{}}
for file in [release/"One More Adventure Amor.exe", pack, archive]:
    manifest["files"][str(file.relative_to(root))] = {"bytes":file.stat().st_size, "sha256":hashlib.sha256(file.read_bytes()).hexdigest()}
(proof/"BUILD_VERIFICATION.json").write_text(json.dumps(manifest, indent=2)+"\n", encoding="utf-8")
print(json.dumps(manifest, indent=2))

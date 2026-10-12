"""Idempotently add the continuous kitchen to the existing room registry."""
import json
from pathlib import Path
path = Path("data/room_layouts.json")
rooms = json.loads(path.read_text(encoding="utf-8"))
stations = [
    ("pantry", "storage", [270, 340], 170, "DESPENSA", "Harina, canela, bicarbonato, sal y avena. La levadura de pan se queda aquí."),
    ("mixing", "counter", [550, 340], 240, "MEZCLA", "Bol y batidor listos. Mantequilla blanda; huevos uno a uno. El azúcar de cobertura va aparte."),
    ("fridge", "fridge", [870, 340], 110, "FRÍO", "La masa reposa al menos una hora. En este recuerdo el tiempo pasa en un instante."),
    ("oven", "oven", [1070, 340], 130, "HORNO", "375 °F / 190 °C; 8–10 minutos. Cambiamos las bandejas a mitad."),
    ("tasting", "counter", [805, 435], 180, "PROBAR", "Bandeja, tenedor y rejilla. Cinco minutos sobre la bandeja y luego enfriar en la rejilla."),
]
rooms["kitchen"] = {"fixtures": [dict(id=i,kind=k,position=p,width=w,label=l,collision=[-w/2,-18,w,30]) for i,k,p,w,l,t in stations]}
path.write_text(json.dumps(rooms,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
path=Path("data/story.json");story=json.loads(path.read_text(encoding="utf-8"))
scene=story["chapters"][3]["scenes"][0]
existing=[t for t in scene["exploration"].get("optional",[]) if t["id"] not in [s[0] for s in stations]]
for i,k,p,w,l,text in stations:
    if i=="tasting":continue
    existing.append(dict(id=i,kind="prop",visual=dict(kind="table",fixture=i),position=[p[0],p[1]+55],label=l,lines=[dict(speaker="Guillermo",text=text,mood="playful")]))
scene["exploration"]["optional"]=existing
path.write_text(json.dumps(story,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")

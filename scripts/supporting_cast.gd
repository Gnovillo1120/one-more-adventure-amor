extends RefCounted
## Original generated designs; private photographs never leave the local workspace.
const SPEAKERS := {"Moncayo":8,"Presidencia":9,"Delegación de Chad":1,"Delegada":2,"Delegado":0,"Catering":10,"Mesero":11,"Staff":10,"Anfitriona":4}
static func sprite(index: int) -> Texture2D:return load("res://assets/art/polish/cast_%d.png"%clampi(index,0,11))
static func portrait(speaker: String) -> Texture2D:
	return load("res://assets/art/polish/portrait_%d.png"%int(SPEAKERS[speaker])) if SPEAKERS.has(speaker) else load("res://assets/art/polish/neutral.svg")

"""Deterministic original synthesized score. Run from project root with Python 3."""
from pathlib import Path
import math, random, struct, wave

OUT = Path('assets/audio'); OUT.mkdir(parents=True, exist_ok=True)
RATE = 22050
def note(buf, at, duration, midi, gain=.15, soft=True):
    freq = 440 * 2 ** ((midi-69)/12)
    start = int(at*RATE); count = int(duration*RATE)
    for i in range(count):
        if start+i >= len(buf): break
        t=i/RATE
        envelope=min(1,t/.012)*min(1,(duration-t)/.06)*math.exp(-t*(3 if soft else 1.5))
        sound=(math.sin(2*math.pi*freq*t)+.28*math.sin(4*math.pi*freq*t)+.1*math.sin(6*math.pi*freq*t))
        buf[start+i]+=gain*envelope*sound
def save(name, buf):
    # Fade boundaries even when accompaniment release extends beyond the phrase.
    fade=min(int(.06*RATE),len(buf)//2)
    for i in range(fade):
        buf[i]*=i/fade
        buf[-1-i]*=i/fade
    peak=max(max(abs(x) for x in buf), .01)
    scale=.72/peak
    with wave.open(str(OUT/(name+'.wav')),'wb') as f:
        f.setnchannels(1); f.setsampwidth(2); f.setframerate(RATE)
        f.writeframes(b''.join(struct.pack('<h',int(max(-1,min(1,x*scale))*32767)) for x in buf))
motif=[0,4,7,9,7,4,2,0]
settings={
 'memory':(92,60,[0,5,7,0],False), 'date':(76,60,[0,9,5,7],False),
 'halloween':(88,57,[0,5,8,7],True), 'mystery':(66,57,[0,8,5,7],True),
 'boss':(118,57,[0,5,8,7],True), 'beach':(72,62,[0,5,9,7],False)}
for name,(bpm,root,chords,minor) in settings.items():
    beat=60/bpm; total=32*beat
    buf=[0.0]*int(total*RATE)
    melody=motif if not minor else [0,3,7,8,7,3,2,0]
    for bar,chord in enumerate(chords*2):
        at=bar*4*beat
        for j,degree in enumerate([0,7,3 if minor else 4,7,12,7,3 if minor else 4,7]):
            note(buf,at+j*.5*beat,beat*.8,root-12+chord+degree,.07)
        for j in range(4):
            note(buf,at+j*beat,beat*.9,root+12+melody[(bar*4+j)%8],.13)
        if name=='boss':
            for j in range(4): note(buf,at+j*beat,.15,root-24,.1,False)
    # Exact silence at boundaries prevents a discontinuity on loop playback.
    save(name,buf)
for name,notes in {'collect':[72,76,79,84], 'interact':[76,79], 'dialogue':[79],
                   'swing':[48,43], 'hit':[40,36], 'victory':[72,76,79,84,88],
                   'step':[43], 'menu':[81,84]}.items():
    buf=[0.0]*int((len(notes)*.09+.3)*RATE)
    for i,n in enumerate(notes): note(buf,i*.09,.22,n,.17)
    save(name,buf)
print('Generated',len(list(OUT.glob('*.wav'))),'original PCM WAV assets')

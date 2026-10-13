"""Code-native transparent action overlay poses, aligned to 32×48 actor cells."""
from pathlib import Path
import wave,struct,math
r=Path(__file__).resolve().parents[1];parts=[]
def rect(x,y,w,h,c):return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{c}"/>'
for row in range(8):
    direction=row%4
    for frame in range(5):
        y=[34,30,23,23,32][frame]
        x=[19,15,14,14,18][frame] if direction in [0,3] else [12,9,6,6,11][frame] if direction==1 else [20,23,26,26,21][frame]
        skin='#d7aa86';sleeve='#ddd1b9' if row<4 else '#547592';body=''
        # Shoulder-to-wrist stepped arms, then held/raised camera phone.
        handx=x-2 if direction==2 else x+3
        body+=rect(11 if direction!=2 else 20,27,3,max(2,y-25),sleeve)
        body+=rect(min(handx,13 if direction!=2 else 20),y+3,abs(handx-(13 if direction!=2 else 20))+2,2,sleeve)
        body+=rect(handx,y+2,2,3,skin)
        body+=rect(x,y,3,5,'#1d2d39')+rect(x+1,y+1,1,2,'#a8c5c4')
        if direction in [0,3] and frame in [2,3]:body+=rect(x-2,y+3,2,2,skin)+rect(x-4,y+4,2,2,sleeve)
        if frame==3:body+=rect(x-1,y-2,5,1,'#f4e8b8')+rect(x+1,y-3,1,3,'#f4e8b8')
        parts.append(f'<g transform="translate({frame*32} {row*48})">{body}</g>')
(r/'assets/art/living/photo_phone_poses.svg').write_text('<svg xmlns="http://www.w3.org/2000/svg" width="160" height="384" viewBox="0 0 160 384" shape-rendering="crispEdges">'+''.join(parts)+'</svg>\n',encoding='utf-8')
# Original short mechanical double-click effect, no external sound recording.
with wave.open(str(r/'assets/audio/camera_shutter.wav'),'wb') as w:
    w.setnchannels(1);w.setsampwidth(2);w.setframerate(22050)
    samples=[]
    for i in range(3528):
        t=i/22050;a=0
        for onset in [0,.065]:
            p=t-onset
            if p>=0:a+=.38*math.exp(-p*100)*(math.sin(2*math.pi*1700*p)+.4*math.sin(2*math.pi*3100*p))
        samples.append(struct.pack('<h',int(max(-1,min(1,a))*25000)))
    w.writeframes(b''.join(samples))
print('40 outfit-matched pixel action overlays and original shutter effect authored')

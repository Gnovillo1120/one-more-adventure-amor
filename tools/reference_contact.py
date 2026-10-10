from pathlib import Path
from PIL import Image, ImageDraw
root = Path(__file__).resolve().parents[1]
files = sorted((root/'assets/references/Minecraft screenshots').glob('*.png'))
sheet = Image.new('RGB', (1200, ((len(files)+2)//3)*250), '#151b24')
d = ImageDraw.Draw(sheet)
for i,p in enumerate(files):
    im = Image.open(p).convert('RGB'); im.thumbnail((394,218))
    x,y=(i%3)*400,(i//3)*250
    sheet.paste(im,(x,y)); d.text((x+5,y+222),p.stem,fill='white')
(root/'docs').mkdir(exist_ok=True)
sheet.save(root/'docs/reference_contact.jpg',quality=92)

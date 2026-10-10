"""Snap generated scene art to a genuine limited-palette pixel grid.
Run only once per freshly generated source. Original tool outputs stay preserved.
"""
from PIL import Image
from pathlib import Path
for path in Path('assets/art/backgrounds').glob('*.png'):
    im=Image.open(path).convert('RGB').resize((320,180),Image.Resampling.NEAREST)
    im=im.quantize(colors=32,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE)
    im.convert('RGB').resize((1280,720),Image.Resampling.NEAREST).save(path)
    print(path)

import os
from fontTools.ttLib import TTFont

src = 'polices'
dst = os.path.join('assets', 'fonts')
os.makedirs(dst, exist_ok=True)

for name in os.listdir(src):
    if name.endswith('.woff2') or name.endswith('.woff'):
        font = TTFont(os.path.join(src, name))
        font.flavor = None
        out = os.path.splitext(name)[0] + '.ttf'
        font.save(os.path.join(dst, out))
        print('OK', out)
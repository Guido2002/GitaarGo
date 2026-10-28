"""Remove PNG alpha for Apple's app-icon requirements after generate_icons.dart.
Tooling dependency: Pillow. Artwork and dimensions are preserved.
"""
import json
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parent.parent
icons = root / 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
for name in {item['filename'] for item in json.loads((icons / 'Contents.json').read_text())['images']}:
    path = icons / name
    with Image.open(path) as source:
        assert source.getextrema()[3] == (255, 255) if source.mode == 'RGBA' else True
        image = source.convert('RGB')
    image.save(path, optimize=True)

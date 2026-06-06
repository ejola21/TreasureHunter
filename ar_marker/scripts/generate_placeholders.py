"""Generate 5 placeholder marker images for Day 1/2 PoC build verification.

Real Seochon photos replace these on Day 3 (per plan_ar_marker.md §4).
Each placeholder has high contrast + unique pattern → ARCore/ARKit can extract
feature points for tracking. (Single-color blanks would fail.)
"""

from PIL import Image, ImageDraw, ImageFont
import os
import random

OUT = os.path.join(os.path.dirname(__file__), "..", "flutter_ar_poc", "assets", "markers")
os.makedirs(OUT, exist_ok=True)

MARKERS = [
    ("daeo_bookstore", "Daeo Bookstore", (0x2C, 0x3E, 0x50), (0xF5, 0xC8, 0x42)),
    ("tongin_market",  "Tongin Market",  (0xC0, 0x39, 0x2B), (0xF5, 0xF5, 0xDC)),
    ("park_nosoo",     "Park No-soo",    (0x16, 0x4A, 0x2E), (0xE8, 0xD4, 0x8C)),
    ("cafe_sticker_1", "Cafe Slow",      (0x6B, 0x2D, 0x5C), (0xFF, 0xC0, 0xCB)),
    ("ghouse_sticker_2","Ghouse Inwang", (0x1A, 0x3D, 0x6E), (0xF0, 0xE6, 0x8C)),
]

SIZE = 1024  # 1024x1024, ARKit/ARCore 권장 해상도

def make(name: str, label: str, bg: tuple, fg: tuple):
    img = Image.new("RGB", (SIZE, SIZE), bg)
    d = ImageDraw.Draw(img)

    # 무작위 도형으로 특징점 풍부하게 채움 (인식률 ↑)
    rng = random.Random(hash(name) & 0xFFFFFFFF)
    for _ in range(60):
        x1 = rng.randint(0, SIZE)
        y1 = rng.randint(0, SIZE)
        x2 = x1 + rng.randint(20, 200)
        y2 = y1 + rng.randint(20, 200)
        shape = rng.choice(["rect", "ellipse", "line"])
        c = (
            rng.randint(0, 255),
            rng.randint(0, 255),
            rng.randint(0, 255),
        )
        if shape == "rect":
            d.rectangle([x1, y1, x2, y2], outline=c, width=3)
        elif shape == "ellipse":
            d.ellipse([x1, y1, x2, y2], outline=c, width=3)
        else:
            d.line([x1, y1, x2, y2], fill=c, width=4)

    # 가운데 라벨
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 72)
    except Exception:
        font = ImageFont.load_default()
    bbox = d.textbbox((0, 0), label, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    cx, cy = (SIZE - tw) // 2, (SIZE - th) // 2
    # 검정 외곽
    for ox in (-3, 0, 3):
        for oy in (-3, 0, 3):
            d.text((cx + ox, cy + oy), label, font=font, fill=(0, 0, 0))
    d.text((cx, cy), label, font=font, fill=fg)

    # 우측 하단 작은 ID
    d.text((SIZE - 200, SIZE - 40), name, font=ImageFont.load_default(), fill=fg)

    path = os.path.join(OUT, f"{name}.png")
    img.save(path, "PNG", optimize=True)
    print(f"  ✓ {path}")


if __name__ == "__main__":
    print(f"Generating {len(MARKERS)} placeholder markers → {os.path.abspath(OUT)}")
    for m in MARKERS:
        make(*m)
    print("Done. Replace with real Seochon photos on Day 3.")

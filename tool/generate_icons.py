"""Builds the app icon layers in assets/icon/ from assets/icon/logo_source.png
(the flame-and-tree logo on a white page).

Run: python tool/generate_icons.py  (needs numpy + Pillow), then
     dart run flutter_launcher_icons
     dart run flutter_native_splash:create
"""
import numpy as np
from PIL import Image

SRC = "assets/icon/logo_source.png"
OUT = 1024
PAPER = (253, 250, 244)   # icon background, also the splash colour


def extract_logo():
    """Logo with real transparency: white page -> alpha, colours un-blended."""
    rgb = np.asarray(Image.open(SRC).convert("RGB"), np.float32)
    alpha = np.clip((245 - rgb.min(-1)) / 190.0, 0, 1)
    a = np.maximum(alpha, 1e-3)[..., None]
    color = np.clip((rgb - 255 * (1 - a)) / a, 0, 255)
    rgba = np.dstack([color, alpha * 255]).astype(np.uint8)
    im = Image.fromarray(rgba, "RGBA")
    return im.crop(im.getchannel("A").point(lambda v: 255 if v > 24 else 0).getbbox())


def place(logo, height_frac, bg=None):
    h = int(OUT * height_frac)
    w = int(logo.width * h / logo.height)
    art = logo.resize((w, h), Image.LANCZOS)
    canvas = Image.new("RGBA", (OUT, OUT), bg or (0, 0, 0, 0))
    canvas.alpha_composite(art, ((OUT - w) // 2, (OUT - h) // 2))
    return canvas


def mono(layer):
    a = layer.getchannel("A")
    out = Image.new("RGBA", layer.size, (255, 255, 255, 0))
    out.putalpha(a)
    return out


if __name__ == "__main__":
    logo = extract_logo()
    out = lambda n: f"assets/icon/{n}"
    place(logo, 0.66, PAPER + (255,)).convert("RGB").save(out("icon.png"))
    fg = place(logo, 0.78)                      # launcher insets adaptive art ~16%
    fg.save(out("icon_foreground.png"))
    mono(fg).save(out("icon_monochrome.png"))
    Image.new("RGB", (OUT, OUT), PAPER).save(out("icon_background.png"))
    print("wrote assets/icon/*")

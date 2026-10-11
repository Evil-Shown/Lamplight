"""Renders the Lamplight app icon layers into assets/icon/.

A warm flame glowing above an open book on an espresso background.
Run: python tool/generate_icons.py  (needs Pillow), then
     dart run flutter_launcher_icons
"""
import math
import os

from PIL import Image, ImageChops, ImageDraw, ImageFilter

S = 2048          # supersampled canvas
OUT = 1024        # final size
K = S / 1024      # design coordinates are in 1024 space

ESPRESSO = (30, 21, 18)
WALNUT = (74, 44, 38)
CREAM = (255, 242, 223)
CREAM_SHADE = (236, 214, 184)
PAGE_EDGE = (150, 104, 72)
GOLD = (255, 218, 150)
AMBER = (232, 140, 52)


def pt(x, y):
    return (x * K, y * K)


def bezier(p0, p1, p2, n=40):
    pts = []
    for i in range(n + 1):
        t = i / n
        x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0]
        y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1]
        pts.append(pt(x, y))
    return pts


def cubic(p0, p1, p2, p3, n=60):
    pts = []
    for i in range(n + 1):
        t = i / n
        a, b, c, d = (1 - t) ** 3, 3 * (1 - t) ** 2 * t, 3 * (1 - t) * t * t, t ** 3
        pts.append(pt(a * p0[0] + b * p1[0] + c * p2[0] + d * p3[0],
                      a * p0[1] + b * p1[1] + c * p2[1] + d * p3[1]))
    return pts


def radial(size, center, radius, inner, outer, power=1.6):
    """RGBA radial gradient; inner/outer are RGBA tuples."""
    small = 256
    img = Image.new("RGBA", (small, small))
    px = img.load()
    cx, cy = center[0] / size * small, center[1] / size * small
    r = radius / size * small
    for y in range(small):
        for x in range(small):
            d = min(math.hypot(x - cx, y - cy) / r, 1.0) ** power
            px[x, y] = tuple(int(inner[i] + (outer[i] - inner[i]) * d) for i in range(4))
    return img.resize((size, size), Image.BICUBIC)


def vgradient(size, top, bottom):
    img = Image.new("RGBA", (1, size))
    for y in range(size):
        t = y / (size - 1)
        img.putpixel((0, y), tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(4)))
    return img.resize((size, size))


def flame_points(cx, tip_y, base_y, half_w, scale=1.0):
    """Teardrop: pointed top, round belly."""
    h = base_y - tip_y
    right = cubic((cx, tip_y), (cx + half_w * 0.15, tip_y + h * 0.32),
                  (cx + half_w * 1.05, tip_y + h * 0.5), (cx + half_w * 0.98, tip_y + h * 0.74))
    belly = cubic((cx + half_w * 0.98, tip_y + h * 0.74), (cx + half_w * 0.9, base_y + 6),
                  (cx - half_w * 0.9, base_y + 6), (cx - half_w * 0.98, tip_y + h * 0.74))
    left = cubic((cx - half_w * 0.98, tip_y + h * 0.74), (cx - half_w * 1.05, tip_y + h * 0.5),
                 (cx - half_w * 0.15, tip_y + h * 0.32), (cx, tip_y))
    return right + belly[1:] + left[1:]


def foreground(mono=False, halo=True):
    """Transparent layer; artwork stays inside the 66% adaptive safe zone."""
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ink = (255, 255, 255, 255)

    if halo and not mono:
        glow = radial(S, pt(512, 440), 400 * K, (255, 186, 100, 150), (255, 186, 100, 0))
        layer = Image.alpha_composite(layer, glow)

    # --- open book -------------------------------------------------------
    def page(sign, fill):
        spine_top, spine_bot = (512, 668), (512, 788)
        outer_top, outer_bot = (512 + sign * 262, 626), (512 + sign * 262, 738)
        top = bezier(spine_top, (512 + sign * 120, 600), outer_top)
        bot = bezier(outer_bot, (512 + sign * 130, 712), spine_bot)
        return top + bot, fill

    def cover(sign):
        # thin lower edge giving the book thickness
        a = bezier((512 + sign * 262, 738), (512 + sign * 130, 712), (512, 788))
        b = [(x, y + 26 * K) for x, y in reversed(a)]
        return a + b

    d = ImageDraw.Draw(layer)
    for sign in (-1, 1):
        d.polygon(cover(sign), fill=ink if mono else PAGE_EDGE + (255,))
    for sign, shade in ((-1, CREAM_SHADE), (1, CREAM)):
        poly, fill = page(sign, shade)
        d.polygon(poly, fill=ink if mono else fill + (255,))
    if not mono:
        d.line([pt(512, 668), pt(512, 788)], fill=PAGE_EDGE + (255,), width=int(5 * K))
        # faint text lines
        for sign in (-1, 1):
            for i, y in enumerate((676, 704)):
                x0, x1 = 512 + sign * 50, 512 + sign * (210 - i * 28)
                yy0, yy1 = y + 6, y - 16 + 14
                d.line([pt(x0, yy0 + 14), pt(x1, yy1 + 8)],
                       fill=(176, 140, 108, 150), width=int(5 * K))

    # --- flame -----------------------------------------------------------
    outer = flame_points(512, 238, 590, 98)
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).polygon(outer, fill=255)
    if mono:
        layer.paste(Image.new("RGBA", (S, S), ink), (0, 0), mask)
    else:
        grad = vgradient(S, GOLD + (255,), AMBER + (255,))
        layer.paste(grad, (0, 0), mask)
    inner = flame_points(512, 360, 580, 52)
    imask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(imask).polygon(inner, fill=255)
    if mono:
        layer.paste(Image.new("RGBA", (S, S), (0, 0, 0, 0)), (0, 0), imask)  # cut-out
    else:
        layer.paste(Image.new("RGBA", (S, S), (255, 248, 226, 255)), (0, 0), imask)
    return layer


def enlarge(layer, factor=1.4):
    """Adaptive icons are inset ~16% by the launcher; scale art up to compensate."""
    crop = int(S / factor)
    off = (S - crop) // 2
    return layer.crop((off, off, off + crop, off + crop)).resize((S, S), Image.LANCZOS)


def background():
    bg = Image.new("RGBA", (S, S), ESPRESSO + (255,))
    glow = radial(S, pt(512, 470), 760 * K, WALNUT + (255,), ESPRESSO + (255,), power=1.2)
    return Image.alpha_composite(bg, glow)


def save(img, name, flatten=False):
    img = img.resize((OUT, OUT), Image.LANCZOS)
    if flatten:
        img = img.convert("RGB")
    img.save(os.path.join("assets", "icon", name))


if __name__ == "__main__":
    os.makedirs(os.path.join("assets", "icon"), exist_ok=True)
    bg, fg = background(), foreground()
    save(Image.alpha_composite(bg, fg), "icon.png", flatten=True)
    save(enlarge(foreground(halo=False)), "icon_foreground.png")
    save(bg, "icon_background.png", flatten=True)
    save(enlarge(foreground(mono=True)), "icon_monochrome.png")
    print("wrote assets/icon/*")

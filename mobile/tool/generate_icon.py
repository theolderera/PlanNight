#!/usr/bin/env python3
"""Generate the PlanNight launcher-icon source images.

Draws the brand mark — a light crescent moon with a check on a deep-navy tile —
matching the in-app `AppLogo` painter, and writes two PNGs into assets/icon/:

  icon_full.png        1024x1024, navy rounded tile + moon + check (legacy icon)
  icon_foreground.png  1024x1024, transparent + moon + check (adaptive foreground)

Everything is drawn at 4x and downsampled (LANCZOS) for smooth edges. After
running this, regenerate the platform icons with:

    dart run flutter_launcher_icons

Requires Pillow:  python -m pip install Pillow
"""
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw

NAVY_TOP = (36, 48, 95)     # gradient top
NAVY_BOT = (22, 32, 70)     # gradient bottom
NAVY = (30, 42, 86)         # #1E2A56, the flat brand navy
MOON = (122, 162, 255)      # #7AA2FF
SS = 4                      # supersample factor
OUT = Path(__file__).resolve().parent.parent / "assets" / "icon"


def _moon_and_check(img: Image.Image, cx: float, cy: float, s: float) -> None:
    """Composite the crescent + navy check onto an RGBA image (same ratios as
    lib/core/widgets/app_widgets.dart `_LogoPainter`)."""
    w, h = img.size
    r = s * 0.30

    disc = Image.new("L", (w, h), 0)
    ImageDraw.Draw(disc).ellipse(
        [cx - r*0.15 - r, cy - r, cx - r*0.15 + r, cy + r], fill=255)
    cut = Image.new("L", (w, h), 0)
    cr = r * 0.82
    ccx, ccy = cx + r*0.55, cy - r*0.5
    ImageDraw.Draw(cut).ellipse([ccx - cr, ccy - cr, ccx + cr, ccy + cr], fill=255)

    crescent = ImageChops.subtract(disc, cut)  # disc AND NOT cut
    moon = Image.new("RGBA", (w, h), MOON + (255,))
    img.paste(moon, (0, 0), crescent)

    d = ImageDraw.Draw(img)
    pts = [(cx - r*0.55, cy + r*0.05), (cx - r*0.12, cy + r*0.48), (cx + r*0.62, cy - r*0.42)]
    d.line(pts, fill=NAVY + (255,), width=int(s * 0.06), joint="curve")
    cap = s * 0.03
    for px, py in (pts[0], pts[2]):
        d.ellipse([px - cap, py - cap, px + cap, py + cap], fill=NAVY + (255,))


def build_full(final: int = 1024) -> Image.Image:
    w = final * SS
    # vertical navy gradient
    grad = Image.new("RGBA", (w, w))
    px = grad.load()
    for y in range(w):
        t = y / (w - 1)
        px_row = tuple(int(a * (1 - t) + b * t) for a, b in zip(NAVY_TOP, NAVY_BOT)) + (255,)
        for x in range(w):
            px[x, y] = px_row
    mask = Image.new("L", (w, w), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, w - 1, w - 1], radius=int(0.235 * w), fill=255)
    img = Image.new("RGBA", (w, w), (0, 0, 0, 0))
    img.paste(grad, (0, 0), mask)

    # subtle top-right glow
    glow = Image.new("RGBA", (w, w), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gx, gy, gr = int(w * 0.80), int(w * 0.20), int(w * 0.42)
    for i in range(gr, 0, -1):
        gd.ellipse([gx - i, gy - i, gx + i, gy + i], fill=MOON + (max(0, int(4 * (i / gr))),))
    img = Image.alpha_composite(img, glow)

    _moon_and_check(img, w / 2, w / 2, final * 0.66 * SS)
    return img.resize((final, final), Image.LANCZOS)


def build_foreground(final: int = 1024) -> Image.Image:
    w = final * SS
    img = Image.new("RGBA", (w, w), (0, 0, 0, 0))
    _moon_and_check(img, w / 2, w / 2, final * 0.52 * SS)
    return img.resize((final, final), Image.LANCZOS)


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    build_full().save(OUT / "icon_full.png")
    build_foreground().save(OUT / "icon_foreground.png")
    print(f"Wrote icon_full.png and icon_foreground.png to {OUT}")

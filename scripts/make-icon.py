#!/usr/bin/env python3
# Draws the Nudge app icon and writes Support/AppIcon.png (1024x1024). Standard library only.
import math
import struct
import zlib
from pathlib import Path

SIZE = 1024
SS = 4
RED = (0x7A, 0x0F, 0x0A)
BG = (0xF6, 0xF6, 0xF7)
OUT = Path(__file__).resolve().parent.parent / "Support" / "AppIcon.png"


def in_rounded_rect(x, y, x0, y0, x1, y1, r):
    cx = min(max(x, x0 + r), x1 - r)
    cy = min(max(y, y0 + r), y1 - r)
    return (x - cx) ** 2 + (y - cy) ** 2 <= r * r


def in_background(x, y):
    return in_rounded_rect(x, y, 100, 100, 924, 924, 185)


def half_width(y):
    if y < 430:
        return math.sqrt(max(0, 190 ** 2 - (y - 430) ** 2))
    return 190 + (y - 430) * 80 / 270


def in_bell(x, y):
    if (x - 512) ** 2 + (y - 225) ** 2 <= 40 ** 2:
        return True
    if 240 <= y <= 700 and abs(x - 512) <= half_width(y):
        return True
    if in_rounded_rect(x, y, 232, 690, 792, 750, 30):
        return True
    return (x - 512) ** 2 + (y - 800) ** 2 <= 60 ** 2


def render_pixel(px, py):
    if not (100 <= px < 924 and 100 <= py < 924):
        return b"\x00\x00\x00\x00"
    bg = bell = 0
    for j in range(SS):
        for i in range(SS):
            x = px + (i + 0.5) / SS
            y = py + (j + 0.5) / SS
            if in_background(x, y):
                bg += 1
                if in_bell(x, y):
                    bell += 1
    bg_cov = bg / (SS * SS)
    t = (bell / (SS * SS)) / bg_cov if bg_cov > 0 else 0
    rgb = [round(BG[k] * (1 - t) + RED[k] * t) for k in range(3)]
    return bytes(rgb + [round(255 * bg_cov)])


def chunk(tag, data):
    return (struct.pack(">I", len(data)) + tag + data
            + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF))


def write_png(path, width, height, rows):
    raw = b"".join(rows)
    png = (b"\x89PNG\r\n\x1a\n"
           + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
           + chunk(b"IDAT", zlib.compress(raw, 9))
           + chunk(b"IEND", b""))
    Path(path).write_bytes(png)


def main():
    rows = [b"\x00" + b"".join(render_pixel(px, py) for px in range(SIZE)) for py in range(SIZE)]
    write_png(OUT, SIZE, SIZE, rows)
    print("Wrote Support/AppIcon.png")


if __name__ == "__main__":
    main()

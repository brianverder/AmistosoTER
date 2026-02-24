"""
Generate assets/images/logo.png  — Tercer Tiempo shield logo
Uses the same monogram geometry as the attached PNG (shield + T°)
"""
from PIL import Image, ImageDraw, ImageFont
import os, pathlib, math

SIZE = 512
OUT = pathlib.Path(r'D:\bverdier\Documents\Amistoso TER Web\amistosos_flutter\assets\images\logo.png')

img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# ── Shield path ────────────────────────────────────────────────────────────────
# Classic shield: flat top, two symmetric sides curving inward, pointed bottom.
# Built as a polygon + arc.

W, H = SIZE, SIZE
PAD = 28
CX = W // 2

# Control points (tuned to match the attached logo proportions)
top_left     = (PAD,            PAD + 40)
top_right    = (W - PAD,        PAD + 40)
top_left_c   = (PAD,            PAD + 10)
top_right_c  = (W - PAD,        PAD + 10)
top_mid      = (CX,             PAD)

# Upper arc (top rounded corners + flat top)
upper_poly = [
    (PAD + 32, PAD),          # top-left near center
    (W - PAD - 32, PAD),      # top-right near center
    (W - PAD, PAD + 32),      # top-right corner
    (W - PAD, int(H * 0.52)), # right side mid
    (CX,       H - PAD),      # bottom point
    (PAD,      int(H * 0.52)),# left side mid
    (PAD, PAD + 32),          # top-left corner
]

# Draw filled shield in black
draw.polygon(upper_poly, fill=(0, 0, 0, 255))

# Smooth the top corners with ellipse arcs
r = 32
draw.ellipse([PAD, PAD, PAD + r*2, PAD + r*2], fill=(0, 0, 0, 255))
draw.ellipse([W - PAD - r*2, PAD, W - PAD, PAD + r*2], fill=(0, 0, 0, 255))

# ── Inner white inset (creates the double-line border effect from the logo) ────
BORDER = 18
inner = [
    (upper_poly[0][0] + BORDER,   upper_poly[0][1] + BORDER),
    (upper_poly[1][0] - BORDER,   upper_poly[1][1] + BORDER),
    (upper_poly[2][0] - BORDER,   upper_poly[2][1] + BORDER // 2),
    (upper_poly[3][0] - BORDER,   upper_poly[3][1]),
    (CX,                           H - PAD - BORDER * 2),
    (upper_poly[5][0] + BORDER,   upper_poly[5][1]),
    (upper_poly[6][0] + BORDER,   upper_poly[6][1] + BORDER // 2),
]
draw.polygon(inner, fill=(255, 255, 255, 255))
# Re-fill corners for inner
ri = r - BORDER
if ri > 0:
    draw.ellipse([PAD + BORDER, PAD + BORDER, PAD + BORDER + ri*2, PAD + BORDER + ri*2],
                 fill=(255, 255, 255, 255))
    draw.ellipse([W - PAD - BORDER - ri*2, PAD + BORDER, W - PAD - BORDER, PAD + BORDER + ri*2],
                 fill=(255, 255, 255, 255))

# Re-draw slim outer ring as black (thicker border)
ring = [
    (upper_poly[0][0] + 8,  upper_poly[0][1] + 8),
    (upper_poly[1][0] - 8,  upper_poly[1][1] + 8),
    (upper_poly[2][0] - 8,  upper_poly[2][1] + 4),
    (upper_poly[3][0] - 8,  upper_poly[3][1]),
    (CX,                     H - PAD - 14),
    (upper_poly[5][0] + 8,  upper_poly[5][1]),
    (upper_poly[6][0] + 8,  upper_poly[6][1] + 4),
]
draw.polygon(ring, outline=(0, 0, 0, 255), width=0)

# ── Draw "T°" monogram ─────────────────────────────────────────────────────────
# "T" character (thick strokes, matching the logo's heavy grotesque)
TY = int(H * 0.19)        # top of T
TX = int(W * 0.17)        # left edge of horizontal bar
TW = int(W * 0.58)        # width of horizontal bar
THICK_H = int(H * 0.08)  # horizontal bar thickness
THICK_V = int(W * 0.11)  # vertical stroke thickness

# Horizontal bar
draw.rectangle([TX, TY, TX + TW, TY + THICK_H], fill=(0, 0, 0, 255))

# Vertical stem
stem_x = int(W * 0.385)
stem_y_top = TY
stem_y_bot = int(H * 0.66)
draw.rectangle([stem_x, stem_y_top, stem_x + THICK_V, stem_y_bot], fill=(0, 0, 0, 255))

# ── Degree dot "°" ─────────────────────────────────────────────────────────────
dot_cx = int(W * 0.70)
dot_cy = int(H * 0.26)
dot_r  = int(W * 0.09)
# Outer filled circle
draw.ellipse([dot_cx - dot_r, dot_cy - dot_r, dot_cx + dot_r, dot_cy + dot_r],
             fill=(0, 0, 0, 255))
# Inner white hole
inner_r = int(dot_r * 0.42)
draw.ellipse([dot_cx - inner_r, dot_cy - inner_r, dot_cx + inner_r, dot_cy + inner_r],
             fill=(255, 255, 255, 255))

# ── Save ───────────────────────────────────────────────────────────────────────
OUT.parent.mkdir(parents=True, exist_ok=True)
img.save(str(OUT), 'PNG')
print(f'Saved {OUT}  ({SIZE}x{SIZE} px)')

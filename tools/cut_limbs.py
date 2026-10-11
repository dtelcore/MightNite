"""Cut the stance paintings into overlapping limb textures."""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path("/Users/it/MightNite/assets/processed")

# Polygons are in source-pixel space. Joints are (x, y) on the painting.
CHARACTERS = {
    "Ryuji": {
        "src": ROOT / "Ryuji.png",
        "out": ROOT / "ryuji",
        "pivots": {
            "rear_shoulder": (250, 300),
            "rear_elbow": (175, 400),
            "lead_shoulder": (460, 230),
            "lead_elbow": (530, 360),
            "rear_hip": (340, 610),
            "rear_knee": (200, 790),
            "lead_hip": (450, 600),
            "lead_knee": (560, 820),
        },
        "parts": {
            "rear_upper": [(210, 250), (310, 270), (280, 360), (210, 430), (140, 400), (160, 320)],
            "rear_fore": [(110, 370), (220, 360), (210, 470), (170, 540), (80, 530), (70, 440)],
            "lead_upper": [(420, 175), (510, 170), (500, 260), (570, 340), (620, 430), (500, 430), (450, 320), (410, 230)],
            "lead_fore": [(490, 210), (610, 200), (610, 330), (560, 410), (470, 370), (475, 250)],
            "rear_thigh": [(250, 540), (430, 560), (380, 740), (250, 860), (140, 820), (170, 660)],
            "rear_shin": [(140, 750), (280, 760), (250, 960), (220, 1130), (40, 1130), (60, 960)],
            "lead_thigh": [(400, 540), (560, 530), (640, 700), (620, 860), (500, 840), (420, 680)],
            "lead_shin": [(500, 760), (660, 760), (730, 980), (730, 1140), (520, 1140), (470, 920)],
            "torso": [(280, 30), (500, 40), (480, 200), (450, 400), (520, 560), (440, 740), (310, 760), (270, 600), (250, 420), (240, 240), (270, 80)],
        },
    },
    "Titan": {
        "src": ROOT / "Titan.png",
        "out": ROOT / "titan",
        "pivots": {
            "rear_shoulder": (250, 210),
            "rear_elbow": (168, 402),
            "lead_shoulder": (560, 200),
            "lead_elbow": (600, 400),
            "rear_hip": (320, 540),
            "rear_knee": (210, 730),
            "lead_hip": (500, 540),
            "lead_knee": (564, 712),
        },
        "parts": {
            "rear_upper": [(150, 120), (310, 140), (290, 300), (210, 430), (90, 400), (110, 250)],
            "rear_fore": [(30, 360), (210, 350), (220, 520), (170, 640), (30, 620), (20, 470)],
            "lead_upper": [(480, 100), (710, 110), (750, 280), (710, 410), (560, 440), (500, 300), (470, 170)],
            "lead_fore": [(540, 370), (760, 360), (770, 540), (700, 650), (520, 630), (510, 480), (530, 400)],
            "rear_thigh": [(190, 480), (420, 500), (380, 720), (240, 840), (110, 780), (140, 600)],
            "rear_shin": [(90, 720), (280, 720), (260, 960), (240, 1140), (20, 1140), (30, 920)],
            "lead_thigh": [(420, 470), (640, 480), (660, 660), (600, 780), (470, 760), (400, 600)],
            "lead_shin": [(470, 680), (660, 670), (720, 900), (710, 1140), (490, 1140), (450, 860)],
            "torso": [(310, 10), (480, 10), (470, 180), (450, 400), (500, 560), (430, 680), (320, 680), (280, 520), (270, 220), (300, 40)],
        },
    },
}

JOINT_LINKS = {
    "rear_upper": "rear_shoulder",
    "rear_fore": "rear_elbow",
    "lead_upper": "lead_shoulder",
    "lead_fore": "lead_elbow",
    "rear_thigh": "rear_hip",
    "rear_shin": "rear_knee",
    "lead_thigh": "lead_hip",
    "lead_shin": "lead_knee",
}


def mask_from_polygon(size, polygon):
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).polygon(polygon, fill=255)
    return mask


def dilate(mask, radius):
    if radius <= 0:
        return mask
    return mask.filter(__import__("PIL.ImageFilter", fromlist=["MaxFilter"]).MaxFilter(radius * 2 + 1))


def _or_mask(a, b):
    return Image.frombytes("L", a.size, bytes(max(x, y) for x, y in zip(a.tobytes(), b.tobytes())))


def _and_mask(a, b):
    return Image.frombytes("L", a.size, bytes(x if y else 0 for x, y in zip(a.tobytes(), b.tobytes())))


def _and_not(a, b):
    return Image.frombytes("L", a.size, bytes(x if y == 0 else 0 for x, y in zip(a.tobytes(), b.tobytes())))


def _disk(size, center, radius):
    blob = Image.new("L", size, 0)
    x, y = center
    ImageDraw.Draw(blob).ellipse((x - radius, y - radius, x + radius, y + radius), fill=255)
    return blob


def cut_character(spec):
    im = Image.open(spec["src"]).convert("RGBA")
    w, h = im.size
    opaque = im.split()[-1]
    spec["out"].mkdir(parents=True, exist_ok=True)
    limb_names = [name for name in spec["parts"] if name != "torso"]
    raw = {name: mask_from_polygon((w, h), spec["parts"][name]) for name in limb_names}
    # The torso polygon is the body that must stay put. Limbs keep everything
    # outside it, plus a disk at the joint so a bend does not open a gap.
    torso_poly = mask_from_polygon((w, h), spec["parts"]["torso"])
    limb_masks = {}
    for name in limb_names:
        # Keep the limb outside the torso, plus the slice of the limb polygon
        # that crosses the torso near the joint. A free circle would copy the
        # belt and the other arm onto this piece.
        joint = spec["pivots"][JOINT_LINKS[name]]
        cap = _and_mask(raw[name], _disk((w, h), joint, 58))
        limb_masks[name] = _or_mask(_and_not(raw[name], torso_poly), cap)
    claimed = Image.new("L", (w, h), 0)
    for mask in raw.values():
        claimed = _or_mask(claimed, mask)
    # Unclaimed body pixels (sashes, tails) stay on the torso.
    torso = Image.frombytes("L", (w, h), bytes(
        255 if (o > 16 and (t > 0 or c == 0)) else 0
        for o, t, c in zip(opaque.tobytes(), torso_poly.tobytes(), claimed.tobytes())
    ))
    for joint in ("rear_shoulder", "lead_shoulder", "rear_hip", "lead_hip"):
        torso = _or_mask(torso, _disk((w, h), spec["pivots"][joint], 26))
    parts = dict(limb_masks)
    parts["torso"] = torso
    for name, mask in parts.items():
        # Clip to the original silhouette.
        clipped = Image.frombytes("L", (w, h), bytes(
            [m if o > 16 else 0 for m, o in zip(mask.tobytes(), opaque.tobytes())]
        ))
        part = im.copy()
        part.putalpha(clipped)
        part.save(spec["out"] / f"{name}.png")
    print(spec["src"].name, "->", spec["out"])


def main():
    for spec in CHARACTERS.values():
        cut_character(spec)


if __name__ == "__main__":
    main()

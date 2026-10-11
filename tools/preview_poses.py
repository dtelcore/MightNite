"""Render a few rig poses with the same joint math the game uses."""
import math
from pathlib import Path
from PIL import Image

ROOT = Path("/Users/it/MightNite/assets/processed")
PIVOTS = {
    "Ryuji": {
        "rear_shoulder": (250, 300), "rear_elbow": (175, 400),
        "lead_shoulder": (460, 230), "lead_elbow": (530, 360),
        "rear_hip": (340, 610), "rear_knee": (200, 790),
        "lead_hip": (450, 600), "lead_knee": (560, 820),
    },
    "Titan": {
        "rear_shoulder": (250, 210),         "rear_elbow": (168, 402),
        "lead_shoulder": (560, 200), "lead_elbow": (600, 400),
        "rear_hip": (320, 540), "rear_knee": (210, 730),
        "lead_hip": (500, 540), "lead_knee": (564, 712),
    },
}
ORDER = [
    ("rear_shin", "rear_hip", "rear_knee"),
    ("rear_thigh", "rear_hip", None),
    ("rear_fore", "rear_shoulder", "rear_elbow"),
    ("rear_upper", "rear_shoulder", None),
    ("torso", None, None),
    ("lead_shin", "lead_hip", "lead_knee"),
    ("lead_thigh", "lead_hip", None),
    ("lead_fore", "lead_shoulder", "lead_elbow"),
    ("lead_upper", "lead_shoulder", None),
]


def rot(p, origin, angle):
    x, y = p[0] - origin[0], p[1] - origin[1]
    c, s = math.cos(angle), math.sin(angle)
    return (origin[0] + x * c - y * s, origin[1] + x * s + y * c)


def pose_idle():
    return {}


def pose_walk(phase):
    c = math.cos(phase * math.tau)
    s = math.sin(phase * math.tau)
    return {
        "lead_hip": 0.34 * c,
        "rear_hip": -0.34 * c,
        "lead_knee": 0.62 * max(s, 0.0),
        "rear_knee": -0.62 * max(-s, 0.0),
        "lead_shoulder": -0.30 * c,
        "rear_shoulder": 0.30 * c,
        "lead_elbow": 0.28 * max(-c, 0.0),
        "rear_elbow": -0.28 * max(c, 0.0),
        "bob": 18.0 * abs(s),
    }


def pose_squat(amount):
    return {
        "lead_knee": 0.7 * amount,
        "rear_knee": -0.7 * amount,
        "lead_hip": 0.18 * amount,
        "rear_hip": -0.18 * amount,
        "bob": 78.0 * amount,
    }


def pose_jump(amount):
    return {
        "lead_hip": 0.32 * amount,
        "rear_hip": -0.32 * amount,
        "lead_knee": -0.2 * amount,
        "rear_knee": 0.2 * amount,
        "lead_shoulder": -0.2 * amount,
        "rear_shoulder": -0.2 * amount,
        "bob": -20.0 * amount,
    }


def extension(weight):
    if weight < 0.22:
        return -0.35 * (weight / 0.22)
    return -0.35 + 1.35 * ((weight - 0.22) / 0.78)


def pose_punch(weight):
    ext = extension(weight)
    return {
        "lead_shoulder": -0.85 * ext,
        "lead_elbow": -0.18 * ext,
        "rear_shoulder": 0.22 * ext,
    }


def pose_kick(weight):
    snap = min(weight / 0.4, 1.0)
    out = max(0.0, (weight - 0.28) / 0.72)
    out = min(out, 1.0)
    return {
        "lead_hip": -0.7 * snap,
        "lead_knee": 0.55 * snap * (1.0 - out),
        "rear_shoulder": -0.18 * snap,
        "lead_shoulder": 0.22 * snap,
    }


def render(name, angles, label):
    folder = ROOT / name.lower()
    piv = PIVOTS[name]
    bob = angles.get("bob", 0.0)
    base = Image.open(folder / "torso.png")
    canvas = Image.new("RGBA", base.size, (18, 20, 26, 255))
    for part, pivot_name, child_name in ORDER:
        im = Image.open(folder / f"{part}.png").convert("RGBA")
        if pivot_name is None:
            if bob:
                shifted = Image.new("RGBA", im.size, (0, 0, 0, 0))
                shifted.paste(im, (0, int(round(bob))))
                im = shifted
            canvas.alpha_composite(im)
            continue
        parent = piv[pivot_name]
        origin = (parent[0], parent[1] + (bob if "shoulder" in pivot_name else 0.0))
        angle = angles.get(pivot_name, 0.0)
        if child_name:
            joint = piv[child_name]
            moved = rot(joint, (parent[0], parent[1] + (bob if "shoulder" in pivot_name else 0.0)), angles.get(pivot_name, 0.0))
            # Shin/fore also carries the parent rotation.
            angle = angles.get(pivot_name, 0.0) + angles.get(child_name, 0.0)
            origin = moved
            # Pixels rotate around the original child joint, then the parent transform.
            # Do it in one affine via a two-step paste using Image.transform.
        _paste_rotated(canvas, im, origin, angle, piv, pivot_name, child_name, bob)
    canvas.thumbnail((280, 420))
    return canvas.convert("RGB"), label


def _paste_rotated(canvas, im, origin, angle, piv, pivot_name, child_name, bob):
    """Rotate part pixels with the hierarchical joint transform."""
    if abs(angle) < 0.001 and abs(bob) < 0.5:
        canvas.alpha_composite(im)
        return
    # Build the source->dest mapping by transforming the four corners and using affine.
    # Hierarchical: p' = origin + R(angle) * (p - joint0)
    # For a single bone, joint0 is the pivot and origin is the pivot (plus bob).
    # For a child bone, origin is the moved joint and joint0 is the original child joint,
    # and angle already includes the parent rotation. That maps original pixels correctly
    # only if origin = R_parent(joint) and angle = parent+child. Check:
    # p' = moved_joint + R(parent+child) * (p - joint)
    # moved_joint = parent_origin + R(parent) * (joint - parent)
    # Yes, that is the full chain. joint0 = original child joint.
    if child_name:
        joint0 = piv[child_name]
    else:
        joint0 = piv[pivot_name]
        origin = (piv[pivot_name][0], piv[pivot_name][1] + (bob if "shoulder" in pivot_name else 0.0))
        angle = angles_safe(pivot_name)
    # The angle/origin for child was passed in. For parent, recompute here if needed.
    _blit(canvas, im, joint0, origin, angle)


# The function above got tangled. A cleaner renderer follows in main().
def angles_safe(_name):
    return 0.0


MARGIN = 280


def _blit(canvas, im, joint, origin, angle):
    joint = (joint[0] + MARGIN, joint[1] + MARGIN)
    origin = (origin[0] + MARGIN, origin[1] + MARGIN)
    # Inverse map: for each dest pixel, sample source.
    # dest = origin + R(angle) * (src - joint)
    # src = joint + R(-angle) * (dest - origin)
    c, s = math.cos(-angle), math.sin(-angle)
    # src_x = joint.x + (dx)*c - (dy)*s
    # src_y = joint.y + (dx)*s + (dy)*c
    # dx = dest_x - origin.x, dy = dest_y - origin.y
    # src_x = c*dest_x - s*dest_y + (joint.x - c*origin.x + s*origin.y)
    # src_y = s*dest_x + c*dest_y + (joint.y - s*origin.x - c*origin.y)
    a = c
    b = -s
    d = s
    e = c
    f = joint[0] - c * origin[0] + s * origin[1]
    g = joint[1] - s * origin[0] - c * origin[1]
    big = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    big.paste(im, (MARGIN, MARGIN))
    warped = big.transform(big.size, Image.AFFINE, (a, b, f, d, e, g), resample=Image.BICUBIC)
    canvas.alpha_composite(warped)


def draw_pose(name, angles):
    folder = ROOT / name.lower()
    piv = PIVOTS[name]
    bob = float(angles.get("bob", 0.0))
    base = Image.open(folder / "torso.png")
    canvas = Image.new("RGBA", (base.size[0] + MARGIN * 2, base.size[1] + MARGIN * 2), (18, 20, 26, 255))
    for part, pivot_name, child_name in ORDER:
        im = Image.open(folder / f"{part}.png").convert("RGBA")
        if pivot_name is None:
            placed = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
            placed.paste(im, (MARGIN, MARGIN + int(round(bob))), im)
            canvas.alpha_composite(placed)
            continue
        parent_angle = float(angles.get(pivot_name, 0.0))
        parent = piv[pivot_name]
        parent_origin = (parent[0], parent[1] + (bob if "shoulder" in pivot_name else 0.0))
        if child_name is None:
            _blit(canvas, im, parent, parent_origin, parent_angle)
            continue
        child = piv[child_name]
        child_angle = parent_angle + float(angles.get(child_name, 0.0))
        moved = rot(child, (parent[0], parent[1] + (bob if "shoulder" in pivot_name else 0.0)), parent_angle)
        _blit(canvas, im, child, moved, child_angle)
    return canvas


def main():
    poses = [
        ("idle", pose_idle()),
        ("walk", pose_walk(0.25)),
        ("squat", pose_squat(1)),
        ("jump", pose_jump(1)),
        ("punch", pose_punch(1)),
        ("kick", pose_kick(1)),
        ("kickwind", pose_kick(0.35)),
    ]
    thumbs = []
    labels = []
    for who in ("Ryuji", "Titan"):
        for label, angles in poses:
            im = draw_pose(who, angles)
            im.thumbnail((180, 270))
            thumbs.append(im.convert("RGB"))
            labels.append(f"{who} {label}")
    cols = len(poses)
    cell_w, cell_h = 180, 290
    sheet = Image.new("RGB", (cols * cell_w, 2 * cell_h), (12, 12, 16))
    from PIL import ImageDraw, ImageFont
    draw = ImageDraw.Draw(sheet)
    for i, (thumb, label) in enumerate(zip(thumbs, labels)):
        x = (i % cols) * cell_w
        y = (i // cols) * cell_h
        sheet.paste(thumb, (x, y + 16))
        draw.text((x + 4, y + 2), label, fill=(230, 230, 230))
    sheet.save("/tmp/pose_sheet.jpg", quality=85)
    print("wrote /tmp/pose_sheet.jpg")


if __name__ == "__main__":
    main()

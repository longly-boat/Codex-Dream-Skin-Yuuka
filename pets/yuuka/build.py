#!/usr/bin/env python3
"""Check or losslessly rebuild the published Yuuka atlas; no app/account access."""
import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent
CELL = (192, 208)
ROWS = [
    ("idle", 6), ("running-right", 8), ("running-left", 8), ("waving", 4),
    ("jumping", 5), ("failed", 8), ("waiting", 6), ("running", 6), ("review", 6),
    ("look-000-to-157.5", 8), ("look-180-to-337.5", 8),
]


def digest(data):
    return hashlib.sha256(data).hexdigest()


def load_sheet(file):
    if not 0 < file.stat().st_size <= 20 * 1024 * 1024:
        raise ValueError(f"Unexpected file size: {file.name}")
    with Image.open(file) as image:
        if image.size != (1536, 2288) or image.format not in ("PNG", "WEBP"):
            raise ValueError("Expected a 1536x2288 PNG/WebP v2 atlas")
        if "A" not in image.getbands():
            raise ValueError("The atlas must retain transparency")
        sheet = image.convert("RGBA")
    for row, (name, count) in enumerate(ROWS):
        for column in range(8):
            alpha = frame(sheet, row, column).getchannel("A")
            present = alpha.getbbox() is not None
            if present != (column < count):
                raise ValueError(f"Unexpected occupied/empty cell: {name}[{column}]")
            if present and alpha.getextrema()[0] != 0:
                raise ValueError(f"Opaque background: {name}[{column}]")
    return sheet


def frame(sheet, row, column):
    x, y = column * CELL[0], row * CELL[1]
    return sheet.crop((x, y, x + CELL[0], y + CELL[1]))


def check():
    metadata = json.loads((ROOT / "manifest.json").read_text(encoding="utf-8"))
    source = load_sheet(ROOT / "source/spritesheet.png")
    published = load_sheet(ROOT / "spritesheet.webp")
    if source.tobytes() != published.tobytes():
        raise ValueError("Editable PNG and published WebP have different pixels")
    if digest(published.tobytes()) != metadata["rgbaSha256"]:
        raise ValueError("Published pixel digest does not match manifest")
    expected = [{"name": name, "row": row, "frames": count}
                for row, (name, count) in enumerate(ROWS)]
    if metadata["rows"] != expected:
        raise ValueError("Manifest row order or frame counts changed")
    sums = (ROOT / "SHA256SUMS.txt").read_text(encoding="ascii").splitlines()
    checked = set()
    for line in sums:
        sha, relative = line.split("  ", 1)
        candidate = ROOT / relative
        file = candidate.resolve()
        if not file.is_relative_to(ROOT) or candidate.is_symlink():
            raise ValueError("Checksum path leaves the pet package")
        if digest(file.read_bytes()) != sha:
            raise ValueError(f"Checksum mismatch: {relative}")
        checked.add(relative)
    required = {p.relative_to(ROOT).as_posix() for p in ROOT.rglob("*")
                if p.is_file() and p.name != "SHA256SUMS.txt"
                and "__pycache__" not in p.parts}
    if checked != required or len(sums) != len(checked):
        raise ValueError("Checksum inventory must cover every package file exactly once")
    print(json.dumps({"ok": True, "version": metadata["version"],
                      "populatedFrames": 73, "transparentCells": 15,
                      "filesVerified": len(checked), "rgbaSha256": metadata["rgbaSha256"]}, indent=2))


def build(output):
    source = load_sheet(ROOT / "source/spritesheet.png")
    output.mkdir(parents=True, exist_ok=False)
    file = output / "spritesheet.webp"
    source.save(file, format="WEBP", lossless=True, exact=True, method=6)
    if load_sheet(file).tobytes() != source.tobytes():
        raise ValueError("Lossless encode verification failed")
    metadata = json.loads((ROOT / "manifest.json").read_text(encoding="utf-8"))
    metadata["rgbaSha256"] = digest(source.tobytes())
    metadata["atlasSha256"] = digest(file.read_bytes())
    (output / "manifest.json").write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")
    previews = output / "previews"
    previews.mkdir()
    all_frames = []
    for row, (name, count) in enumerate(ROWS):
        frames = [frame(source, row, column) for column in range(count)]
        if row < 9:
            render_gif(frames, previews / f"{name}.gif")
            all_frames.extend(frames)
    render_gif(all_frames, previews / "all-states.gif")
    render_gif([frame(source, 9 + i // 8, i % 8) for i in range(16)], previews / "look-loop.gif")
    render_gif([frame(source, 0, i) for i in range(6)] +
               [frame(source, 4, i) for i in range(5)] +
               [frame(source, 0, i) for i in range(6)], previews / "idle-jump-idle.gif")
    strip = Image.new("RGBA", (CELL[0] * 6, CELL[1]))
    for i in range(6):
        strip.paste(frame(source, 0, i), (i * CELL[0], 0))
    strip.save(previews / "idle-frames.png")
    contact = Image.new("RGB", (1536, 11 * (208 + 24)), "#edf5fc")
    draw = ImageDraw.Draw(contact)
    for row, (name, count) in enumerate(ROWS):
        y = row * 232
        draw.text((8, y + 5), f"{row}: {name} ({count} frames)", fill="#1b2b49")
        for column in range(count):
            cell = frame(source, row, column)
            contact.paste(cell, (column * 192, y + 24), cell)
    contact.save(previews / "contact-sheet.png")
    print(json.dumps({"built": str(output), "rgbaSha256": metadata["rgbaSha256"],
                      "atlasSha256": metadata["atlasSha256"]}, indent=2))


def render_gif(frames, file):
    # Composite only previews onto a neutral background; the actual atlas retains alpha.
    prepared = []
    for image in frames:
        canvas = Image.new("RGBA", CELL, "#edf5fc")
        canvas.alpha_composite(image)
        prepared.append(canvas.convert("RGB"))
    prepared[0].save(file, save_all=True, append_images=prepared[1:],
                     duration=180, loop=0, disposal=2)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="verify the published package")
    parser.add_argument("--output", type=Path, help="create a NEW output directory from editable source PNG")
    args = parser.parse_args()
    if args.check == (args.output is not None):
        parser.error("choose exactly one of --check or --output NEW_DIRECTORY")
    if args.check:
        check()
    else:
        build(args.output.resolve())

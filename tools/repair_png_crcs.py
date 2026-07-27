#!/usr/bin/env python3
"""Repair incorrect PNG chunk CRC fields without changing pixel data."""

from __future__ import annotations

from pathlib import Path
import argparse
import struct
import tempfile
import zlib

PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


def repair_png(path: Path) -> bool:
    data = path.read_bytes()
    if not data.startswith(PNG_SIGNATURE):
        raise ValueError(f"{path}: invalid PNG signature")

    output = bytearray(PNG_SIGNATURE)
    offset = len(PNG_SIGNATURE)
    changed = False
    saw_iend = False

    while offset < len(data):
        if offset + 12 > len(data):
            raise ValueError(f"{path}: truncated chunk header")

        size = struct.unpack(">I", data[offset : offset + 4])[0]
        chunk_end = offset + 12 + size
        if chunk_end > len(data):
            raise ValueError(f"{path}: truncated chunk payload")

        kind = data[offset + 4 : offset + 8]
        payload = data[offset + 8 : offset + 8 + size]
        stored_crc = struct.unpack(">I", data[offset + 8 + size : chunk_end])[0]
        correct_crc = zlib.crc32(kind + payload) & 0xFFFFFFFF

        output.extend(data[offset : offset + 8 + size])
        output.extend(struct.pack(">I", correct_crc))
        changed = changed or stored_crc != correct_crc
        offset = chunk_end

        if kind == b"IEND":
            saw_iend = True
            output.extend(data[offset:])
            break

    if not saw_iend:
        raise ValueError(f"{path}: missing IEND chunk")

    if changed:
        with tempfile.NamedTemporaryFile(dir=path.parent, delete=False) as handle:
            handle.write(output)
            temporary = Path(handle.name)
        temporary.replace(path)

    return changed


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("root", nargs="?", default="assets")
    args = parser.parse_args()

    root = Path(args.root)
    pngs = sorted(root.rglob("*.png"))
    if not pngs:
        raise SystemExit(f"No PNG files found under {root}")

    repaired = 0
    for path in pngs:
        if repair_png(path):
            repaired += 1
            print(f"REPAIRED {path}")
        else:
            print(f"OK {path}")

    print(f"Repaired {repaired} PNG file(s)")


if __name__ == "__main__":
    main()

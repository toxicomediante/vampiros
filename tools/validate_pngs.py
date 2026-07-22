#!/usr/bin/env python3
"""Fail CI when a tracked PNG has corrupt chunks or image data."""

from pathlib import Path
import struct
import zlib


EXPECTED_ANIMATION_SHEETS = {
    Path("assets/characters/overworld/juan_overworld_animations.png"),
    Path("assets/characters/overworld/michu_overworld_animations.png"),
}


def validate(path: Path) -> None:
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("invalid PNG signature")

    offset = 8
    compressed = bytearray()
    saw_end = False
    color_type = None
    dimensions = None
    while offset < len(data):
        if offset + 12 > len(data):
            raise ValueError("truncated chunk")
        size = struct.unpack(">I", data[offset : offset + 4])[0]
        kind = data[offset + 4 : offset + 8]
        payload_start = offset + 8
        payload_end = payload_start + size
        crc_end = payload_end + 4
        if crc_end > len(data):
            raise ValueError("truncated chunk payload")
        payload = data[payload_start:payload_end]
        expected_crc = struct.unpack(">I", data[payload_end:crc_end])[0]
        actual_crc = zlib.crc32(kind + payload) & 0xFFFFFFFF
        if actual_crc != expected_crc:
            raise ValueError(f"CRC mismatch in {kind.decode('ascii', 'replace')}")
        if kind == b"IDAT":
            compressed.extend(payload)
        if kind == b"IHDR":
            if len(payload) != 13:
                raise ValueError("invalid IHDR chunk")
            dimensions = struct.unpack(">II", payload[:8])
            color_type = payload[9]
        if kind == b"IEND":
            saw_end = True
            break
        offset = crc_end

    if not saw_end:
        raise ValueError("missing IEND chunk")
    zlib.decompress(compressed)
    if color_type not in (3, 6):
        raise ValueError(
            "unsupported asset encoding: expected indexed or RGBA PNG "
            f"(type 3 or 6), got type {color_type}"
        )
    if path in EXPECTED_ANIMATION_SHEETS:
        if dimensions != (576, 512):
            raise ValueError(
                "invalid overworld animation sheet geometry: "
                f"expected 576x512, got {dimensions}"
            )
        if color_type != 6:
            raise ValueError("overworld animation sheets must use RGBA transparency")


def main() -> None:
    pngs = sorted(Path("assets").rglob("*.png"))
    if not pngs:
        raise SystemExit("No PNG assets found")
    failed = False
    for path in pngs:
        try:
            validate(path)
            print(f"OK {path}")
        except (OSError, ValueError, zlib.error) as exc:
            failed = True
            print(f"CORRUPT {path}: {exc}")
    if failed:
        raise SystemExit(1)


if __name__ == "__main__":
    main()

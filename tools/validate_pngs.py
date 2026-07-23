#!/usr/bin/env python3
"""Fail CI when a tracked PNG has corrupt chunks or image data."""

from pathlib import Path
import struct
import zlib


EXPECTED_ANIMATION_SHEETS = {
    Path("assets/characters/overworld/juan_overworld_animations.png"): (576, 512),
    Path("assets/characters/overworld/michu_overworld_animations.png"): (576, 512),
    Path("assets/characters/combat/juan_combat_idle.png"): (2172, 644),
    Path("assets/characters/combat/michu_combat_idle.png"): (2172, 644),
}

LOCKED_COMBAT_IDLE_REGIONS = {
    Path("assets/characters/combat/juan_combat_idle.png"): (
        362,
        6,
        ((34, 548, 128, 612), (205, 568, 336, 644)),
    ),
    Path("assets/characters/combat/michu_combat_idle.png"): (
        362,
        6,
        ((32, 548, 134, 614), (194, 574, 334, 644)),
    ),
}

COMBAT_IDLE_TRAVEL_LIMITS = {
    Path("assets/characters/combat/juan_combat_idle.png"): (362, 6, 40, 90),
    Path("assets/characters/combat/michu_combat_idle.png"): (362, 6, 60, 95),
}


def paeth_predictor(left: int, above: int, upper_left: int) -> int:
    prediction = left + above - upper_left
    distance_left = abs(prediction - left)
    distance_above = abs(prediction - above)
    distance_upper_left = abs(prediction - upper_left)
    if distance_left <= distance_above and distance_left <= distance_upper_left:
        return left
    if distance_above <= distance_upper_left:
        return above
    return upper_left


def decode_rgba_scanlines(compressed: bytes, width: int, height: int) -> list[bytes]:
    """Decode non-interlaced, 8-bit RGBA rows using only the standard library."""
    bytes_per_pixel = 4
    stride = width * bytes_per_pixel
    filtered = zlib.decompress(compressed)
    expected_size = height * (stride + 1)
    if len(filtered) != expected_size:
        raise ValueError(
            f"unexpected decompressed size: expected {expected_size}, got {len(filtered)}"
        )

    rows: list[bytes] = []
    previous = bytearray(stride)
    offset = 0
    for _ in range(height):
        filter_type = filtered[offset]
        source = filtered[offset + 1 : offset + 1 + stride]
        offset += stride + 1
        row = bytearray(stride)
        for index, value in enumerate(source):
            left = row[index - bytes_per_pixel] if index >= bytes_per_pixel else 0
            above = previous[index]
            upper_left = (
                previous[index - bytes_per_pixel]
                if index >= bytes_per_pixel
                else 0
            )
            if filter_type == 0:
                predictor = 0
            elif filter_type == 1:
                predictor = left
            elif filter_type == 2:
                predictor = above
            elif filter_type == 3:
                predictor = (left + above) // 2
            elif filter_type == 4:
                predictor = paeth_predictor(left, above, upper_left)
            else:
                raise ValueError(f"unsupported PNG filter type {filter_type}")
            row[index] = (value + predictor) & 0xFF
        rows.append(bytes(row))
        previous = row
    return rows


def validate_locked_idle_region(
    compressed: bytes,
    dimensions: tuple[int, int],
    frame_width: int,
    frame_count: int,
    locked_regions: tuple[tuple[int, int, int, int], ...],
) -> None:
    width, height = dimensions
    if width != frame_width * frame_count:
        raise ValueError("locked combat idle geometry does not match frame layout")
    rows = decode_rgba_scanlines(compressed, width, height)
    frame_stride = frame_width * 4
    for x0, y0, x1, y1 in locked_regions:
        if not (0 <= x0 < x1 <= frame_width and 0 <= y0 < y1 <= height):
            raise ValueError("locked combat idle region lies outside a frame")
        for y in range(y0, y1):
            reference = rows[y][x0 * 4 : x1 * 4]
            for frame_index in range(1, frame_count):
                start = frame_index * frame_stride + x0 * 4
                candidate = rows[y][start : start + (x1 - x0) * 4]
                if candidate != reference:
                    raise ValueError(
                        "combat idle foot contact drifts from frame 0 "
                        f"in frame {frame_index}, region {(x0, y0, x1, y1)}"
                    )


def validate_idle_motion(
    compressed: bytes,
    dimensions: tuple[int, int],
    frame_width: int,
    frame_count: int,
    minimum_vertical_travel: int,
    maximum_vertical_travel: int,
) -> None:
    width, height = dimensions
    if width != frame_width * frame_count:
        raise ValueError("combat idle motion geometry does not match frame layout")
    rows = decode_rgba_scanlines(compressed, width, height)
    frame_stride = frame_width * 4
    opaque_tops: list[int] = []
    for frame_index in range(frame_count):
        frame_start = frame_index * frame_stride
        top = None
        for y, row in enumerate(rows):
            alpha = row[frame_start + 3 : frame_start + frame_stride : 4]
            if any(value >= 128 for value in alpha):
                top = y
                break
        if top is None:
            raise ValueError(f"combat idle frame {frame_index} is empty")
        opaque_tops.append(top)
    travel = max(opaque_tops) - min(opaque_tops)
    if travel < minimum_vertical_travel:
        raise ValueError(
            "combat idle has lost its body compression: "
            f"expected at least {minimum_vertical_travel}px, got {travel}px"
        )
    if travel > maximum_vertical_travel:
        raise ValueError(
            "combat idle crouches too deeply: "
            f"expected at most {maximum_vertical_travel}px, got {travel}px"
        )


def validate(path: Path) -> None:
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("invalid PNG signature")

    offset = 8
    compressed = bytearray()
    saw_end = False
    color_type = None
    dimensions = None
    bit_depth = None
    interlace_method = None
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
            bit_depth = payload[8]
            color_type = payload[9]
            interlace_method = payload[12]
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
        expected_dimensions = EXPECTED_ANIMATION_SHEETS[path]
        if dimensions != expected_dimensions:
            raise ValueError(
                "invalid animation sheet geometry: "
                f"expected {expected_dimensions}, got {dimensions}"
            )
        if color_type != 6:
            raise ValueError("animation sheets must use RGBA transparency")
    if path in LOCKED_COMBAT_IDLE_REGIONS:
        if bit_depth != 8 or interlace_method != 0:
            raise ValueError(
                "locked combat idle validation requires 8-bit non-interlaced RGBA"
            )
        validate_locked_idle_region(
            bytes(compressed),
            dimensions,
            *LOCKED_COMBAT_IDLE_REGIONS[path],
        )
    if path in COMBAT_IDLE_TRAVEL_LIMITS:
        validate_idle_motion(
            bytes(compressed),
            dimensions,
            *COMBAT_IDLE_TRAVEL_LIMITS[path],
        )


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

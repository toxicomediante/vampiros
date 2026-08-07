#!/usr/bin/env python3
"""Fail when a project PNG has corrupt chunks, data, or locked sheet geometry."""

from pathlib import Path
import struct
import zlib


EXPECTED_ANIMATION_SHEETS = {
    Path("assets/characters/overworld/juan_overworld_animations.png"): (576, 512),
    Path("assets/characters/overworld/michu_overworld_animations.png"): (576, 512),
    Path("assets/characters/combat/juan_combat_idle.png"): (2172, 644),
    Path("assets/characters/combat/michu_combat_idle.png"): (2172, 644),
    Path("assets/enemies/tarantula/idle_atlas.png"): (2896, 1086),
    Path("assets/enemies/tarantula/attack_atlas.png"): (2896, 1086),
    Path("assets/enemies/vampiro_malleiro/idle_atlas.png"): (2172, 1448),
    Path("assets/enemies/vampiro_malleiro/attack_atlas.png"): (2172, 1448),
    Path("assets/enemies/el_fregona/idle_atlas.png"): (2048, 1536),
    Path("assets/enemies/el_fregona/attack_atlas.png"): (2048, 1536),
    Path("assets/enemies/momia/idle_atlas.png"): (2172, 1448),
    Path("assets/enemies/momia/attack_atlas.png"): (2172, 1448),
    Path("assets/enemies/pavo_white_label/idle_atlas.png"): (2172, 1448),
    Path("assets/enemies/pavo_white_label/attack_atlas.png"): (2172, 1448),
    Path("assets/enemies/sequeiros/idle_atlas.png"): (2048, 1536),
    Path("assets/enemies/sequeiros/attack_atlas.png"): (2048, 1536),
    Path("assets/enemies/el_futbolin/idle_atlas.png"): (3072, 1024),
    Path("assets/enemies/el_futbolin/attack_atlas.png"): (3072, 1024),
    Path("assets/enemies/media_croqueta/idle_atlas.png"): (2048, 1536),
    Path("assets/enemies/media_croqueta/attack_atlas.png"): (2048, 1536),
    Path("assets/enemies/pimiento_infernal/idle_atlas.png"): (2048, 1536),
    Path("assets/enemies/pimiento_infernal/attack_atlas.png"): (2048, 1536),
    Path("assets/enemies/pareja_gaitero_dragon/idle_atlas.png"): (2244, 1402),
    Path("assets/enemies/pareja_gaitero_dragon/attack_atlas.png"): (2244, 1402),
    Path("assets/enemies/la_mamona/idle_atlas.png"): (2172, 1448),
    Path("assets/enemies/la_mamona/attack_atlas.png"): (2172, 1448),
    Path("assets/npcs/trujillo/idle_atlas.png"): (2048, 1536),
    Path("assets/npcs/trujillo/dialogue_atlas.png"): (2048, 1536),
}

EXPECTED_RUNTIME_TEXTURES = {
    Path("assets/backgrounds/shop/supermercados_trujillo.png"): (1672, 940),
    Path("assets/backgrounds/combat/pub_meigas.png"): (1672, 940),
    Path("assets/ui/currency/coins.png"): (64, 64),
    Path("assets/ui/combat/energy_states.png"): (1024, 373),
    Path("assets/ui/combat/hp_def_frame.png"): (640, 128),
    Path("assets/ui/combat/hp_bar_base.png"): (453, 41),
    Path("assets/ui/combat/hp_bar_fill.png"): (453, 41),
    Path("assets/ui/combat/def_bar_base.png"): (453, 34),
    Path("assets/ui/combat/def_bar_fill.png"): (453, 34),
    Path("assets/ui/combat/portraits/juan.png"): (96, 96),
    Path("assets/ui/combat/portraits/michu.png"): (96, 96),
    Path("assets/ui/combat/targeting/ouija_target_marker.png"): (72, 112),
    Path("assets/ui/options/options_panel.png"): (1024, 1535),
    Path("assets/ui/options/options_gear.png"): (96, 96),
    Path("assets/ui/options/checkbox_empty.png"): (64, 64),
    Path("assets/ui/options/checkbox_checked.png"): (64, 64),
    Path("assets/ui/options/volume_track.png"): (320, 32),
    Path("assets/ui/options/volume_knob.png"): (48, 48),
    Path("assets/ui/options/boton_salir.png"): (420, 104),
}

REQUIRED_TRANSPARENT_ASSETS = {
    *Path("assets/enemies").rglob("*.png"),
    *Path("assets/npcs").rglob("*.png"),
    Path("assets/ui/currency/coins.png"),
    Path("assets/ui/combat/hp_def_frame.png"),
    Path("assets/ui/combat/energy_states.png"),
    Path("assets/ui/combat/hp_bar_base.png"),
    Path("assets/ui/combat/hp_bar_fill.png"),
    Path("assets/ui/combat/def_bar_base.png"),
    Path("assets/ui/combat/def_bar_fill.png"),
    Path("assets/ui/combat/portraits/juan.png"),
    Path("assets/ui/combat/portraits/michu.png"),
    Path("assets/ui/combat/targeting/ouija_target_marker.png"),
    *Path("assets/ui/options").rglob("*.png"),
    *Path("assets/cards").rglob("*.png"),
}

ENERGY_STATE_SHEET = Path("assets/ui/combat/energy_states.png")
ENERGY_FRAME_WIDTH = 256
ENERGY_FRAME_COUNT = 4

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


def validate_energy_alignment(
    compressed: bytes,
    dimensions: tuple[int, int],
) -> None:
    width, height = dimensions
    if width != ENERGY_FRAME_WIDTH * ENERGY_FRAME_COUNT:
        raise ValueError("energy sheet does not contain four equal-width frames")
    rows = decode_rgba_scanlines(compressed, width, height)
    horizontal_centers: list[float] = []
    opaque_bottoms: list[int] = []
    for frame_index in range(ENERGY_FRAME_COUNT):
        frame_x = frame_index * ENERGY_FRAME_WIDTH
        opaque_points = [
            (x - frame_x, y)
            for y, row in enumerate(rows)
            for x in range(frame_x, frame_x + ENERGY_FRAME_WIDTH)
            if row[x * 4 + 3] > 0
        ]
        if not opaque_points:
            raise ValueError(f"energy frame {frame_index} is empty")
        xs = [point[0] for point in opaque_points]
        ys = [point[1] for point in opaque_points]
        horizontal_centers.append((min(xs) + max(xs)) / 2.0)
        opaque_bottoms.append(max(ys))
    if max(horizontal_centers) - min(horizontal_centers) > 1.0:
        raise ValueError(
            "energy states are not centered on the same horizontal anchor: "
            f"{horizontal_centers}"
        )
    if len(set(opaque_bottoms)) != 1:
        raise ValueError(
            "energy states do not share a fixed baseline: "
            f"{opaque_bottoms}"
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
    if color_type not in (0, 2, 3, 4, 6):
        raise ValueError(
            "unsupported PNG color type: "
            f"expected grayscale, RGB, indexed, grayscale-alpha, or RGBA; got {color_type}"
        )
    if dimensions is None or dimensions[0] <= 0 or dimensions[1] <= 0:
        raise ValueError("invalid or missing PNG dimensions")
    if bit_depth not in (1, 2, 4, 8, 16):
        raise ValueError(f"unsupported PNG bit depth {bit_depth}")
    expected_runtime_dimensions = EXPECTED_RUNTIME_TEXTURES.get(path)
    if path.parts[:2] == ("assets", "cards"):
        expected_runtime_dimensions = (512, 768)
    if (
        expected_runtime_dimensions is not None
        and dimensions != expected_runtime_dimensions
    ):
        raise ValueError(
            "runtime texture exceeds its mobile-safe geometry: "
            f"expected {expected_runtime_dimensions}, got {dimensions}"
        )
    if path in REQUIRED_TRANSPARENT_ASSETS:
        if color_type != 6 or bit_depth != 8 or interlace_method != 0:
            raise ValueError(
                "transparent runtime art must be an 8-bit non-interlaced RGBA PNG"
            )
        rows = decode_rgba_scanlines(bytes(compressed), *dimensions)
        alpha_values = [alpha for row in rows for alpha in row[3::4]]
        if not any(alpha == 0 for alpha in alpha_values):
            raise ValueError("runtime art has no transparent background")
        if not any(alpha == 255 for alpha in alpha_values):
            raise ValueError("runtime art has no fully opaque artwork")
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
    if path == ENERGY_STATE_SHEET:
        if color_type != 6 or bit_depth != 8 or interlace_method != 0:
            raise ValueError(
                "energy alignment validation requires 8-bit non-interlaced RGBA"
            )
        validate_energy_alignment(bytes(compressed), dimensions)


def main() -> None:
    pngs = sorted(
        path
        for root in (Path("assets"), Path("art_source"))
        for path in root.rglob("*.png")
    )
    if not pngs:
        raise SystemExit("No PNG assets found")
    failed = False
    validated = 0
    for path in pngs:
        try:
            validate(path)
            validated += 1
        except (OSError, ValueError, zlib.error) as exc:
            failed = True
            print(f"CORRUPT {path}: {exc}")
    if failed:
        raise SystemExit(1)
    print(f"PNGS OK: {validated} files")


if __name__ == "__main__":
    main()

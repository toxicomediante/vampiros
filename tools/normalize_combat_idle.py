#!/usr/bin/env python3
"""Normalize generated combat-idle sheets around fixed foot contacts.

The source is a six-column RGBA sheet.  Each frame keeps its generated pose,
but the two lower legs are progressively sheared from the knee down so both
feet land on the frame-zero anchors.  The footwear pixels are then copied from
frame zero, making the ground contact exact without freezing the knees or hips.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path

from PIL import Image


FRAME_WIDTH = 362
FRAME_HEIGHT = 644
FRAME_COUNT = 6
ALPHA_THRESHOLD = 128


@dataclass(frozen=True)
class Profile:
    blend_left_x: int
    blend_right_x: int
    warp_start_y: int
    rigid_from_y: int
    back_foot_window: tuple[int, int]
    front_foot_window: tuple[int, int]
    footwear_regions: tuple[tuple[int, int, int, int], ...]


PROFILES = {
    "juan": Profile(
        blend_left_x=140,
        blend_right_x=222,
        warp_start_y=430,
        rigid_from_y=548,
        back_foot_window=(0, 181),
        front_foot_window=(181, FRAME_WIDTH),
        footwear_regions=((34, 548, 128, 612), (205, 568, 336, 644)),
    ),
    "michu": Profile(
        blend_left_x=140,
        blend_right_x=222,
        warp_start_y=430,
        rigid_from_y=548,
        back_foot_window=(0, 181),
        front_foot_window=(181, FRAME_WIDTH),
        footwear_regions=((32, 548, 134, 614), (194, 574, 334, 644)),
    ),
}


def smoothstep(value: float) -> float:
    value = min(1.0, max(0.0, value))
    return value * value * (3.0 - 2.0 * value)


def foot_anchor(frame: Image.Image, window: tuple[int, int]) -> tuple[int, int]:
    """Return the midpoint of the lowest three opaque rows in one foot window."""
    alpha = frame.getchannel("A")
    x0, x1 = window
    points: list[tuple[int, int]] = []
    for y in range(500, FRAME_HEIGHT):
        for x in range(x0, x1):
            if alpha.getpixel((x, y)) >= ALPHA_THRESHOLD:
                points.append((x, y))
    if not points:
        raise ValueError(f"no opaque foot pixels found in window {window}")
    lowest_y = max(y for _, y in points)
    contact_x = [x for x, y in points if y >= lowest_y - 2]
    return round(sum(contact_x) / len(contact_x)), lowest_y


def warp_row(
    source: Image.Image,
    destination: Image.Image,
    y: int,
    left_dx: float,
    right_dx: float,
    blend_left_x: int,
    blend_right_x: int,
) -> None:
    """Continuously shear a row between independently anchored legs."""
    source_pixels = source.load()
    destination_pixels = destination.load()
    destination_left = blend_left_x + left_dx
    destination_right = blend_right_x + right_dx
    destination_span = destination_right - destination_left
    source_span = blend_right_x - blend_left_x

    for destination_x in range(FRAME_WIDTH):
        if destination_x <= destination_left:
            source_x = destination_x - left_dx
        elif destination_x >= destination_right:
            source_x = destination_x - right_dx
        else:
            source_x = blend_left_x + (
                (destination_x - destination_left) * source_span / destination_span
            )
        nearest_x = round(source_x)
        if 0 <= nearest_x < FRAME_WIDTH:
            destination_pixels[destination_x, y] = source_pixels[nearest_x, y]


def anchor_lower_legs(
    frame: Image.Image,
    profile: Profile,
    back_dx: int,
    front_dx: int,
) -> Image.Image:
    output = Image.new("RGBA", frame.size, (0, 0, 0, 0))
    output.alpha_composite(frame.crop((0, 0, FRAME_WIDTH, profile.warp_start_y)))

    transition = profile.rigid_from_y - profile.warp_start_y
    for y in range(profile.warp_start_y, FRAME_HEIGHT):
        progress = smoothstep((y - profile.warp_start_y) / transition)
        warp_row(
            frame,
            output,
            y,
            back_dx * progress,
            front_dx * progress,
            profile.blend_left_x,
            profile.blend_right_x,
        )
    return output


def translate_vertical(frame: Image.Image, dy: int) -> Image.Image:
    translated = Image.new("RGBA", frame.size, (0, 0, 0, 0))
    translated.alpha_composite(frame, (0, dy))
    return translated


def lock_footwear(
    frame: Image.Image,
    reference: Image.Image,
    regions: tuple[tuple[int, int, int, int], ...],
) -> None:
    transparent = Image.new("RGBA", frame.size, (0, 0, 0, 0))
    for region in regions:
        frame.paste(transparent.crop(region), region)
        frame.alpha_composite(reference.crop(region), (region[0], region[1]))


def build_sheet(source_path: Path, output_path: Path, profile: Profile) -> None:
    source = Image.open(source_path).convert("RGBA")
    if source.width != FRAME_WIDTH * FRAME_COUNT or source.height < FRAME_HEIGHT:
        raise ValueError(
            "source must be six 362 px columns and at least 644 px high; "
            f"got {source.size}"
        )

    frames = [
        source.crop((i * FRAME_WIDTH, 0, (i + 1) * FRAME_WIDTH, FRAME_HEIGHT))
        for i in range(FRAME_COUNT)
    ]
    target_back = foot_anchor(frames[0], profile.back_foot_window)
    target_front = foot_anchor(frames[0], profile.front_foot_window)

    normalized: list[Image.Image] = []
    for frame in frames:
        front = foot_anchor(frame, profile.front_foot_window)
        frame = translate_vertical(frame, target_front[1] - front[1])
        back = foot_anchor(frame, profile.back_foot_window)
        front = foot_anchor(frame, profile.front_foot_window)
        corrected = anchor_lower_legs(
            frame,
            profile,
            target_back[0] - back[0],
            target_front[0] - front[0],
        )
        normalized.append(corrected)

    for frame in normalized[1:]:
        lock_footwear(frame, normalized[0], profile.footwear_regions)

    sheet = Image.new(
        "RGBA", (FRAME_WIDTH * FRAME_COUNT, FRAME_HEIGHT), (0, 0, 0, 0)
    )
    for index, frame in enumerate(normalized):
        sheet.alpha_composite(frame, (index * FRAME_WIDTH, 0))
    output_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output_path, optimize=True, compress_level=9)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("character", choices=sorted(PROFILES))
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    build_sheet(args.source, args.output, PROFILES[args.character])


if __name__ == "__main__":
    main()

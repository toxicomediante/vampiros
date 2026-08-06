#!/usr/bin/env python3
"""Remove animation-base-derived frames from every enemy atlas.

The runtime expects a fixed 4x2 atlas with eight frames.  Instead of changing
that contract, each static base-derived cell is replaced by the nearest
non-base frame already present in the same animation.  No pixels are blended,
recoloured, resized, warped, or generated.
"""

from __future__ import annotations

import json
import os
from pathlib import Path
import shutil
from typing import Any

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE_ROOT = ROOT / "art_source" / "runtime_sources" / "assets" / "enemies"
RUNTIME_ROOT = ROOT / "assets" / "enemies"
MANIFEST_ROOT = ROOT / "art_source" / "animation_docs"
ATLAS_COLUMNS = 4
ATLAS_ROWS = 2
FRAME_COUNT = ATLAS_COLUMNS * ATLAS_ROWS

ENEMY_FOLDERS = (
    "tarantula",
    "vampiro_malleiro",
    "el_fregona",
    "momia",
    "pavo_white_label",
    "sequeiros",
    "el_futbolin",
    "media_croqueta",
    "pimiento_infernal",
    "pareja_gaitero_dragon",
    "la_mamona",
)


def fail(message: str) -> None:
    raise ValueError(message)


def frame_box(index: int, frame_size: tuple[int, int]) -> tuple[int, int, int, int]:
    width, height = frame_size
    left = (index % ATLAS_COLUMNS) * width
    top = (index // ATLAS_COLUMNS) * height
    return left, top, left + width, top + height


def images_are_identical(left: Image.Image, right: Image.Image) -> bool:
    return left.size == right.size and left.tobytes() == right.tobytes()


def is_base_derived_frame(frame: Image.Image, base: Image.Image) -> bool:
    """Detect exact bases and recoloured/haloed copies with the same silhouette."""
    if frame.size != base.size:
        return False
    if images_are_identical(frame, base):
        return True
    return frame.getchannel("A").tobytes() == base.getchannel("A").tobytes()


def nearest_non_base_index(index: int, base_indices: set[int]) -> int:
    for distance in range(1, FRAME_COUNT):
        previous = index - distance
        if previous >= 0 and previous not in base_indices:
            return previous
        following = index + distance
        if following < FRAME_COUNT and following not in base_indices:
            return following
    fail("atlas contains no animated frame distinct from animation_base")


def validate_complete_png(path: Path) -> None:
    with Image.open(path) as image:
        image.load()
        if image.mode != "RGBA":
            fail(f"{path} is {image.mode}, expected RGBA")


def atomic_save_png(image: Image.Image, path: Path) -> None:
    temporary = path.with_name(path.name + ".tmp.png")
    try:
        image.save(temporary, format="PNG", optimize=False)
        validate_complete_png(temporary)
        os.replace(temporary, path)
        validate_complete_png(path)
    finally:
        temporary.unlink(missing_ok=True)


def atomic_copy(source: Path, destination: Path) -> None:
    temporary = destination.with_name(destination.name + ".tmp")
    try:
        shutil.copyfile(source, temporary)
        validate_complete_png(temporary)
        os.replace(temporary, destination)
        validate_complete_png(destination)
        if source.read_bytes() != destination.read_bytes():
            fail(f"copy mismatch: {source} -> {destination}")
    finally:
        temporary.unlink(missing_ok=True)


def rebuild_atlas(base: Image.Image, atlas_path: Path) -> tuple[list[int], set[int]]:
    atlas = Image.open(atlas_path).convert("RGBA")
    if atlas.width % ATLAS_COLUMNS or atlas.height % ATLAS_ROWS:
        fail(f"{atlas_path} is not a {ATLAS_COLUMNS}x{ATLAS_ROWS} atlas")

    frame_size = (atlas.width // ATLAS_COLUMNS, atlas.height // ATLAS_ROWS)
    if base.size != frame_size:
        fail(f"{atlas_path} cell {frame_size} does not match base {base.size}")

    frames = [atlas.crop(frame_box(index, frame_size)) for index in range(FRAME_COUNT)]
    base_indices = {
        index for index, frame in enumerate(frames) if is_base_derived_frame(frame, base)
    }
    if not base_indices:
        fail(f"{atlas_path} contains no exact animation_base frame")

    source_indices = [
        nearest_non_base_index(index, base_indices) if index in base_indices else index
        for index in range(FRAME_COUNT)
    ]
    rebuilt = Image.new("RGBA", atlas.size, (0, 0, 0, 0))
    for index, source_index in enumerate(source_indices):
        rebuilt.paste(frames[source_index], frame_box(index, frame_size)[:2])

    for index in range(FRAME_COUNT):
        frame = rebuilt.crop(frame_box(index, frame_size))
        if is_base_derived_frame(frame, base):
            fail(f"{atlas_path} frame {index} is still derived from animation_base")
        alpha = frame.getchannel("A")
        if alpha.getextrema()[0] != 0:
            fail(f"{atlas_path} frame {index} has no transparent background")
        corners = (
            alpha.getpixel((0, 0)),
            alpha.getpixel((frame.width - 1, 0)),
            alpha.getpixel((0, frame.height - 1)),
            alpha.getpixel((frame.width - 1, frame.height - 1)),
        )
        if any(corners):
            fail(f"{atlas_path} frame {index} has a non-transparent corner")

    atomic_save_png(rebuilt, atlas_path)
    return source_indices, base_indices


def update_manifest(
    manifest_path: Path,
    remaps: dict[str, list[int]],
    removed: dict[str, set[int]],
) -> None:
    manifest: dict[str, Any] = json.loads(manifest_path.read_text(encoding="utf-8"))
    manifest.pop("bridge_frames", None)
    manifest["base_frame_policy"] = {
        "contains_animation_base_frames": False,
        "method": "static base-derived cells replaced by nearest existing animated frame",
        "pixel_operations": "copy only; no recolour, interpolation, resize or warp",
    }
    animations = manifest.setdefault("animations", {})
    for animation_name in ("idle", "attack"):
        animation = animations.setdefault(animation_name, {})
        for stale_key in (
            "bridge_frames",
            "bridge_matches_animation_base",
            "start_bridge_frame",
            "end_bridge_frame",
        ):
            animation.pop(stale_key, None)
        animation["contains_animation_base_frames"] = False
        animation["removed_base_frame_indices"] = sorted(removed[animation_name])
        animation["frame_source_indices"] = remaps[animation_name]

    transition = manifest.get("transition")
    if isinstance(transition, dict):
        transition["idle_to_attack"] = (
            "Play attack from frame 0; the fixed 8-frame timing is preserved."
        )
        transition["attack_to_idle"] = (
            "After attack frame 7, resume idle; neither atlas contains animation_base."
        )

    transition_contract = manifest.get("transition_contract")
    if isinstance(transition_contract, dict):
        transition_contract.clear()
        transition_contract.update(
            {
                "idle_to_attack": (
                    "Play attack from frame 0; the fixed 8-frame timing is preserved."
                ),
                "attack_to_idle": (
                    "After attack frame 7, resume idle; neither atlas contains animation_base."
                ),
            }
        )

    validation = manifest.setdefault("validation", {})
    validation.pop("extreme_frame_pixel_difference", None)
    for stale_key in tuple(validation):
        if "bridge" in stale_key:
            validation.pop(stale_key, None)
    validation["contains_animation_base_frames"] = False
    validation["atlas_grid_preserved"] = True
    validation["frame_count_preserved"] = FRAME_COUNT
    validation["transparent_corners"] = True

    manifest_path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def main() -> None:
    report: dict[str, dict[str, Any]] = {}
    for folder in ENEMY_FOLDERS:
        source_dir = SOURCE_ROOT / folder
        runtime_dir = RUNTIME_ROOT / folder
        manifest_dir = MANIFEST_ROOT / folder
        base_path = source_dir / "base.png"
        manifest_path = manifest_dir / f"{folder}_animation_manifest.json"
        if not base_path.is_file() or not manifest_path.is_file():
            fail(f"missing source or manifest for {folder}")

        base = Image.open(base_path).convert("RGBA")
        remaps: dict[str, list[int]] = {}
        removed: dict[str, set[int]] = {}
        for animation_name in ("idle", "attack"):
            source_atlas = source_dir / f"{animation_name}_atlas.png"
            runtime_atlas = runtime_dir / f"{animation_name}_atlas.png"
            remap, base_indices = rebuild_atlas(base, source_atlas)
            atomic_copy(source_atlas, runtime_atlas)
            remaps[animation_name] = remap
            removed[animation_name] = base_indices

        update_manifest(manifest_path, remaps, removed)
        report[folder] = {
            name: {
                "removed_base_frame_indices": sorted(removed[name]),
                "frame_source_indices": remaps[name],
            }
            for name in ("idle", "attack")
        }

    report_path = ROOT / "art_source" / "animation_docs" / "base_frame_removal_report.json"
    report_path.write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()

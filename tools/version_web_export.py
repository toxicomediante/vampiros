#!/usr/bin/env python3
"""Give every Godot Web payload a commit-specific URL.

GitHub Pages and browsers may keep large Web exports in cache. Godot normally
reuses names such as ``index.pck`` and ``index.wasm`` for every deployment, so
an old file can be paired with a newer export. This post-processing step keeps
``index.html`` as the public entry point while renaming every runtime payload
with the build commit and updating Godot's generated HTML accordingly.
"""

from __future__ import annotations

import argparse
from pathlib import Path
import re


BUILD_ID_PATTERN = re.compile(r"[0-9a-f]{7,40}")
RUNTIME_FILES = (
    "index.js",
    "index.pck",
    "index.wasm",
    "index.audio.position.worklet.js",
    "index.audio.worklet.js",
    "index.apple-touch-icon.png",
    "index.icon.png",
    "index.png",
)
CACHE_META = """\
		<meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">
		<meta http-equiv="Pragma" content="no-cache">
		<meta http-equiv="Expires" content="0">
"""


def version_web_export(build_dir: Path, build_id: str) -> None:
    """Rename generated runtime files and rewrite their HTML references."""
    if BUILD_ID_PATTERN.fullmatch(build_id) is None:
        raise ValueError("build id must be a 7-40 character lowercase Git SHA")

    index_path = build_dir / "index.html"
    if not index_path.is_file():
        raise ValueError(f"missing Godot Web entry point: {index_path}")

    missing = [name for name in RUNTIME_FILES if not (build_dir / name).is_file()]
    if missing:
        raise ValueError("missing Godot Web runtime files: " + ", ".join(missing))

    versioned_prefix = f"index-{build_id}"
    html = index_path.read_text(encoding="utf-8")

    executable_token = '"executable":"index"'
    if html.count(executable_token) != 1:
        raise ValueError("could not find exactly one Godot executable setting")
    html = html.replace(
        executable_token,
        f'"executable":"{versioned_prefix}"',
    )

    for source_name in RUNTIME_FILES:
        target_name = source_name.replace("index", versioned_prefix, 1)
        html = html.replace(source_name, target_name)
        (build_dir / source_name).rename(build_dir / target_name)

    head_token = "<head>"
    if html.count(head_token) != 1:
        raise ValueError("could not find exactly one HTML head")
    html = html.replace(
        head_token,
        f'{head_token}\n\t\t<meta name="vampiros-build" content="{build_id}">\n'
        f"{CACHE_META}",
        1,
    )
    index_path.write_text(html, encoding="utf-8")

    stale = [name for name in RUNTIME_FILES if (build_dir / name).exists()]
    if stale:
        raise ValueError("unversioned runtime files remain: " + ", ".join(stale))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("build_dir", type=Path)
    parser.add_argument("build_id")
    args = parser.parse_args()

    try:
        version_web_export(args.build_dir, args.build_id)
    except (OSError, ValueError) as exc:
        raise SystemExit(f"WEB VERSIONING FAILED: {exc}") from exc

    print(f"WEB VERSIONED: {args.build_id}")


if __name__ == "__main__":
    main()

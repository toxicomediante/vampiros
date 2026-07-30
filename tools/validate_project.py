#!/usr/bin/env python3
"""One read-only validation command for the whole Vampiros project."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import re
import subprocess
import sys

import validate_pngs


ROOT = Path(__file__).resolve().parents[1]
os.chdir(ROOT)
REQUIRED_FILES = (
    Path("project.godot"),
    Path("export_presets.cfg"),
    Path("assets/audio/title_la_noche_nos_llama.ogg"),
    Path("assets/audio/overworld_luces_entre_la_bruma.ogg"),
    Path("assets/audio/combat_ultima_ronda_v2.ogg"),
    Path("assets/enemies/tarantula.png"),
    Path("assets/enemies/vampiro_malleiro.png"),
    Path("assets/ui/combat/energy_states.png"),
    Path("assets/ui/combat/hp_def_frame.png"),
    Path("assets/ui/combat/hp_bar_base.png"),
    Path("assets/ui/combat/hp_bar_fill.png"),
    Path("assets/ui/combat/def_bar_base.png"),
    Path("assets/ui/combat/def_bar_fill.png"),
    Path("scenes/combat.tscn"),
    Path("scenes/combat_loader.tscn"),
    Path("scripts/combat.gd"),
    Path("scripts/combat_loader.gd"),
    Path("tools/combat_smoke_test.gd"),
    Path("tools/scene_lifecycle_test.gd"),
    Path("tools/version_web_export.py"),
    Path("tools/test_version_web_export.py"),
    Path("art_source/.gdignore"),
    Path("art_source/runtime_sources/README.md"),
)
RESOURCE_PATTERN = re.compile(r"res://[A-Za-z0-9_./@+\-]+")
SOURCE_FILES = (
    Path("project.godot"),
    *sorted(Path("scenes").rglob("*.tscn")),
    *sorted(Path("scripts").rglob("*.gd")),
)
GODOT_ERROR_PATTERNS = (
    "SCRIPT ERROR:",
    "Parse Error:",
    "Compile Error:",
    "Failed loading resource:",
    "Failed to load script",
    "Error importing",
    "ERR_FILE_CORRUPT",
)


def fail(message: str) -> None:
    raise ValueError(message)


def validate_required_files() -> None:
    missing = [str(path) for path in REQUIRED_FILES if not path.is_file()]
    if missing:
        fail("missing required files: " + ", ".join(missing))

    music_paths = (
        Path("assets/audio/title_la_noche_nos_llama.ogg"),
        Path("assets/audio/overworld_luces_entre_la_bruma.ogg"),
        Path("assets/audio/combat_ultima_ronda_v2.ogg"),
    )
    music_payloads = []
    for music in music_paths:
        payload = music.read_bytes()
        if music.stat().st_size < 100_000 or payload[:4] != b"OggS":
            fail(f"{music} is missing or is not a valid committed OGG file")
        music_payloads.append(payload)
    if len(set(music_payloads)) != len(music_paths):
        fail("title, overworld, and combat must use three distinct music files")


def validate_resource_paths() -> None:
    missing: list[str] = []
    for source in SOURCE_FILES:
        text = source.read_text(encoding="utf-8")
        for reference in RESOURCE_PATTERN.findall(text):
            target = Path(reference.removeprefix("res://"))
            if not target.is_file():
                missing.append(f"{source}: {reference}")
    if missing:
        fail("missing res:// resources:\n  " + "\n  ".join(sorted(set(missing))))


def validate_music_routing() -> None:
    expected = {
        Path("scenes/main.tscn"): "res://assets/audio/title_la_noche_nos_llama.ogg",
        Path("scenes/overworld.tscn"): (
            "res://assets/audio/overworld_luces_entre_la_bruma.ogg"
        ),
        Path("scenes/combat.tscn"): "res://assets/audio/combat_ultima_ronda_v2.ogg",
    }
    expected_files = sorted(
        Path(path.removeprefix("res://")) for path in expected.values()
    )
    actual_files = sorted(Path("assets/audio").glob("*.ogg"))
    if actual_files != expected_files:
        fail(
            "runtime music set does not match title/overworld/combat routing: "
            f"expected={expected_files}, actual={actual_files}"
        )
    for scene, music_path in expected.items():
        text = scene.read_text(encoding="utf-8")
        if text.count(music_path) != 1:
            fail(f"{scene} does not reference exactly one {music_path}")


def validate_asset_boundaries() -> None:
    forbidden_runtime_names = ("preliminary", "no_usable", "checker", "chroma")
    bad_assets = [
        str(path)
        for path in Path("assets").rglob("*")
        if path.is_file()
        and path.suffix != ".import"
        and any(word in path.name.lower() for word in forbidden_runtime_names)
    ]
    if bad_assets:
        fail("source/reference files found inside runtime assets: " + ", ".join(bad_assets))

    source_originals = sorted(Path("art_source/originals").glob("*.png"))
    if len(source_originals) != 16:
        fail(f"expected 16 supplied source images, found {len(source_originals)}")

    source_ready_runtime_paths = {
        *Path("assets/cards").rglob("*.png"),
        *Path("assets/enemies").rglob("*.png"),
        *(
            path
            for path in Path("assets/ui/combat").glob("*.png")
            if path.parent == Path("assets/ui/combat")
        ),
    }
    preserved_source_paths = {
        path.relative_to(Path("art_source/runtime_sources"))
        for path in Path("art_source/runtime_sources/assets").rglob("*.png")
    }
    if preserved_source_paths != source_ready_runtime_paths:
        missing = sorted(source_ready_runtime_paths - preserved_source_paths)
        unexpected = sorted(preserved_source_paths - source_ready_runtime_paths)
        fail(
            "full-resolution runtime sources do not mirror optimized assets: "
            f"missing={missing}, unexpected={unexpected}"
        )

    for music in (
        "assets/audio/title_la_noche_nos_llama.ogg",
        "assets/audio/overworld_luces_entre_la_bruma.ogg",
        "assets/audio/combat_ultima_ronda_v2.ogg",
    ):
        ignored = subprocess.run(
            ["git", "check-ignore", "--quiet", music],
            cwd=ROOT,
            check=False,
        )
        if ignored.returncode == 0:
            fail(f"runtime audio is ignored by Git: {music}")


def validate_combat_loading() -> None:
    combat_script = Path("scripts/combat.gd").read_text(encoding="utf-8")
    forbidden_preloads = (
        'preload("res://assets/cards/',
        'preload("res://assets/backgrounds/combat/',
        'preload("res://assets/characters/combat/',
        'preload("res://assets/characters/juan_idle.png',
        'preload("res://assets/characters/michu_idle.png',
    )
    found = [token for token in forbidden_preloads if token in combat_script]
    if found:
        fail(
            "combat preloads high-resolution optional textures: "
            + ", ".join(found)
        )

    character_select_script = Path("scripts/character_select.gd").read_text(
        encoding="utf-8"
    )
    forbidden_character_preloads = (
        'preload("res://assets/characters/juan_idle.png',
        'preload("res://assets/characters/michu_idle.png',
    )
    found = [
        token
        for token in forbidden_character_preloads
        if token in character_select_script
    ]
    if found:
        fail(
            "character selection retains full character sheets between scenes: "
            + ", ".join(found)
        )

    overworld_script = Path("scripts/overworld.gd").read_text(encoding="utf-8")
    forbidden_overworld_preloads = (
        'preload("res://assets/overworld/',
        'preload("res://assets/characters/overworld/',
    )
    found = [
        token for token in forbidden_overworld_preloads if token in overworld_script
    ]
    if found:
        fail(
            "overworld retains high-resolution textures during combat: "
            + ", ".join(found)
        )
    if 'change_scene_to_file("res://scenes/combat.tscn")' in overworld_script:
        fail("overworld bypasses the low-memory combat loader")
    if "res://scenes/combat_loader.tscn" not in overworld_script:
        fail("overworld does not route combat through the loader scene")

    combat_scene = Path("scenes/combat.tscn").read_text(encoding="utf-8")
    if "color = Color(0.008, 0.012, 0.025, 0)" not in combat_scene:
        fail("combat curtain is not fail-open before runtime initialization")
    if "PORTRAIT_SHEET_PATHS" in combat_script or "_player_portrait_texture" in combat_script:
        fail("compact combat HUD still references the removed player portrait")


def validate_export_settings() -> None:
    text = Path("export_presets.cfg").read_text(encoding="utf-8")
    if "encrypt_pck=true" in text or "encrypt_directory=true" in text:
        fail("an export preset enables encryption")
    if text.count("encrypt_pck=false") != 2:
        fail("both Android and Web must explicitly disable PCK encryption")
    if text.count("encrypt_directory=false") != 2:
        fail("both Android and Web must explicitly disable directory encryption")
    if text.count('encryption_include_filters=""') != 2:
        fail("encryption include filters must be empty in both presets")
    if text.count('encryption_exclude_filters=""') != 2:
        fail("encryption exclude filters must be empty in both presets")
    if text.count('exclude_filter="tools/*"') != 2:
        fail("development-only tools must stay out of both exported builds")


def validate_workflows() -> None:
    workflows = sorted(path.name for path in Path(".github/workflows").glob("*.yml"))
    if workflows != ["android.yml", "web.yml"]:
        fail(f"unexpected workflow set: {workflows}")

    combined = "\n".join(
        path.read_text(encoding="utf-8")
        for path in sorted(Path(".github/workflows").glob("*.yml"))
    )
    forbidden = (
        "contents: write",
        "git push",
        "generate_night_drive",
        "apply_combat_fixes",
        "repair_png_crcs",
    )
    found = [token for token in forbidden if token in combined]
    if found:
        fail("workflows still mutate or generate project files: " + ", ".join(found))

    web = Path(".github/workflows/web.yml").read_text(encoding="utf-8")
    if "MAX_WEB_PCK_BYTES" not in web or "pck_bytes" not in web:
        fail("Web workflow does not enforce the mobile package budget")
    if "scene_lifecycle_test.gd" not in web:
        fail("Web workflow does not test that earlier scenes release their textures")
    if "version_web_export.py" not in web or '"$GITHUB_SHA"' not in web:
        fail("Web workflow does not give each deployment cache-safe filenames")

    android = Path(".github/workflows/android.yml").read_text(encoding="utf-8")
    android_on = android.split("permissions:", 1)[0]
    if "push:" in android_on or "pull_request:" in android_on:
        fail("Android must remain manual-only until the first stable version")


def validate_repository_portability() -> None:
    result = subprocess.run(
        ["git", "ls-files", "-z"],
        cwd=ROOT,
        check=True,
        capture_output=True,
    )
    tracked = [
        Path(raw.decode("utf-8"))
        for raw in result.stdout.split(b"\0")
        if raw
    ]
    casefolded: dict[str, Path] = {}
    for path in tracked:
        key = str(path).casefold()
        if key in casefolded and casefolded[key] != path:
            fail(f"case-insensitive path collision: {casefolded[key]} and {path}")
        casefolded[key] = path
        if path.suffix in {".import"} or path.name == ".DS_Store":
            fail(f"generated local file is tracked: {path}")
        if path.is_file() and path.stat().st_size >= 95 * 1024 * 1024:
            fail(f"file is too large for ordinary GitHub storage: {path}")


def validate_godot_logs(paths: list[Path]) -> None:
    for path in paths:
        text = path.read_text(encoding="utf-8", errors="replace")
        errors = [pattern for pattern in GODOT_ERROR_PATTERNS if pattern in text]
        if errors:
            fail(f"{path} contains Godot errors: {', '.join(errors)}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--godot-log",
        action="append",
        default=[],
        type=Path,
        help="Fail if this Godot log contains known import/script/resource errors.",
    )
    args = parser.parse_args()

    try:
        validate_required_files()
        validate_resource_paths()
        validate_music_routing()
        validate_asset_boundaries()
        validate_combat_loading()
        validate_export_settings()
        validate_workflows()
        validate_repository_portability()
        validate_pngs.main()
        validate_godot_logs(args.godot_log)
    except (OSError, subprocess.CalledProcessError, ValueError) as exc:
        print(f"PROJECT INVALID: {exc}", file=sys.stderr)
        raise SystemExit(1) from exc

    print("PROJECT OK: assets, paths, workflows, exports, PNGs, and logs are valid")


if __name__ == "__main__":
    main()

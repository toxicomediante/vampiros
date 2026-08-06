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
    Path("assets/audio/combat_ultima_ronda.ogg"),
    Path("assets/fonts/press-start-2p-latin-400-normal.woff2"),
    Path("assets/backgrounds/shop/supermercados_trujillo.png"),
    Path("assets/ui/currency/coins.png"),
    Path("assets/npcs/trujillo/idle_atlas.png"),
    Path("assets/npcs/trujillo/dialogue_atlas.png"),
    Path("assets/backgrounds/combat/bar_foreground_01.png"),
    Path("assets/backgrounds/combat/bar_foreground_02.png"),
    Path("assets/ui/combat/energy_states.png"),
    Path("assets/ui/combat/hp_def_frame.png"),
    Path("assets/ui/combat/boton_descartar.png"),
    Path("assets/ui/combat/boton_fin_turno.png"),
    Path("assets/ui/combat/boton_omitir.png"),
    Path("assets/ui/combat/reward_mat.png"),
    Path("scenes/combat.tscn"),
    Path("scenes/combat_loader.tscn"),
    Path("scenes/shop.tscn"),
    Path("scenes/coming_soon.tscn"),
    Path("scripts/combat.gd"),
    Path("scripts/combat_loader.gd"),
    Path("scripts/enemies/enemy_catalog.gd"),
    Path("scripts/shop.gd"),
    Path("scripts/coming_soon.gd"),
    Path("tools/combat_smoke_test.gd"),
    Path("tools/progression_smoke_test.gd"),
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

    enemy_folders = (
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
    missing_enemy_atlases = [
        str(Path("assets/enemies", folder, atlas))
        for folder in enemy_folders
        for atlas in ("idle_atlas.png", "attack_atlas.png")
        if not Path("assets/enemies", folder, atlas).is_file()
    ]
    if missing_enemy_atlases:
        fail("missing enemy atlases: " + ", ".join(missing_enemy_atlases))

    music_paths = (
        Path("assets/audio/title_la_noche_nos_llama.ogg"),
        Path("assets/audio/overworld_luces_entre_la_bruma.ogg"),
        Path("assets/audio/combat_ultima_ronda.ogg"),
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
            if reference.endswith("/") and target.is_dir():
                continue
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
        Path("scenes/combat.tscn"): "res://assets/audio/combat_ultima_ronda.ogg",
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
        *Path("assets/npcs").rglob("*.png"),
        *Path("assets/backgrounds/shop").rglob("*.png"),
        *Path("assets/ui/currency").rglob("*.png"),
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
    if not source_ready_runtime_paths.issubset(preserved_source_paths):
        missing = sorted(source_ready_runtime_paths - preserved_source_paths)
        fail(
            "full-resolution runtime sources do not cover optimized assets: "
            f"missing={missing}"
        )

    for music in (
        "assets/audio/title_la_noche_nos_llama.ogg",
        "assets/audio/overworld_luces_entre_la_bruma.ogg",
        "assets/audio/combat_ultima_ronda.ogg",
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
    combat_ui_script = Path("scripts/combat_ui.gd").read_text(encoding="utf-8")
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
    legacy_bar_textures = (
        "hp_bar_base.png",
        "hp_bar_fill.png",
        "def_bar_base.png",
        "def_bar_fill.png",
    )
    for texture_name in legacy_bar_textures:
        if texture_name in combat_script or texture_name in combat_ui_script:
            fail(f"combat HUD still loads legacy bar texture: {texture_name}")
    required_runtime_bar_tokens = (
        'background.name = node_name',
        'fill.name = "Fill"',
        'const PLAYER_HP_BAR_COLOR := Color(0.78, 0.08, 0.12, 1.0)',
        'const PLAYER_BLOCK_BAR_COLOR := Color(0.34, 0.47, 0.60, 1.0)',
        'player_hp_label.name = "PlayerHPValue"',
        'player_block_label.name = "PlayerBlockValue"',
        'label.add_theme_constant_override("outline_size", 5)',
    )
    for token in required_runtime_bar_tokens:
        if token not in combat_script:
            fail(f"combat HUD is missing runtime bar behavior: {token}")
    if "COMPACT_HUD_FRAME_OFFSETS" in combat_ui_script:
        fail("compact combat HUD still uses erratic per-frame XY jumps")
    if "COMPACT_HUD_VERTICAL_OFFSETS" not in combat_ui_script:
        fail("compact combat HUD does not define synchronized vertical motion")
    foreground_node = combat_scene.find('[node name="Foreground"')
    interface_node = combat_scene.find('[node name="Interface"')
    if foreground_node < 0 or interface_node < 0 or foreground_node > interface_node:
        fail("combat foreground must remain below the interface layer")
    if combat_script.count('"player_feet": Vector2(') != 3:
        fail("each combat interior must define one fixed player foot anchor")
    if combat_script.count('"enemy_feet": [') != 3:
        fail("each combat interior must define fixed enemy foot anchors")
    for required_enemy_animation_token in (
        "EnemyCatalogScript",
        "AnimatedSprite2D.new()",
        "_build_enemy_frames",
        "_anchor_enemy_on_feet",
        'sprite.play(&"attack")',
        'sprite.play(&"idle")',
    ):
        if required_enemy_animation_token not in combat_script:
            fail(
                "animated enemy integration is missing: "
                + required_enemy_animation_token
            )
    if combat_script.count('"foreground_source_rect": Rect2') != 3:
        fail("each combat interior must define its foreground crop rectangle")
    combat_numbers_node = combat_scene.find('[node name="CombatNumbers"')
    curtain_node = combat_scene.find('[node name="Curtain"')
    if (
        combat_numbers_node < interface_node
        or curtain_node < combat_numbers_node
    ):
        fail("combat numbers must remain above the world and below the curtain")
    for required_combat_number_hook in (
        "_spawn_combat_number",
        "_show_status_result",
        "COMBAT_NUMBER_NORMAL_COLOR",
        "COMBAT_NUMBER_STATUS_COLOR",
        "COMBAT_NUMBER_FONT",
    ):
        if required_combat_number_hook not in combat_script:
            fail(f"combat number feedback is missing {required_combat_number_hook}")
    required_action_button_tokens = (
        'const DISCARD_BUTTON_POSITION := Vector2(1497.0, 976.0)',
        'const TURN_BUTTON_POSITION := Vector2(1653.0, 721.0)',
        'res://assets/ui/combat/boton_descartar.png',
        'res://assets/ui/combat/boton_fin_turno.png',
        'res://assets/ui/combat/boton_omitir.png',
        'discard_button.toggle_mode = true',
        'discard_button.toggled.connect(_toggle_discard_mode)',
        'turn_button.pressed.connect(_end_player_turn)',
        '_add_reward_skip_button()',
    )
    for token in required_action_button_tokens:
        if token not in combat_script:
            fail(f"combat action button integration is missing: {token}")

    game_state_script = Path("scripts/game_state.gd").read_text(encoding="utf-8")
    overworld_script = Path("scripts/overworld.gd").read_text(encoding="utf-8")
    shop_script = Path("scripts/shop.gd").read_text(encoding="utf-8")
    for token in (
        "route_step",
        "begin_location",
        "complete_location",
        "award_combat_gold",
        "prepare_shop_inventory",
    ):
        if token not in game_state_script:
            fail(f"run progression is missing GameState.{token}")
    for scene_path in (
        "res://scenes/combat_loader.tscn",
        "res://scenes/shop.tscn",
        "res://scenes/coming_soon.tscn",
    ):
        if scene_path not in overworld_script:
            fail(f"overworld does not route to {scene_path}")
    for token in (
        "npc_sprite.play(&\"dialogue\")",
        "GameState.spend_gold",
        "GameState.complete_location",
    ):
        if token not in shop_script:
            fail(f"shop integration is missing: {token}")


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
    if "progression_smoke_test.gd" not in web:
        fail("Web workflow does not test route, shop, gold, and enemy tiers")
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

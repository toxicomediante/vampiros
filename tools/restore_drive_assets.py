#!/usr/bin/env python3
from __future__ import annotations

import pathlib
import struct
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[1]

# path: (Drive file id, exact byte length reported by Drive)
ASSETS = {
    "assets/cards/juan/el_oculto.png": ("1T6wMCLGQkWog3v7r2qEqX3DdzVHc51bt", 2056387),
    "assets/cards/juan/siempre_sale_bien.png": ("18Y5WS7KvgMUW74wheKIrnc1zPKbp6v2I", 2611065),
    "assets/cards/juan/tiriviento.png": ("1aLhPC_09MyKKfUoYgHrVzqgt0Jt2q2UF", 2308012),
    "assets/cards/juan/fresquita.png": ("1mwSBANscjj2MAEUk00_-kUbv1oLUl_yJ", 2451513),
    "assets/cards/juan/guantazo.png": ("13YK69wL_uTCtmbcfopH55DLD6zbZdNAK", 2229316),
    "assets/cards/juan/guardia.png": ("1X0tJL0gneOo1B-zrf-WytBBKTKAIiICP", 2090500),
    "assets/cards/michu/trilita.png": ("1IsGCd84WTKd6on7qDFO6DAwVzH97tcRn", 2361621),
    "assets/cards/michu/petardo.png": ("1Xm4_xQX2oiEi7ET4Z4CtMn_NTJO8NrOy", 2555462),
    "assets/cards/michu/choriza.png": ("1vbNQx7tNyrky_NX9lulKDH5qyBuPf1dm", 2291916),
    "assets/cards/michu/mojadita.png": ("1dGw8apzDhbaQAIao2enDncpN6IMRuQif", 2278230),
    "assets/cards/michu/bocanegra.png": ("1qQP-HzG-8sl5zpwQ5tAmFF_9AMacIyF4", 2336618),
    "assets/cards/michu/guardia.png": ("15OorIMp4TpGxj4rMnG17ymWRDBd_0Nmd", 2410314),
    "assets/cards/neutral/katana.png": ("1OliexSbIhmjGflk6TLprwSr8rBkPsd3Q", 2590025),
    "assets/cards/neutral/camino.png": ("1VduWa0Z5FON7Fpy7Mb9O_SjV8GM8yB7z", 2535671),
    "assets/cards/neutral/variz.png": ("1kAAB9ujXhiYznJ3EVC1yy5kUnS_0YUMA", 2454937),
    "assets/enemies/tarantula.png": ("1gyWDTjNK8Fr9yiROliGGAPBJil3T9_o_", 1411703),
    "assets/enemies/vampiro_malleiro.png": ("1rbjdsEt_UzS4LhPdVDvhNxwi37SPRY0A", 1247380),
}

CARD_PATH_PREFIXES = ("assets/cards/juan/", "assets/cards/michu/", "assets/cards/neutral/")
EXPECTED_CARD_SIZE = (1024, 1535)


def png_size(data: bytes) -> tuple[int, int]:
    if not data.startswith(b"\x89PNG\r\n\x1a\n") or data[12:16] != b"IHDR":
        raise RuntimeError("Downloaded data is not a valid PNG")
    return struct.unpack(">II", data[16:24])


def download(file_id: str, expected_bytes: int, destination: pathlib.Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    url = f"https://drive.usercontent.google.com/download?id={file_id}&export=download&confirm=t"
    request = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(request, timeout=120) as response:
        data = response.read()

    actual_size = len(data)
    if actual_size != expected_bytes:
        raise RuntimeError(
            f"Drive byte mismatch for {destination}: expected {expected_bytes}, got {actual_size}"
        )

    width, height = png_size(data)
    relative_path = destination.relative_to(ROOT).as_posix()
    if relative_path.startswith(CARD_PATH_PREFIXES) and (width, height) != EXPECTED_CARD_SIZE:
        raise RuntimeError(
            f"Unexpected card dimensions for {relative_path}: {(width, height)}; "
            f"expected {EXPECTED_CARD_SIZE}"
        )

    destination.write_bytes(data)
    print(f"restored exact Drive PNG {relative_path} ({actual_size} bytes, {width}x{height})")


def patch_combat() -> None:
    path = ROOT / "scripts/combat.gd"
    text = path.read_text(encoding="utf-8")
    replacements = {
        "const CARD_GAP := 18.0": "const CARD_GAP := -58.0",
        "player_frame.position = Vector2(24, 132)": "player_frame.position = Vector2(34, 150)",
        "player_frame.size = Vector2(690, 388)": "player_frame.size = Vector2(430, 242)",
        "Vector2(245, 286), Vector2(420, 42), 25": "Vector2(155, 244), Vector2(265, 34), 20",
        "Vector2(245, 350), Vector2(420, 42), 23": "Vector2(155, 286), Vector2(265, 34), 19",
        "Vector2(55, 485), Vector2(650, 52), 15": "Vector2(48, 392), Vector2(430, 42), 13",
    }
    for old, new in replacements.items():
        if old not in text:
            raise RuntimeError(f"Expected combat source fragment not found: {old}")
        text = text.replace(old, new, 1)

    texture_line = '\t&"siempre_sale_bien": preload("res://assets/cards/juan/siempre_sale_bien.png"),'
    oculto_line = '\n\t&"el_oculto": preload("res://assets/cards/juan/el_oculto.png"),'
    if '&"el_oculto"' not in text:
        if texture_line not in text:
            raise RuntimeError("Could not insert EL OCULTO texture")
        text = text.replace(texture_line, texture_line + oculto_line, 1)

    stretch_line = "\t\tbutton.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED"
    full_png_lines = (
        stretch_line
        + "\n\t\tbutton.clip_contents = false"
        + "\n\t\tbutton.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST"
    )
    if "button.clip_contents = false" not in text:
        if stretch_line not in text:
            raise RuntimeError("Could not enforce full-card texture rendering")
        text = text.replace(stretch_line, full_png_lines, 1)

    path.write_text(text, encoding="utf-8")
    print("patched overlap, HP/DEF scale, EL OCULTO and full-PNG card rendering")


def main() -> None:
    for relative_path, (file_id, expected_bytes) in ASSETS.items():
        download(file_id, expected_bytes, ROOT / relative_path)
    patch_combat()


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
from __future__ import annotations

import pathlib
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[1]

ASSETS = {
    "assets/cards/juan/el_oculto.png": "1T6wMCLGQkWog3v7r2qEqX3DdzVHc51bt",
    "assets/cards/juan/siempre_sale_bien.png": "18Y5WS7KvgMUW74wheKIrnc1zPKbp6v2I",
    "assets/cards/juan/tiriviento.png": "1aLhPC_09MyKKfUoYgHrVzqgt0Jt2q2UF",
    "assets/cards/juan/fresquita.png": "1mwSBANscjj2MAEUk00_-kUbv1oLUl_yJ",
    "assets/cards/juan/guantazo.png": "13YK69wL_uTCtmbcfopH55DLD6zbZdNAK",
    "assets/cards/juan/guardia.png": "1X0tJL0gneOo1B-zrf-WytBBKTKAIiICP",
    "assets/cards/michu/trilita.png": "1IsGCd84WTKd6on7qDFO6DAwVzH97tcRn",
    "assets/cards/michu/petardo.png": "1Xm4_xQX2oiEi7ET4Z4CtMn_NTJO8NrOy",
    "assets/cards/michu/choriza.png": "1vbNQx7tNyrky_NX9lulKDH5qyBuPf1dm",
    "assets/cards/michu/mojadita.png": "1dGw8apzDhbaQAIao2enDncpN6IMRuQif",
    "assets/cards/michu/bocanegra.png": "1qQP-HzG-8sl5zpwQ5tAmFF_9AMacIyF4",
    "assets/cards/michu/guardia.png": "15OorIMp4TpGxj4rMnG17ymWRDBd_0Nmd",
    "assets/cards/neutral/katana.png": "1OliexSbIhmjGflk6TLprwSr8rBkPsd3Q",
    "assets/cards/neutral/camino.png": "1VduWa0Z5FON7Fpy7Mb9O_SjV8GM8yB7z",
    "assets/cards/neutral/variz.png": "1kAAB9ujXhiYznJ3EVC1yy5kUnS_0YUMA",
    "assets/enemies/tarantula.png": "1gyWDTjNK8Fr9yiROliGGAPBJil3T9_o_",
    "assets/enemies/vampiro_malleiro.png": "1rbjdsEt_UzS4LhPdVDvhNxwi37SPRY0A",
}


def download(file_id: str, destination: pathlib.Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    url = f"https://drive.usercontent.google.com/download?id={file_id}&export=download&confirm=t"
    request = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(request, timeout=90) as response:
        data = response.read()
    if not data.startswith(b"\x89PNG\r\n\x1a\n"):
        raise RuntimeError(f"Drive did not return a PNG for {destination}")
    destination.write_bytes(data)
    print(f"restored {destination.relative_to(ROOT)} ({len(data)} bytes)")


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

    path.write_text(text, encoding="utf-8")
    print("patched combat hand overlap, HP/DEF scale and EL OCULTO texture")


def main() -> None:
    for relative_path, file_id in ASSETS.items():
        download(file_id, ROOT / relative_path)
    patch_combat()


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Regenerate compact, valid pixel-art assets for the playable vertical slice."""
from __future__ import annotations

from pathlib import Path
import struct
import zlib

RGBA = tuple[int, int, int, int]


def save_png(path: Path, width: int, height: int, pixels: list[list[RGBA]]) -> None:
    raw = bytearray()
    for row in pixels:
        raw.append(0)
        for r, g, b, a in row:
            raw.extend((r, g, b, a))
    def chunk(kind: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)
    payload = b"\x89PNG\r\n\x1a\n"
    payload += chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
    payload += chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    payload += chunk(b"IEND", b"")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(payload)


def canvas(w: int, h: int, color: RGBA = (0, 0, 0, 0)) -> list[list[RGBA]]:
    return [[color for _ in range(w)] for _ in range(h)]


def rect(px: list[list[RGBA]], x0: int, y0: int, x1: int, y1: int, c: RGBA) -> None:
    h, w = len(px), len(px[0])
    for y in range(max(0, y0), min(h, y1)):
        for x in range(max(0, x0), min(w, x1)):
            px[y][x] = c


def diamond(px: list[list[RGBA]], cx: int, cy: int, radius: int, c: RGBA) -> None:
    for y in range(cy - radius, cy + radius + 1):
        span = radius - abs(y - cy)
        rect(px, cx - span, y, cx + span + 1, y + 1, c)


def glyph(px: list[list[RGBA]], x: int, y: int, text: str, scale: int, c: RGBA) -> None:
    font = {
        "A":("01110","10001","11111","10001","10001"),"B":("11110","10001","11110","10001","11110"),
        "C":("01111","10000","10000","10000","01111"),"D":("11110","10001","10001","10001","11110"),
        "E":("11111","10000","11110","10000","11111"),"F":("11111","10000","11110","10000","10000"),
        "G":("01111","10000","10111","10001","01111"),"H":("10001","10001","11111","10001","10001"),
        "I":("11111","00100","00100","00100","11111"),"J":("00111","00010","00010","10010","01100"),
        "K":("10001","10010","11100","10010","10001"),"L":("10000","10000","10000","10000","11111"),
        "M":("10001","11011","10101","10001","10001"),"N":("10001","11001","10101","10011","10001"),
        "O":("01110","10001","10001","10001","01110"),"P":("11110","10001","11110","10000","10000"),
        "Q":("01110","10001","10101","10010","01101"),"R":("11110","10001","11110","10010","10001"),
        "S":("01111","10000","01110","00001","11110"),"T":("11111","00100","00100","00100","00100"),
        "U":("10001","10001","10001","10001","01110"),"V":("10001","10001","10001","01010","00100"),
        "W":("10001","10001","10101","11011","10001"),"X":("10001","01010","00100","01010","10001"),
        "Y":("10001","01010","00100","00100","00100"),"Z":("11111","00010","00100","01000","11111"),
        "0":("01110","10011","10101","11001","01110"),"1":("00100","01100","00100","00100","01110"),
        "2":("01110","10001","00010","00100","11111"),"3":("11110","00001","01110","00001","11110"),
        "4":("10010","10010","11111","00010","00010"),"5":("11111","10000","11110","00001","11110"),
        "6":("01111","10000","11110","10001","01110"),"7":("11111","00010","00100","01000","01000"),
        "8":("01110","10001","01110","10001","01110"),"9":("01110","10001","01111","00001","11110"),
        "/":("00001","00010","00100","01000","10000"),"-":("00000","00000","11111","00000","00000"),
        " ":("00000",)*5,
    }
    cursor = x
    for ch in text.upper():
        rows = font.get(ch, font[" "])
        for ry, row in enumerate(rows):
            for rx, on in enumerate(row):
                if on == "1": rect(px, cursor + rx*scale, y + ry*scale, cursor+(rx+1)*scale, y+(ry+1)*scale, c)
        cursor += 6*scale


def card(path: str, title: str, cost: int, accent: RGBA, symbol: str) -> None:
    w, h = 128, 192
    px = canvas(w, h, (19, 12, 20, 255))
    rect(px, 3, 3, w-3, h-3, (116, 75, 42, 255)); rect(px, 7, 7, w-7, h-7, (35, 22, 28, 255))
    rect(px, 11, 36, w-11, 126, (54, 46, 54, 255)); rect(px, 14, 39, w-14, 123, (22, 27, 35, 255))
    diamond(px, 18, 18, 13, (103, 9, 24, 255)); diamond(px, 18, 16, 8, (224, 45, 57, 255)); glyph(px, 15, 12, str(cost), 2, (255, 234, 190, 255))
    rect(px, 18, 47, 110, 114, accent)
    glyph(px, 30, 70, symbol[:6], 3, (255, 244, 210, 255))
    words = title.replace("Á","A").replace("Í","I").split()
    y = 132
    for word in words[:3]:
        scale = 2 if len(word) <= 9 else 1
        glyph(px, max(8, (w-len(word)*6*scale)//2), y, word, scale, (242, 218, 169, 255)); y += 13
    save_png(Path(path), w, h, px)


def enemy(path: str, kind: str) -> None:
    w = h = 384; px = canvas(w, h)
    shadow = (10, 8, 16, 120); rect(px, 72, 320, 312, 342, shadow)
    if kind == "tarantula":
        dark=(24,14,29,255); body=(72,37,45,255); glow=(182,42,56,255)
        for i in range(8):
            y=155+i*13; left=42+(i%2)*20; rect(px,left,y,160,y+10,dark); rect(px,224,y,342-left//3,y+10,dark)
        rect(px,126,125,258,286,body); rect(px,150,88,234,170,dark)
        for ex in (170,190,210): diamond(px,ex,130,5,glow)
    else:
        coat=(42,27,54,255); skin=(210,171,146,255); hair=(25,16,29,255); red=(143,22,39,255)
        rect(px,130,90,254,292,coat); rect(px,153,56,231,136,skin); rect(px,145,45,239,82,hair)
        rect(px,102,142,145,270,coat); rect(px,239,135,286,260,coat); rect(px,150,286,181,330,hair); rect(px,205,286,236,330,hair)
        diamond(px,174,89,4,red); diamond(px,211,89,4,red); glyph(px,143,180,"MALLEIRO",2,(225,185,123,255))
    save_png(Path(path), w, h, px)


def ui_frame() -> None:
    w,h=345,194; px=canvas(w,h)
    rect(px,2,2,w-2,h-2,(89,55,38,255)); rect(px,7,7,w-7,h-7,(28,21,29,230)); rect(px,16,18,w-16,82,(68,24,28,255)); rect(px,16,98,w-16,162,(24,43,66,255))
    glyph(px,30,38,"HP",4,(255,220,177,255)); glyph(px,30,118,"DEF",4,(195,225,255,255))
    save_png(Path("assets/ui/combat/hp_def_frame.png"),w,h,px)


def main() -> None:
    cards = [
      ("assets/cards/juan/fresquita.png","FRESQUITA",3,(68,115,143,255),"VIDA"),("assets/cards/juan/guantazo.png","GUANTAZO",1,(130,65,48,255),"PUNO"),
      ("assets/cards/juan/guardia.png","GUARDIA",1,(55,95,135,255),"DEF"),("assets/cards/juan/siempre_sale_bien.png","SIEMPRE SALE BIEN",2,(82,120,69,255),"REGEN"),
      ("assets/cards/juan/tiriviento.png","TIRIVIENTO",1,(123,83,42,255),"VIENTO"),("assets/cards/michu/bocanegra.png","BOCANEGRA",2,(64,112,62,255),"VENENO"),
      ("assets/cards/michu/choriza.png","CHORIZA",3,(118,58,36,255),"X2"),("assets/cards/michu/guardia.png","GUARDIA",1,(55,95,135,255),"DEF"),
      ("assets/cards/michu/mojadita.png","MOJADITA",1,(48,108,139,255),"AGUA"),("assets/cards/michu/petardo.png","PETARDO",1,(142,79,34,255),"BOOM"),
      ("assets/cards/michu/trilita.png","TRILITA",2,(145,48,46,255),"TNT"),("assets/cards/neutral/camino.png","EL CAMINO TE CAMELA",1,(90,76,52,255),"RUTA"),
      ("assets/cards/neutral/katana.png","KATANA ESCONDIDA",1,(89,91,108,255),"KATANA"),("assets/cards/neutral/variz.png","LA VARIZ",1,(104,56,91,255),"DANO")]
    for args in cards: card(*args)
    enemy("assets/enemies/tarantula.png","tarantula"); enemy("assets/enemies/vampiro_malleiro.png","malleiro"); ui_frame()
    print("Regenerated", len(cards)+3, "vertical-slice assets")

if __name__ == "__main__": main()

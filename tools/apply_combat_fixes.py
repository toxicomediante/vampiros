#!/usr/bin/env python3
from __future__ import annotations

import pathlib
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[1]

ASSETS = {
    "assets/enemies/tarantula.png": "1QYy4UuHuqlWMpIPITGhOyVmGRC9FAaBc",
    "assets/enemies/vampiro_malleiro.png": "1JBURuSMrrjxd9H4vEg1KJgNBgHfUdwfH",
    "assets/ui/combat/hp_def_frame.png": "1HuLGM-imDX0ruV0-7KEoJReyjoBLvko7",
}


def download(file_id: str, destination: pathlib.Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    url = f"https://drive.usercontent.google.com/download?id={file_id}&export=download&confirm=t"
    request = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(request, timeout=120) as response:
        data = response.read()
    if not data.startswith(b"\x89PNG\r\n\x1a\n"):
        raise RuntimeError(f"Invalid PNG downloaded for {destination}")
    destination.write_bytes(data)
    print(f"wrote {destination.relative_to(ROOT)} ({len(data)} bytes)")


def replace_once(text: str, old: str, new: str) -> str:
    if new in text:
        return text
    if old not in text:
        raise RuntimeError(f"Expected source fragment not found:\n{old}")
    return text.replace(old, new, 1)


def patch_combat() -> None:
    path = ROOT / "scripts/combat.gd"
    text = path.read_text(encoding="utf-8")

    text = replace_once(
        text,
        "const CARD_GAP := -58.0\nconst CARD_Y := 735.0",
        "const CARD_GAP := -78.0\nconst CARD_Y := 748.0\nconst CARD_FAN_ROTATION := 6.0\nconst CARD_FAN_LIFT := 17.0\nconst DRAG_FOLLOW := 0.30",
    )
    text = replace_once(
        text,
        "var drag_origin := Vector2.ZERO\nvar discard_window_open := true",
        "var drag_origin := Vector2.ZERO\nvar drag_origin_rotation := 0.0\nvar drag_pointer_offset := Vector2.ZERO\nvar discard_window_open := true",
    )
    text = replace_once(
        text,
        "var player_hp_label: Label\nvar player_block_label: Label",
        "var player_hp_label: Label\nvar player_block_label: Label\nvar player_hp_fill: ColorRect\nvar player_block_fill: ColorRect",
    )

    old_ui = '''\tvar player_frame := TextureRect.new()
\tplayer_frame.texture = HP_DEF_FRAME_TEXTURE
\tplayer_frame.position = Vector2(34, 150)
\tplayer_frame.size = Vector2(430, 242)
\tplayer_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
\tplayer_frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
\tplayer_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
\tinterface.add_child(player_frame)

\tplayer_hp_label = _make_label(
\t\tVector2(155, 244), Vector2(265, 34), 20, Color(1.0, 0.9, 0.79)
\t)
\tplayer_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
\tinterface.add_child(player_hp_label)
\tplayer_block_label = _make_label(
\t\tVector2(155, 286), Vector2(265, 34), 19, Color(0.72, 0.88, 1.0)
\t)
\tplayer_block_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
\tinterface.add_child(player_block_label)
\tplayer_status_label = _make_label(
\t\tVector2(48, 392), Vector2(430, 42), 13, Color(0.96, 0.82, 0.56)
\t)
\tinterface.add_child(player_status_label)'''
    new_ui = '''\t# The coloured fills sit behind the approved ornate PNG frame.
\tplayer_hp_fill = ColorRect.new()
\tplayer_hp_fill.position = Vector2(222, 255)
\tplayer_hp_fill.size = Vector2(326, 38)
\tplayer_hp_fill.color = Color(0.62, 0.015, 0.025, 0.96)
\tplayer_hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
\tinterface.add_child(player_hp_fill)

\tplayer_block_fill = ColorRect.new()
\tplayer_block_fill.position = Vector2(222, 307)
\tplayer_block_fill.size = Vector2(0, 36)
\tplayer_block_fill.color = Color(0.08, 0.25, 0.43, 0.96)
\tplayer_block_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
\tinterface.add_child(player_block_fill)

\tvar player_frame := TextureRect.new()
\tplayer_frame.texture = HP_DEF_FRAME_TEXTURE
\tplayer_frame.position = Vector2(24, 120)
\tplayer_frame.size = Vector2(600, 337)
\tplayer_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
\tplayer_frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
\tplayer_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
\tinterface.add_child(player_frame)

\tplayer_hp_label = _make_label(
\t\tVector2(222, 255), Vector2(326, 38), 19, Color(1.0, 0.92, 0.82)
\t)
\tplayer_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
\tplayer_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
\tinterface.add_child(player_hp_label)
\tplayer_block_label = _make_label(
\t\tVector2(222, 307), Vector2(326, 36), 18, Color(0.78, 0.9, 1.0)
\t)
\tplayer_block_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
\tplayer_block_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
\tinterface.add_child(player_block_label)
\tplayer_status_label = _make_label(
\t\tVector2(48, 454), Vector2(550, 38), 13, Color(0.96, 0.82, 0.56)
\t)
\tinterface.add_child(player_status_label)'''
    text = replace_once(text, old_ui, new_ui)

    text = text.replace(
        '"PRIMER TURNO · CLIC DERECHO PARA DESCARTAR · ARRASTRA PARA JUGAR"\n\t\tif first_turn\n\t\telse "NUEVO TURNO · CLIC DERECHO PARA DESCARTAR · ARRASTRA PARA JUGAR"',
        '"PRIMER TURNO · ARRASTRA UNA CARTA PARA JUGAR"\n\t\tif first_turn\n\t\telse "NUEVO TURNO · ARRASTRA UNA CARTA PARA JUGAR"',
    )

    start = text.index("func _rebuild_hand() -> void:")
    end = text.index("func _finish_card_drag() -> void:")
    new_hand = '''func _rebuild_hand() -> void:
\tfor button in card_buttons:
\t\tif is_instance_valid(button):
\t\t\tbutton.queue_free()
\tcard_buttons.clear()

\tvar count := deck.hand.size()
\tif count == 0:
\t\treturn
\tvar step := CARD_SIZE.x + CARD_GAP
\tvar center := (count - 1) / 2.0
\tvar start_x := 960.0 - CARD_SIZE.x / 2.0 - center * step
\tfor card_index in count:
\t\tvar card_id: StringName = deck.hand[card_index]
\t\tvar offset := card_index - center
\t\tvar button := TextureButton.new()
\t\tbutton.texture_normal = CARD_TEXTURES[card_id]
\t\tbutton.ignore_texture_size = true
\t\tbutton.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
\t\tbutton.clip_contents = false
\t\tbutton.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
\t\tbutton.size = CARD_SIZE
\t\tbutton.pivot_offset = CARD_SIZE / 2.0
\t\tbutton.position = Vector2(
\t\t\tstart_x + card_index * step,
\t\t\tCARD_Y + absf(offset) * CARD_FAN_LIFT
\t\t)
\t\tbutton.rotation = deg_to_rad(offset * CARD_FAN_ROTATION)
\t\tbutton.z_index = card_index
\t\tbutton.tooltip_text = "%s · Coste %d" % [
\t\t\tCardCatalog.CARDS[card_id]["name"],
\t\t\tCardCatalog.CARDS[card_id]["cost"],
\t\t]
\t\tbutton.set_meta("card_id", card_id)
\t\tbutton.gui_input.connect(_on_card_input.bind(button))
\t\tinterface.add_child(button)
\t\tcard_buttons.append(button)


func _start_card_drag(button: TextureButton, card_id: StringName, pointer: Vector2) -> void:
\tdrag_card = button
\tdrag_card_id = card_id
\tdrag_origin = button.position
\tdrag_origin_rotation = button.rotation
\tdrag_pointer_offset = pointer - button.global_position
\tbutton.rotation = 0.0
\tbutton.z_index = 100
\tbutton.modulate = Color(1.08, 1.08, 1.08)


func _move_card_drag(pointer: Vector2) -> void:
\tif not is_instance_valid(drag_card):
\t\treturn
\tvar target := pointer - drag_pointer_offset
\tdrag_card.global_position = drag_card.global_position.lerp(target, DRAG_FOLLOW)
\t_refresh_enemy_highlight(pointer)


func _on_card_input(event: InputEvent, button: TextureButton) -> void:
\tif combat_finished:
\t\treturn
\tvar card_id: StringName = button.get_meta("card_id")
\tif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
\t\tif event.pressed:
\t\t\t_start_card_drag(button, card_id, get_viewport().get_mouse_position())
\t\telif drag_card == button:
\t\t\t_finish_card_drag()
\t\tbutton.accept_event()
\telif event is InputEventMouseMotion and drag_card == button:
\t\t_move_card_drag(get_viewport().get_mouse_position())
\t\tbutton.accept_event()
\telif event is InputEventScreenTouch:
\t\tif event.pressed:
\t\t\t_start_card_drag(button, card_id, event.position)
\t\telif drag_card == button:
\t\t\t_finish_card_drag()
\t\tbutton.accept_event()
\telif event is InputEventScreenDrag and drag_card == button:
\t\t_move_card_drag(event.position)
\t\tbutton.accept_event()


'''
    text = text[:start] + new_hand + text[end:]

    text = replace_once(
        text,
        "\tdrag_card.position = drag_origin\n\tdrag_card.z_index = 0\n\tdrag_card.modulate = Color.WHITE",
        "\tdrag_card.position = drag_origin\n\tdrag_card.rotation = drag_origin_rotation\n\tdrag_card.z_index = card_buttons.find(drag_card)\n\tdrag_card.modulate = Color.WHITE",
    )

    text = replace_once(
        text,
        'func _refresh_all_ui() -> void:\n\tplayer_hp_label.text = "HP  %d / %d" % [player.hp, player.max_hp]\n\tplayer_block_label.text = "DEF  %d" % player.block',
        'func _refresh_all_ui() -> void:\n\tplayer_hp_label.text = "HP  %d / %d" % [player.hp, player.max_hp]\n\tplayer_block_label.text = "DEF  %d" % player.block\n\tplayer_hp_fill.size.x = 326.0 * clampf(float(player.hp) / float(player.max_hp), 0.0, 1.0)\n\tplayer_block_fill.size.x = 326.0 * clampf(float(player.block) / 20.0, 0.0, 1.0)',
    )

    path.write_text(text, encoding="utf-8")
    print("patched combat UI, card fan, touch drag and removed right-click discard")


def main() -> None:
    for relative, file_id in ASSETS.items():
        download(file_id, ROOT / relative)
    patch_combat()


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
from __future__ import annotations

import pathlib

ROOT = pathlib.Path(__file__).resolve().parents[1]


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

    text = replace_once(
        text,
        '\t\tsprite.texture = definition["texture"]\n\t\tsprite.position = definition["position"]',
        '\t\tsprite.texture = definition["texture"]\n\t\tsprite.material = _checker_transparency_material()\n\t\tsprite.position = definition["position"]',
    )

    helper = '''\n\nfunc _checker_transparency_material() -> ShaderMaterial:\n\tvar shader := Shader.new()\n\tshader.code = """shader_type canvas_item;\nvoid fragment() {\n    vec4 c = texture(TEXTURE, UV);\n    float spread = max(c.r, max(c.g, c.b)) - min(c.r, min(c.g, c.b));\n    bool neutral_light = spread < 0.035 && c.r > 0.58;\n    COLOR = neutral_light ? vec4(c.rgb, 0.0) : c;\n}\n"""\n\tvar material := ShaderMaterial.new()\n\tmaterial.shader = shader\n\treturn material\n'''
    if "func _checker_transparency_material()" not in text:
        marker = "\n\nfunc _build_runtime_ui() -> void:"
        if marker not in text:
            raise RuntimeError("Could not insert checker transparency material")
        text = text.replace(marker, helper + marker, 1)

    old_ui = '''\tvar player_frame := TextureRect.new()\n\tplayer_frame.texture = HP_DEF_FRAME_TEXTURE\n\tplayer_frame.position = Vector2(34, 150)\n\tplayer_frame.size = Vector2(430, 242)\n\tplayer_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE\n\tplayer_frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED\n\tplayer_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE\n\tinterface.add_child(player_frame)\n\n\tplayer_hp_label = _make_label(\n\t\tVector2(155, 244), Vector2(265, 34), 20, Color(1.0, 0.9, 0.79)\n\t)\n\tplayer_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER\n\tinterface.add_child(player_hp_label)\n\tplayer_block_label = _make_label(\n\t\tVector2(155, 286), Vector2(265, 34), 19, Color(0.72, 0.88, 1.0)\n\t)\n\tplayer_block_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER\n\tinterface.add_child(player_block_label)\n\tplayer_status_label = _make_label(\n\t\tVector2(48, 392), Vector2(430, 42), 13, Color(0.96, 0.82, 0.56)\n\t)\n\tinterface.add_child(player_status_label)'''

    new_ui = '''\tplayer_hp_fill = ColorRect.new()\n\tplayer_hp_fill.position = Vector2(222, 255)\n\tplayer_hp_fill.size = Vector2(326, 38)\n\tplayer_hp_fill.color = Color(0.62, 0.015, 0.025, 0.96)\n\tplayer_hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE\n\tinterface.add_child(player_hp_fill)\n\n\tplayer_block_fill = ColorRect.new()\n\tplayer_block_fill.position = Vector2(222, 307)\n\tplayer_block_fill.size = Vector2(0, 36)\n\tplayer_block_fill.color = Color(0.08, 0.25, 0.43, 0.96)\n\tplayer_block_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE\n\tinterface.add_child(player_block_fill)\n\n\tvar player_frame := TextureRect.new()\n\tplayer_frame.texture = HP_DEF_FRAME_TEXTURE\n\tplayer_frame.material = _checker_transparency_material()\n\tplayer_frame.position = Vector2(24, 120)\n\tplayer_frame.size = Vector2(600, 337)\n\tplayer_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE\n\tplayer_frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED\n\tplayer_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE\n\tinterface.add_child(player_frame)\n\n\tplayer_hp_label = _make_label(Vector2(222, 255), Vector2(326, 38), 19, Color(1.0, 0.92, 0.82))\n\tplayer_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER\n\tplayer_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER\n\tinterface.add_child(player_hp_label)\n\tplayer_block_label = _make_label(Vector2(222, 307), Vector2(326, 36), 18, Color(0.78, 0.9, 1.0))\n\tplayer_block_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER\n\tplayer_block_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER\n\tinterface.add_child(player_block_label)\n\tplayer_status_label = _make_label(Vector2(48, 454), Vector2(550, 38), 13, Color(0.96, 0.82, 0.56))\n\tinterface.add_child(player_status_label)'''
    text = replace_once(text, old_ui, new_ui)

    text = text.replace(
        '"PRIMER TURNO · CLIC DERECHO PARA DESCARTAR · ARRASTRA PARA JUGAR"\n\t\tif first_turn\n\t\telse "NUEVO TURNO · CLIC DERECHO PARA DESCARTAR · ARRASTRA PARA JUGAR"',
        '"PRIMER TURNO · ARRASTRA UNA CARTA PARA JUGAR"\n\t\tif first_turn\n\t\telse "NUEVO TURNO · ARRASTRA UNA CARTA PARA JUGAR"',
    )

    start = text.index("func _rebuild_hand() -> void:")
    end = text.index("func _finish_card_drag() -> void:")
    new_hand = '''func _rebuild_hand() -> void:\n\tfor button in card_buttons:\n\t\tif is_instance_valid(button):\n\t\t\tbutton.queue_free()\n\tcard_buttons.clear()\n\n\tvar count := deck.hand.size()\n\tif count == 0:\n\t\treturn\n\tvar step := CARD_SIZE.x + CARD_GAP\n\tvar center := (count - 1) / 2.0\n\tvar start_x := 960.0 - CARD_SIZE.x / 2.0 - center * step\n\tfor card_index in count:\n\t\tvar card_id: StringName = deck.hand[card_index]\n\t\tvar offset := card_index - center\n\t\tvar button := TextureButton.new()\n\t\tbutton.texture_normal = CARD_TEXTURES[card_id]\n\t\tbutton.ignore_texture_size = true\n\t\tbutton.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED\n\t\tbutton.clip_contents = false\n\t\tbutton.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST\n\t\tbutton.size = CARD_SIZE\n\t\tbutton.pivot_offset = CARD_SIZE / 2.0\n\t\tbutton.position = Vector2(start_x + card_index * step, CARD_Y + absf(offset) * CARD_FAN_LIFT)\n\t\tbutton.rotation = deg_to_rad(offset * CARD_FAN_ROTATION)\n\t\tbutton.z_index = card_index\n\t\tbutton.set_meta("card_id", card_id)\n\t\tbutton.gui_input.connect(_on_card_input.bind(button))\n\t\tinterface.add_child(button)\n\t\tcard_buttons.append(button)\n\n\nfunc _start_card_drag(button: TextureButton, card_id: StringName, pointer: Vector2) -> void:\n\tdrag_card = button\n\tdrag_card_id = card_id\n\tdrag_origin = button.position\n\tdrag_origin_rotation = button.rotation\n\tdrag_pointer_offset = pointer - button.global_position\n\tbutton.rotation = 0.0\n\tbutton.z_index = 100\n\tbutton.modulate = Color(1.08, 1.08, 1.08)\n\n\nfunc _move_card_drag(pointer: Vector2) -> void:\n\tif not is_instance_valid(drag_card):\n\t\treturn\n\tvar target := pointer - drag_pointer_offset\n\tdrag_card.global_position = drag_card.global_position.lerp(target, DRAG_FOLLOW)\n\t_refresh_enemy_highlight(pointer)\n\n\nfunc _on_card_input(event: InputEvent, button: TextureButton) -> void:\n\tif combat_finished:\n\t\treturn\n\tvar card_id: StringName = button.get_meta("card_id")\n\tif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:\n\t\tif event.pressed:\n\t\t\t_start_card_drag(button, card_id, get_viewport().get_mouse_position())\n\t\telif drag_card == button:\n\t\t\t_finish_card_drag()\n\t\tbutton.accept_event()\n\telif event is InputEventMouseMotion and drag_card == button:\n\t\t_move_card_drag(get_viewport().get_mouse_position())\n\t\tbutton.accept_event()\n\telif event is InputEventScreenTouch:\n\t\tif event.pressed:\n\t\t\t_start_card_drag(button, card_id, event.position)\n\t\telif drag_card == button:\n\t\t\t_finish_card_drag()\n\t\tbutton.accept_event()\n\telif event is InputEventScreenDrag and drag_card == button:\n\t\t_move_card_drag(event.position)\n\t\tbutton.accept_event()\n\n\n'''
    text = text[:start] + new_hand + text[end:]

    text = replace_once(text, "\tdrag_card.position = drag_origin\n\tdrag_card.z_index = 0\n\tdrag_card.modulate = Color.WHITE", "\tdrag_card.position = drag_origin\n\tdrag_card.rotation = drag_origin_rotation\n\tdrag_card.z_index = card_buttons.find(drag_card)\n\tdrag_card.modulate = Color.WHITE")
    text = replace_once(text, 'func _refresh_all_ui() -> void:\n\tplayer_hp_label.text = "HP  %d / %d" % [player.hp, player.max_hp]\n\tplayer_block_label.text = "DEF  %d" % player.block', 'func _refresh_all_ui() -> void:\n\tplayer_hp_label.text = "HP  %d / %d" % [player.hp, player.max_hp]\n\tplayer_block_label.text = "DEF  %d" % player.block\n\tplayer_hp_fill.size.x = 326.0 * clampf(float(player.hp) / float(player.max_hp), 0.0, 1.0)\n\tplayer_block_fill.size.x = 326.0 * clampf(float(player.block) / 20.0, 0.0, 1.0)')

    path.write_text(text, encoding="utf-8")
    print("patched runtime transparency, combat UI, card fan and mobile drag")


def main() -> None:
    patch_combat()


if __name__ == "__main__":
    main()

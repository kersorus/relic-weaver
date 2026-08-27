class_name ItemSlot
extends Button

signal item_dropped(from_index: int, to_index: int)
signal shop_item_dropped(offer_index: int, to_index: int)

var slot_index := -1
var item_snapshot: Variant = null
var preview_texture: Texture2D
var preview_tier := 1
var preview_color := Color.WHITE

func configure(index: int, item: Variant, icon: Texture2D, tier: int, tier_color: Color) -> void:
    slot_index = index
    item_snapshot = item
    preview_texture = icon
    preview_tier = tier
    preview_color = tier_color

func _get_drag_data(_at_position: Vector2) -> Variant:
    if item_snapshot == null or preview_texture == null:
        return null
    var preview := VBoxContainer.new()
    preview.custom_minimum_size = Vector2(104, 118)
    preview.modulate = Color(1.0, 1.0, 1.0, 0.94)

    var art := TextureRect.new()
    art.texture = preview_texture
    art.custom_minimum_size = Vector2(96, 96)
    art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    art.mouse_filter = Control.MOUSE_FILTER_IGNORE
    preview.add_child(art)

    var tier_label := Label.new()
    tier_label.text = "T%d" % preview_tier
    tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    tier_label.add_theme_font_size_override("font_size", 18)
    tier_label.add_theme_color_override("font_color", preview_color)
    tier_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    preview.add_child(tier_label)

    set_drag_preview(preview)
    return {"type": "board_item", "from": slot_index}

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
    if not data is Dictionary:
        return false
    var drag_type := str(data.get("type", ""))
    if drag_type == "board_item":
        return int(data.get("from", -1)) >= 0 and int(data.get("from", -1)) != slot_index
    if drag_type == "shop_offer":
        return item_snapshot == null and int(data.get("offer", -1)) >= 0
    return false

func _drop_data(_at_position: Vector2, data: Variant) -> void:
    if str(data.get("type", "")) == "shop_offer":
        shop_item_dropped.emit(int(data["offer"]), slot_index)
    else:
        item_dropped.emit(int(data["from"]), slot_index)

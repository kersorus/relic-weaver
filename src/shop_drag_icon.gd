class_name ShopDragIcon
extends TextureRect

var offer_index := -1
var item_tier := 1
var tier_color := Color.WHITE
var drag_enabled := true

func configure(index: int, tier: int, color: Color, enabled: bool) -> void:
    offer_index = index
    item_tier = tier
    tier_color = color
    drag_enabled = enabled
    mouse_default_cursor_shape = Control.CURSOR_DRAG if enabled else Control.CURSOR_FORBIDDEN
    modulate = Color.WHITE if enabled else Color(0.55, 0.55, 0.60, 0.72)

func _get_drag_data(_at_position: Vector2) -> Variant:
    if not drag_enabled or texture == null or offer_index < 0:
        return null
    var preview := VBoxContainer.new()
    preview.custom_minimum_size = Vector2(104, 118)
    preview.modulate = Color(1.0, 1.0, 1.0, 0.94)

    var art := TextureRect.new()
    art.texture = texture
    art.custom_minimum_size = Vector2(96, 96)
    art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    art.mouse_filter = Control.MOUSE_FILTER_IGNORE
    preview.add_child(art)

    var tier_label := Label.new()
    tier_label.text = "T%d" % item_tier
    tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    tier_label.add_theme_font_size_override("font_size", 18)
    tier_label.add_theme_color_override("font_color", tier_color)
    tier_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    preview.add_child(tier_label)

    set_drag_preview(preview)
    return {"type": "shop_offer", "offer": offer_index}

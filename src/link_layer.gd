extends Control

var links: Array = []
var selected_slot := -1
var reduced_motion := false
var phase := 0.0
var cell_size := Vector2(121.0, 121.0)
var gap := Vector2(7.0, 7.0)
var columns := 5

func configure(new_links: Array, selected: int, motion_reduced: bool) -> void:
    links = new_links.duplicate(true)
    selected_slot = selected
    reduced_motion = motion_reduced
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    queue_redraw()

func _process(delta: float) -> void:
    if reduced_motion or not is_visible_in_tree():
        return
    phase = fmod(phase + delta * 0.72, 1.0)
    queue_redraw()

func _draw() -> void:
    for link_data in links:
        var from_index := int(link_data.get("from", -1))
        var to_index := int(link_data.get("to", -1))
        if from_index < 0 or to_index < 0:
            continue
        var color: Color = link_data.get("color", Color("63d6bd"))
        var start := _cell_center(from_index)
        var finish := _cell_center(to_index)
        var strength := float(link_data.get("strength", 1.0))
        draw_line(start, finish, Color(color.r, color.g, color.b, 0.18), 9.0 + strength * 2.0, true)
        draw_line(start, finish, Color(color.r, color.g, color.b, 0.78), 2.0 + strength, true)
        _draw_link_marker(
            start,
            finish,
            str(link_data.get("pattern", "thread")),
            strength,
            Color(color.r, color.g, color.b, 0.98)
        )

    if selected_slot >= 0:
        var center := _cell_center(selected_slot)
        var pulse := 4.0 if reduced_motion else sin(phase * TAU) * 2.0 + 5.0
        draw_arc(center, cell_size.x * 0.41 + pulse, 0.0, TAU, 32, Color("80f5d9"), 3.0, true)

func _draw_link_marker(start: Vector2, finish: Vector2, pattern: String, strength: float, color: Color) -> void:
    var direction := (finish - start).normalized()
    var normal := Vector2(-direction.y, direction.x)
    var center := start.lerp(finish, 0.5)
    match pattern:
        "steel":
            var radius := 6.0 + strength
            draw_colored_polygon(PackedVector2Array([
                center - direction * radius,
                center + normal * radius,
                center + direction * radius,
                center - normal * radius
            ]), color)
        "arcane":
            draw_circle(center, 8.0 + strength, Color(color.r, color.g, color.b, 0.16))
            draw_arc(center, 7.0 + strength, 0.0, TAU, 20, color, 2.5, true)
        "mechanism":
            for distance in [0.38, 0.62]:
                var marker := start.lerp(finish, distance)
                draw_line(marker - normal * 7.0, marker + normal * 7.0, color, 3.0, true)
        _:
            var marker_phase := 0.5 if reduced_motion else phase
            var pulse_position := start.lerp(finish, marker_phase)
            draw_circle(pulse_position, 4.0 + strength, color)

func _cell_center(index: int) -> Vector2:
    var x := index % columns
    var y := index / columns
    return Vector2(
        x * (cell_size.x + gap.x) + cell_size.x * 0.5,
        y * (cell_size.y + gap.y) + cell_size.y * 0.5
    )

extends Control

const GameDataRef = preload("res://src/game_data.gd")
const SaveManagerRef = preload("res://src/save_manager.gd")

const C_BG := Color("181b25")
const C_PANEL := Color("242936")
const C_PANEL_2 := Color("30394a")
const C_TEXT := Color("eef0f5")
const C_MUTED := Color("aeb6c7")
const C_ACCENT := Color("63d6bd")
const C_GOLD := Color("e5bd69")
const C_DANGER := Color("df6973")

var save_data: Dictionary
var screen_root: Control
var chapter_index := 0
var stage_index := 0
var scrap := 0
var board: Array = []
var shop: Array = []
var selected_slot := -1
var rng := RandomNumberGenerator.new()

# Battle runtime
var battle_active := false
var battle_stats := {}
var enemy_data := {}
var hero_hp := 0.0
var hero_max_hp := 0.0
var enemy_hp := 0.0
var enemy_max_hp := 0.0
var hero_timer := 0.0
var enemy_timer := 0.0
var magic_timer := 0.0
var bell_timer := 0.0
var regen_timer := 0.0
var enemy_hit_count := 0
var hero_attack_count := 0
var enemy_stun := 0.0
var mirror_charge := false
var hero_hp_bar: ProgressBar
var enemy_hp_bar: ProgressBar
var hero_hp_label: Label
var enemy_hp_label: Label
var battle_log_label: Label
var hero_actor: TextureRect
var enemy_actor: TextureRect
var battle_continue_button: Button
var current_bg: TextureRect
var combat_area: Control
var slot_buttons: Array = []
var battle_speed := 1.0
var loot_choices: Array = []

var sfx_click: AudioStreamPlayer
var sfx_merge: AudioStreamPlayer
var sfx_hit: AudioStreamPlayer
var sfx_victory: AudioStreamPlayer

func _ready() -> void:
    print("RW_GAME: _ready begin")
    rng.randomize()
    save_data = SaveManagerRef.load_save()
    print("RW_GAME: save loaded")
    _setup_audio()
    print("RW_GAME: audio configured")
    show_home()
    set_meta("boot_ok", true)
    print("RELIC_WEAVER_BOOT_OK")

func _process(delta: float) -> void:
    if battle_active:
        _battle_tick(delta * battle_speed)

func _setup_audio() -> void:
    sfx_click = AudioStreamPlayer.new()
    sfx_click.stream = load("res://assets/audio/click.wav")
    add_child(sfx_click)
    sfx_merge = AudioStreamPlayer.new()
    sfx_merge.stream = load("res://assets/audio/merge.wav")
    add_child(sfx_merge)
    sfx_hit = AudioStreamPlayer.new()
    sfx_hit.stream = load("res://assets/audio/hit.wav")
    add_child(sfx_hit)
    sfx_victory = AudioStreamPlayer.new()
    sfx_victory.stream = load("res://assets/audio/victory.wav")
    add_child(sfx_victory)

func _clear_screen() -> void:
    battle_active = false
    if screen_root != null:
        screen_root.queue_free()
    screen_root = Control.new()
    screen_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(screen_root)

func _style_box(color: Color, radius := 16, border_color := Color.TRANSPARENT, border := 0) -> StyleBoxFlat:
    var box := StyleBoxFlat.new()
    box.bg_color = color
    box.corner_radius_top_left = radius
    box.corner_radius_top_right = radius
    box.corner_radius_bottom_left = radius
    box.corner_radius_bottom_right = radius
    if border > 0:
        box.border_width_left = border
        box.border_width_right = border
        box.border_width_top = border
        box.border_width_bottom = border
        box.border_color = border_color
    box.content_margin_left = 14
    box.content_margin_right = 14
    box.content_margin_top = 10
    box.content_margin_bottom = 10
    return box

func _label(text: String, size := 26, color := C_TEXT, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
    var l := Label.new()
    l.text = text
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", color)
    l.horizontal_alignment = align
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    return l

func _art(path: String, min_size := Vector2(128, 128)) -> TextureRect:
    var t := TextureRect.new()
    t.texture = load(path)
    t.custom_minimum_size = min_size
    t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    t.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return t

func _button(text: String, callback: Callable, min_height := 64, accent := false) -> Button:
    var b := Button.new()
    b.text = text
    b.custom_minimum_size = Vector2(0, min_height)
    b.add_theme_font_size_override("font_size", 24)
    b.add_theme_stylebox_override("normal", _style_box(C_ACCENT if accent else C_PANEL_2, 14))
    b.add_theme_stylebox_override("hover", _style_box((C_ACCENT if accent else C_PANEL_2).lightened(0.08), 14))
    b.add_theme_stylebox_override("pressed", _style_box((C_ACCENT if accent else C_PANEL_2).darkened(0.10), 14))
    b.add_theme_color_override("font_color", Color("10161b") if accent else C_TEXT)
    b.pressed.connect(func():
        sfx_click.play()
        callback.call()
    )
    return b

func _panel() -> PanelContainer:
    var p := PanelContainer.new()
    p.add_theme_stylebox_override("panel", _style_box(Color(C_PANEL, 0.96), 18))
    return p

func _margin(node: Control, amount := 24) -> MarginContainer:
    var m := MarginContainer.new()
    m.add_theme_constant_override("margin_left", amount)
    m.add_theme_constant_override("margin_right", amount)
    m.add_theme_constant_override("margin_top", amount)
    m.add_theme_constant_override("margin_bottom", amount)
    m.add_child(node)
    return m

func _set_background(path: String) -> TextureRect:
    var bg := TextureRect.new()
    bg.texture = load(path)
    bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.modulate = Color(0.58, 0.61, 0.70, 1.0)
    screen_root.add_child(bg)
    var veil := ColorRect.new()
    veil.color = Color(0.05, 0.06, 0.09, 0.35)
    veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    screen_root.add_child(veil)
    current_bg = bg
    return bg

func _main_vbox(top := 24, side := 24, gap := 14) -> VBoxContainer:
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", side)
    margin.add_theme_constant_override("margin_right", side)
    margin.add_theme_constant_override("margin_top", top)
    margin.add_theme_constant_override("margin_bottom", 24)
    screen_root.add_child(margin)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", gap)
    margin.add_child(v)
    return v

# ---------- HOME ----------
func show_home() -> void:
    _clear_screen()
    _set_background("res://assets/backgrounds/chapel.png")
    var v := _main_vbox(54, 34, 18)

    var spacer := Control.new(); spacer.custom_minimum_size.y = 58; v.add_child(spacer)
    var icon := TextureRect.new()
    icon.texture = load("res://assets/icon.png")
    icon.custom_minimum_size = Vector2(146, 146)
    icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    v.add_child(icon)

    var title := _label("RELlC WEAVER", 46, C_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
    title.text = "RELIC WEAVER"
    v.add_child(title)
    v.add_child(_label("Узлы старого мира", 24, C_ACCENT, HORIZONTAL_ALIGNMENT_CENTER))

    var desc_panel := _panel()
    desc_panel.add_child(_margin(_label("Офлайн merge-RPG: собирай артефакты на сетке, сшивай одинаковые предметы, строй цепи соседства и отправляй героя в короткие автобои.", 22, C_TEXT), 20))
    v.add_child(desc_panel)

    var progress_text := "Искры: %d    •    Открыто глав: %d/%d" % [int(save_data["embers"]), int(save_data["max_chapter"]) + 1, GameDataRef.CHAPTERS.size()]
    v.add_child(_label(progress_text, 21, C_GOLD, HORIZONTAL_ALIGNMENT_CENTER))

    v.add_child(_button("НАЧАТЬ ЗАБЕГ", show_chapter_select, 76, true))
    var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 12)
    var upgrades := _button("Узлы силы", show_upgrades, 64); upgrades.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(upgrades)
    var lore := _button("Архив", show_archive, 64); lore.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(lore)
    v.add_child(row)
    v.add_child(_label("Без рекламы • без аккаунта • сохранение только на устройстве", 18, C_MUTED, HORIZONTAL_ALIGNMENT_CENTER))

func show_chapter_select() -> void:
    _clear_screen()
    _set_background("res://assets/backgrounds/road.png")
    var v := _main_vbox(38, 26, 14)
    var head := HBoxContainer.new()
    var back := _button("‹", show_home, 58); back.custom_minimum_size.x = 72; head.add_child(back)
    var t := _label("Выбор главы", 34, C_TEXT); t.size_flags_horizontal = Control.SIZE_EXPAND_FILL; t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; head.add_child(t)
    v.add_child(head)
    v.add_child(_label("Каждая глава — 5 боёв. После поражения остаются Искры для постоянных улучшений.", 20, C_MUTED))

    for i in range(GameDataRef.CHAPTERS.size()):
        var ch: Dictionary = GameDataRef.CHAPTERS[i]
        var unlocked := i <= int(save_data["max_chapter"])
        var p := _panel()
        var box := VBoxContainer.new(); box.add_theme_constant_override("separation", 8)
        box.add_child(_label(ch["name"], 27, C_TEXT if unlocked else C_MUTED))
        box.add_child(_label(ch["intro"], 18, C_MUTED))
        var b := _button("Войти" if unlocked else "Закрыто", _start_run.bind(i), 56, unlocked)
        b.disabled = not unlocked
        box.add_child(b)
        p.add_child(_margin(box, 16)); v.add_child(p)

func _start_run(idx: int) -> void:
    chapter_index = idx
    stage_index = 0
    scrap = 20 + int(save_data["purse_knot"]) * 2
    selected_slot = -1
    board.clear()
    for _i in range(GameDataRef.BOARD_SIZE): board.append(null)
    board[6] = {"id":"blade", "tier":1}
    board[7] = {"id":"thread", "tier":1}
    board[11] = {"id":"buckler", "tier":1}
    _roll_shop(true)
    save_data["runs"] = int(save_data["runs"]) + 1
    SaveManagerRef.save(save_data)
    show_story_card(true)

func show_story_card(is_intro: bool) -> void:
    _clear_screen()
    var ch: Dictionary = GameDataRef.CHAPTERS[chapter_index]
    _set_background(ch["background"])
    var v := _main_vbox(160, 32, 20)
    var p := _panel(); var box := VBoxContainer.new(); box.add_theme_constant_override("separation", 18)
    var chapter_art := _art(ch["prop"], Vector2(0, 220))
    box.add_child(chapter_art)
    box.add_child(_label(ch["name"], 34, C_TEXT, HORIZONTAL_ALIGNMENT_CENTER))
    box.add_child(_label(ch["intro"] if is_intro else ch["outro"], 24, C_TEXT))
    box.add_child(_button("Собрать мастерскую" if is_intro else "Вернуться в лагерь", show_prepare if is_intro else show_home, 70, true))
    p.add_child(_margin(box, 24)); v.add_child(p)

# ---------- PREP / BOARD ----------
func show_prepare() -> void:
    _clear_screen()
    var ch: Dictionary = GameDataRef.CHAPTERS[chapter_index]
    _set_background(ch["background"])
    var v := _main_vbox(22, 20, 10)

    var top := HBoxContainer.new(); top.add_theme_constant_override("separation", 12)
    var quit := _button("×", _confirm_abandon, 52); quit.custom_minimum_size.x = 64; top.add_child(quit)
    var info := _label("%s  •  бой %d/5" % [ch["short"], stage_index + 1], 23, C_TEXT); info.size_flags_horizontal = Control.SIZE_EXPAND_FILL; info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; top.add_child(info)
    top.add_child(_label("⚙ %d" % scrap, 25, C_GOLD, HORIZONTAL_ALIGNMENT_RIGHT))
    v.add_child(top)

    var stats := _calculate_stats()
    v.add_child(_label("Сила %d  •  HP %d  •  скорость %.2f  •  синергия %d" % [int(stats["attack"]), int(stats["max_hp"]), stats["attack_speed"], int(stats["link_score"])], 19, C_MUTED, HORIZONTAL_ALIGNMENT_CENTER))

    var grid_panel := _panel()
    var grid := GridContainer.new(); grid.columns = GameDataRef.BOARD_COLS; grid.add_theme_constant_override("h_separation", 7); grid.add_theme_constant_override("v_separation", 7)
    slot_buttons.clear()
    for i in range(GameDataRef.BOARD_SIZE):
        var slot_button := _make_slot(i)
        slot_buttons.append(slot_button)
        grid.add_child(slot_button)
    grid_panel.add_child(_margin(grid, 12)); v.add_child(grid_panel)

    var selected_text := _label(_selected_description(), 18, C_TEXT)
    selected_text.custom_minimum_size.y = 56
    v.add_child(selected_text)

    var action_row := HBoxContainer.new(); action_row.add_theme_constant_override("separation", 10)
    var dismantle := _button("Разобрать", _dismantle_selected, 52); dismantle.size_flags_horizontal = Control.SIZE_EXPAND_FILL; dismantle.disabled = selected_slot < 0; action_row.add_child(dismantle)
    var shuffle := _button("Перемешать", _shuffle_board, 52); shuffle.size_flags_horizontal = Control.SIZE_EXPAND_FILL; action_row.add_child(shuffle)
    v.add_child(action_row)

    var shop_panel := _panel(); var shop_box := VBoxContainer.new(); shop_box.add_theme_constant_override("separation", 8)
    var sh := HBoxContainer.new(); var st := _label("Находки", 23, C_TEXT); st.size_flags_horizontal = Control.SIZE_EXPAND_FILL; sh.add_child(st)
    sh.add_child(_button("Обновить · 3⚙", _reroll_shop, 46)); shop_box.add_child(sh)
    var offers := HBoxContainer.new(); offers.add_theme_constant_override("separation", 7)
    for i in range(shop.size()): offers.add_child(_make_offer(i))
    shop_box.add_child(offers); shop_panel.add_child(_margin(shop_box, 12)); v.add_child(shop_panel)

    v.add_child(_button("В БОЙ", start_battle, 68, true))

    if not bool(save_data["tutorial_seen"]):
        _show_tutorial_overlay()

func _make_slot(index: int) -> Button:
    var b := Button.new()
    b.custom_minimum_size = Vector2(121, 121)
    b.expand_icon = true
    b.icon_max_width = 62
    b.add_theme_font_size_override("font_size", 15)
    var chosen := index == selected_slot
    b.add_theme_stylebox_override("normal", _style_box(Color("3a4354"), 12, C_ACCENT if chosen else Color("536076"), 3 if chosen else 1))
    b.add_theme_stylebox_override("pressed", _style_box(Color("465267"), 12, C_ACCENT, 3))
    var item = board[index]
    if item == null:
        b.text = "·"
        b.add_theme_color_override("font_color", Color("69758b"))
    else:
        var data: Dictionary = GameDataRef.ITEMS[item["id"]]
        b.icon = load(data["icon"])
        b.text = "\n\n\nT%d" % int(item["tier"])
        b.add_theme_color_override("font_color", _tier_color(int(item["tier"])))
    b.pressed.connect(func():
        sfx_click.play()
        _slot_pressed(index)
    )
    return b

func _slot_pressed(index: int) -> void:
    if selected_slot < 0:
        if board[index] != null:
            selected_slot = index
    elif selected_slot == index:
        selected_slot = -1
    else:
        var src = board[selected_slot]
        var dst = board[index]
        if dst == null:
            board[index] = src; board[selected_slot] = null; selected_slot = -1
        elif src["id"] == dst["id"] and int(src["tier"]) == int(dst["tier"]) and int(src["tier"]) < GameDataRef.MAX_TIER:
            var merged_id: String = src["id"]
            board[index] = {"id":merged_id, "tier":int(src["tier"]) + 1}
            board[selected_slot] = null
            selected_slot = -1
            sfx_merge.play()
            _play_merge_fx(index, merged_id)
            get_tree().create_timer(0.28).timeout.connect(show_prepare, CONNECT_ONE_SHOT)
            return
        else:
            board[selected_slot] = dst; board[index] = src; selected_slot = index
    show_prepare()

func _play_merge_fx(index: int, item_id: String) -> void:
    if index < 0 or index >= slot_buttons.size(): return
    var slot: Button = slot_buttons[index]
    if not is_instance_valid(slot): return
    var local_rect := slot.get_global_rect()
    local_rect.position -= screen_root.global_position

    var glow := Panel.new()
    glow.position = local_rect.position - Vector2(6, 6)
    glow.size = local_rect.size + Vector2(12, 12)
    glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
    glow.add_theme_stylebox_override("panel", _style_box(Color(0.35, 0.90, 0.78, 0.18), 18, C_ACCENT, 4))
    screen_root.add_child(glow)

    var icon := TextureRect.new()
    icon.texture = load(GameDataRef.ITEMS[item_id]["icon"])
    icon.position = local_rect.position + local_rect.size * 0.5 - Vector2(48, 48)
    icon.size = Vector2(96, 96)
    icon.pivot_offset = icon.size * 0.5
    icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    screen_root.add_child(icon)

    var tw := icon.create_tween()
    tw.set_parallel(true)
    tw.tween_property(icon, "scale", Vector2(1.55, 1.55), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tw.tween_property(icon, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.28)
    var gw := glow.create_tween()
    gw.set_parallel(true)
    gw.tween_property(glow, "scale", Vector2(1.12, 1.12), 0.28)
    gw.tween_property(glow, "modulate", Color(1,1,1,0), 0.28)

func _selected_description() -> String:
    if selected_slot < 0 or board[selected_slot] == null:
        return "Тапни предмет, затем другую клетку: перенос, обмен или слияние одинаковых уровней."
    var item = board[selected_slot]
    var d: Dictionary = GameDataRef.ITEMS[item["id"]]
    return "%s · T%d — %s" % [d["name"], int(item["tier"]), d["desc"]]

func _dismantle_selected() -> void:
    if selected_slot < 0 or board[selected_slot] == null: return
    var item = board[selected_slot]
    scrap += max(2, int(GameDataRef.item_cost(item["id"], int(item["tier"])) * 0.45))
    board[selected_slot] = null
    selected_slot = -1
    show_prepare()

func _shuffle_board() -> void:
    var items := []
    for it in board:
        if it != null: items.append(it)
    board.clear()
    for _i in range(GameDataRef.BOARD_SIZE): board.append(null)
    var cells := range(GameDataRef.BOARD_SIZE)
    cells.shuffle()
    for i in range(items.size()): board[cells[i]] = items[i]
    selected_slot = -1
    show_prepare()

func _roll_shop(initial := false) -> void:
    shop.clear()
    var ids := GameDataRef.ITEMS.keys()
    var max_tier := 1 if stage_index < 2 else 2
    for _i in range(3):
        var id: String = ids[_weighted_item_index(ids)]
        var tier := 1
        if max_tier >= 2 and rng.randf() < 0.13: tier = 2
        shop.append({"id":id, "tier":tier})
    if initial and chapter_index == 0:
        shop[0] = {"id":"blade", "tier":1}
        shop[1] = {"id":"thread", "tier":1}

func _weighted_item_index(ids: Array) -> int:
    var total := 0
    for id in ids: total += int(GameDataRef.ITEMS[id]["weight"])
    var pick := rng.randi_range(1, total)
    for i in range(ids.size()):
        pick -= int(GameDataRef.ITEMS[ids[i]]["weight"])
        if pick <= 0: return i
    return 0

func _reroll_shop() -> void:
    if scrap < 3: return
    scrap -= 3
    _roll_shop()
    show_prepare()

func _make_offer(index: int) -> VBoxContainer:
    var item = shop[index]
    var d: Dictionary = GameDataRef.ITEMS[item["id"]]
    var box := VBoxContainer.new(); box.size_flags_horizontal = Control.SIZE_EXPAND_FILL; box.add_theme_constant_override("separation", 4)
    var icon := TextureRect.new(); icon.texture = load(d["icon"]); icon.custom_minimum_size = Vector2(70,70); icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; box.add_child(icon)
    box.add_child(_label(d["name"], 15, C_TEXT, HORIZONTAL_ALIGNMENT_CENTER))
    var cost := GameDataRef.item_cost(item["id"], int(item["tier"]))
    var b := _button("%d⚙" % cost, _buy_offer.bind(index), 44, false); b.disabled = scrap < cost or _first_empty_slot() < 0; box.add_child(b)
    return box

func _buy_offer(index: int) -> void:
    if index < 0 or index >= shop.size(): return
    var slot := _first_empty_slot()
    if slot < 0: return
    var item = shop[index]
    var cost := GameDataRef.item_cost(item["id"], int(item["tier"]))
    if scrap < cost: return
    scrap -= cost
    board[slot] = item.duplicate(true)
    _roll_shop()
    show_prepare()

func _first_empty_slot() -> int:
    for i in range(board.size()):
        if board[i] == null: return i
    return -1

func _tier_color(tier: int) -> Color:
    match tier:
        2: return Color("72d8c0")
        3: return Color("b993ff")
        4: return Color("f2cc69")
        _: return C_TEXT

func _show_tutorial_overlay() -> void:
    var overlay := ColorRect.new(); overlay.color = Color(0.03,0.04,0.06,0.82); overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); screen_root.add_child(overlay)
    var m := MarginContainer.new(); m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); m.add_theme_constant_override("margin_left",42); m.add_theme_constant_override("margin_right",42); m.add_theme_constant_override("margin_top",300); m.add_theme_constant_override("margin_bottom",300); overlay.add_child(m)
    var p := _panel(); var vb := VBoxContainer.new(); vb.add_theme_constant_override("separation",12)
    vb.add_child(_label("Как работает мастерская", 30, C_TEXT))
    vb.add_child(_label("1. Купи предмет.\n2. Тапни предмет на сетке и затем другую клетку.\n3. Два одинаковых предмета одного T-уровня сольются.\n4. Соседство важно: нити усиливают предметы вокруг себя.\n5. Нажми «В БОЙ» — дальше герой сражается сам.", 22, C_TEXT))
    vb.add_child(_button("Понятно", _dismiss_tutorial, 62, true))
    p.add_child(_margin(vb,22)); m.add_child(p)

func _dismiss_tutorial() -> void:
    save_data["tutorial_seen"] = true
    SaveManagerRef.save(save_data)
    show_prepare()

func _noop() -> void:
    pass

# ---------- STAT BUILD ----------
func _neighbors(index: int) -> Array:
    var out := []
    var x := index % GameDataRef.BOARD_COLS
    var y := index / GameDataRef.BOARD_COLS
    if x > 0: out.append(index - 1)
    if x < GameDataRef.BOARD_COLS - 1: out.append(index + 1)
    if y > 0: out.append(index - GameDataRef.BOARD_COLS)
    if y < GameDataRef.BOARD_ROWS - 1: out.append(index + GameDataRef.BOARD_COLS)
    return out

func _adjacent_count(index: int, predicate: Callable) -> int:
    var n := 0
    for j in _neighbors(index):
        if board[j] != null and predicate.call(board[j]): n += 1
    return n

func _calculate_stats() -> Dictionary:
    var s := {
        "attack": 18.0 * (1.0 + 0.04 * int(save_data["attack_knot"])),
        "max_hp": 120.0 * (1.0 + 0.06 * int(save_data["vital_knot"])),
        "armor": 0.0, "attack_speed": 1.0, "crit": 0.05, "dodge": 0.0,
        "lifesteal": 0.0, "regen": 0.0, "magic": 0.0, "bell": 0.0,
        "link_score": 0.0, "damage_mult": 1.0, "guard_mult": 1.0
    }
    for i in range(board.size()):
        var item = board[i]
        if item == null: continue
        var tier := int(item["tier"])
        var m := GameDataRef.tier_mult(tier)
        var id: String = item["id"]
        var linked := _adjacent_count(i, func(other): return other["id"] == "thread")
        var neighbors := _neighbors(i).filter(func(j): return board[j] != null).size()
        if id == "blade":
            s["attack"] += 8.0 * m * (1.0 + linked * 0.15)
        elif id == "buckler":
            s["max_hp"] += 28.0 * m; s["armor"] += 3.2 * m
            var steel_near := _adjacent_count(i, func(other): return "steel" in GameDataRef.ITEMS[other["id"]]["tags"])
            s["guard_mult"] *= max(0.72, 1.0 - steel_near * 0.035)
        elif id == "sigil":
            s["magic"] += 9.0 * m * (1.0 + linked * 0.22)
        elif id == "boot":
            s["attack_speed"] += 0.10 * m; s["dodge"] += 0.012 * m
        elif id == "charm":
            s["lifesteal"] += 0.018 * m; s["max_hp"] += 9.0 * m
        elif id == "cog":
            s["attack_speed"] += 0.075 * m; s["crit"] += 0.018 * m
            var rune_near := _adjacent_count(i, func(other): return other["id"] == "rune")
            s["crit"] += rune_near * 0.025
        elif id == "lantern":
            s["regen"] += 1.8 * m; s["max_hp"] += 8.0 * m
        elif id == "thread":
            s["link_score"] += neighbors * tier
            s["damage_mult"] *= 1.0 + neighbors * 0.018 * tier
        elif id == "rune":
            s["crit"] += 0.028 * m
            var arcane_near := _adjacent_count(i, func(other): return "arcane" in GameDataRef.ITEMS[other["id"]]["tags"])
            s["magic"] += arcane_near * 2.0 * m
        elif id == "bell":
            s["bell"] += 7.0 * m
        elif id == "mirror":
            s["dodge"] += 0.025 * m
        elif id == "spindle":
            s["attack"] += 4.0 * m * (1.0 + linked * 0.30); s["max_hp"] += 13.0 * m * (1.0 + linked * 0.20)
    s["crit"] = min(0.62, float(s["crit"]))
    s["dodge"] = min(0.42, float(s["dodge"]))
    return s

# ---------- BATTLE ----------
func start_battle() -> void:
    _clear_screen()
    battle_stats = _calculate_stats()
    var enemy_id: String = GameDataRef.CHAPTERS[chapter_index]["enemies"][stage_index]
    enemy_data = GameDataRef.ENEMIES[enemy_id].duplicate(true)
    var scale := GameDataRef.chapter_scale(chapter_index, stage_index)
    hero_max_hp = float(battle_stats["max_hp"])
    hero_hp = hero_max_hp
    enemy_max_hp = float(enemy_data["hp"]) * scale
    enemy_hp = enemy_max_hp
    hero_timer = 0.45
    enemy_timer = 1.0
    magic_timer = 1.4
    bell_timer = 2.8
    regen_timer = 1.0
    enemy_hit_count = 0; hero_attack_count = 0; enemy_stun = 0.0; mirror_charge = false
    battle_speed = 1.0

    _set_background(GameDataRef.CHAPTERS[chapter_index]["background"])
    var v := _main_vbox(28, 28, 14)
    var battle_head := HBoxContainer.new()
    battle_head.add_theme_constant_override("separation", 10)
    var battle_title := _label("Бой %d/5" % (stage_index + 1), 25, C_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
    battle_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    battle_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    battle_head.add_child(battle_title)
    var speed_button := _button("×1", _toggle_battle_speed, 48)
    speed_button.name = "BattleSpeedButton"
    speed_button.custom_minimum_size.x = 74
    battle_head.add_child(speed_button)
    v.add_child(battle_head)

    combat_area = Control.new(); combat_area.custom_minimum_size.y = 590; v.add_child(combat_area)
    hero_actor = _actor_texture("res://assets/actors/hero.png", Vector2(80, 250)); combat_area.add_child(hero_actor)
    enemy_actor = _actor_texture(enemy_data["sprite"], Vector2(430, 250)); combat_area.add_child(enemy_actor)
    var versus := _label("×", 44, C_MUTED, HORIZONTAL_ALIGNMENT_CENTER); versus.position=Vector2(313,312); versus.size=Vector2(64,64); combat_area.add_child(versus)

    var hero_name := _label("Связующий", 22, C_TEXT); hero_name.position=Vector2(20,160); hero_name.size=Vector2(250,40); combat_area.add_child(hero_name)
    var enemy_name := _label(enemy_data["name"], 22, C_TEXT, HORIZONTAL_ALIGNMENT_RIGHT); enemy_name.position=Vector2(370,160); enemy_name.size=Vector2(280,40); combat_area.add_child(enemy_name)
    var trait_label := _label(enemy_data["trait"], 17, C_MUTED, HORIZONTAL_ALIGNMENT_RIGHT); trait_label.position=Vector2(350,200); trait_label.size=Vector2(300,50); combat_area.add_child(trait_label)

    hero_hp_bar = _hp_bar(hero_max_hp, hero_hp); hero_hp_bar.position=Vector2(20,460); hero_hp_bar.size=Vector2(280,28); combat_area.add_child(hero_hp_bar)
    enemy_hp_bar = _hp_bar(enemy_max_hp, enemy_hp); enemy_hp_bar.position=Vector2(360,460); enemy_hp_bar.size=Vector2(280,28); combat_area.add_child(enemy_hp_bar)
    hero_hp_label = _label("", 18, C_TEXT); hero_hp_label.position=Vector2(20,495); hero_hp_label.size=Vector2(280,30); combat_area.add_child(hero_hp_label)
    enemy_hp_label = _label("", 18, C_TEXT, HORIZONTAL_ALIGNMENT_RIGHT); enemy_hp_label.position=Vector2(360,495); enemy_hp_label.size=Vector2(280,30); combat_area.add_child(enemy_hp_label)

    battle_log_label = _label("Связи натянуты. Бой начинается.", 20, C_TEXT, HORIZONTAL_ALIGNMENT_CENTER); battle_log_label.custom_minimum_size.y=70; v.add_child(battle_log_label)
    var statline := "ATK %d  •  CRIT %d%%  •  уклон %d%%  •  вамп %d%%" % [int(battle_stats["attack"]), int(float(battle_stats["crit"])*100), int(float(battle_stats["dodge"])*100), int(float(battle_stats["lifesteal"])*100)]
    v.add_child(_label(statline, 18, C_MUTED, HORIZONTAL_ALIGNMENT_CENTER))
    battle_continue_button = _button("...", _noop, 68, true); battle_continue_button.visible=false; v.add_child(battle_continue_button)
    _update_battle_ui()
    battle_active = true
    _spawn_battle_caption("СВЯЗЬ", Vector2(330, 340), C_ACCENT)

func _actor_texture(path: String, pos: Vector2) -> TextureRect:
    var t := TextureRect.new()
    t.texture = load(path)
    t.position = pos
    t.size = Vector2(210,210)
    t.pivot_offset = t.size * 0.5
    t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    return t

func _hp_bar(maxv: float, value: float) -> ProgressBar:
    var b := ProgressBar.new(); b.max_value=maxv; b.value=value; b.show_percentage=false; b.add_theme_stylebox_override("background", _style_box(Color("2b303c"),8)); b.add_theme_stylebox_override("fill", _style_box(C_ACCENT,8)); return b

func _toggle_battle_speed() -> void:
    battle_speed = 2.0 if battle_speed < 1.5 else 1.0
    if screen_root != null:
        var b := screen_root.find_child("BattleSpeedButton", true, false) as Button
        if b != null: b.text = "×2" if battle_speed > 1.5 else "×1"

func _battle_tick(delta: float) -> void:
    hero_timer -= delta
    enemy_timer -= delta
    magic_timer -= delta
    bell_timer -= delta
    regen_timer -= delta
    enemy_stun = max(0.0, enemy_stun - delta)
    _animate_idle(hero_actor, Time.get_ticks_msec() * 0.001, 0.018)
    _animate_idle(enemy_actor, Time.get_ticks_msec() * 0.001 + 1.3, -0.016)

    if hero_timer <= 0.0:
        _hero_attack()
        hero_timer = max(0.25, 1.0 / float(battle_stats["attack_speed"]))
    if magic_timer <= 0.0 and float(battle_stats["magic"]) > 0:
        var dmg := float(battle_stats["magic"]) * float(battle_stats["damage_mult"])
        _spawn_battle_icon("res://assets/items/sigil.png", enemy_actor, C_ACCENT)
        _damage_enemy(dmg, "Знак связи вспыхивает: −%d" % int(dmg), C_ACCENT)
        magic_timer = max(0.72, 2.45 - float(battle_stats["link_score"]) * 0.018)
    if bell_timer <= 0.0 and float(battle_stats["bell"]) > 0:
        var dmg := float(battle_stats["bell"])
        enemy_stun = 0.52
        _spawn_battle_icon("res://assets/items/bell.png", enemy_actor, Color("c39cff"))
        _damage_enemy(dmg, "Колокол сбивает ритм: −%d" % int(dmg), Color("c39cff"))
        bell_timer = 3.6
    if regen_timer <= 0.0 and float(battle_stats["regen"]) > 0:
        var healed := min(float(battle_stats["regen"]), hero_max_hp - hero_hp)
        hero_hp = min(hero_max_hp, hero_hp + float(battle_stats["regen"]))
        if healed > 0.1: _floating_text("+%d" % int(healed), hero_actor, C_ACCENT)
        regen_timer = 1.0
    if enemy_timer <= 0.0 and enemy_stun <= 0.0:
        _enemy_attack()
        var speed := float(enemy_data["speed"])
        if enemy_data["name"] == "Пустой часовой" and enemy_hp < enemy_max_hp * 0.5: speed *= 1.35
        enemy_timer = 1.0 / speed
    _update_battle_ui()

func _animate_idle(node: Control, phase: float, amount: float) -> void:
    if node == null or not is_instance_valid(node): return
    if node.modulate.a < 0.1: return
    node.rotation = sin(phase * 2.1) * amount
    var breathe := 1.0 + sin(phase * 2.8) * 0.012
    node.scale = Vector2(breathe, breathe)

func _hero_attack() -> void:
    hero_attack_count += 1
    var dmg := float(battle_stats["attack"]) * float(battle_stats["damage_mult"])
    var critical := rng.randf() < float(battle_stats["crit"])
    if critical: dmg *= 1.75
    if mirror_charge: dmg *= 1.45; mirror_charge=false
    if enemy_data["name"] == "Сломанный дозорный": dmg *= 0.86
    if enemy_data["name"] == "Последний сторож" and rng.randf() < 0.20: dmg *= 0.55
    var text := ("Критический удар" if critical else "Удар") + ": −%d" % int(dmg)
    _animate_attack(hero_actor, 22.0)
    _damage_enemy(dmg, text, C_GOLD if critical else C_TEXT)
    var heal := dmg * float(battle_stats["lifesteal"])
    if heal > 0:
        hero_hp = min(hero_max_hp, hero_hp + heal)
        _floating_text("+%d" % int(heal), hero_actor, Color("7ee4a8"))

func _enemy_attack() -> void:
    enemy_hit_count += 1
    if rng.randf() < float(battle_stats["dodge"]):
        battle_log_label.text = "Ты уходишь с линии удара. Зеркало запоминает движение."
        mirror_charge = _has_item("mirror")
        _animate_dodge(hero_actor)
        _floating_text("УКЛОН", hero_actor, C_ACCENT)
        return
    var raw := float(enemy_data["atk"]) * GameDataRef.chapter_scale(chapter_index, stage_index)
    if enemy_data["name"] == "Тень прихожанина" and enemy_hit_count % 3 == 0: raw *= 1.65
    if enemy_data["name"] == "Чернильный писец": raw *= 1.0 + min(0.7, enemy_hit_count * 0.035)
    if enemy_data["name"] == "Связанный маг" and enemy_hit_count % 4 == 0: raw *= 1.85
    var reduced := max(1.0, raw - float(battle_stats["armor"])) * float(battle_stats["guard_mult"])
    hero_hp -= reduced
    battle_log_label.text = "%s наносит %d урона." % [enemy_data["name"], int(reduced)]
    sfx_hit.play()
    _animate_attack(enemy_actor, -22.0)
    _floating_text("-%d" % int(reduced), hero_actor, C_DANGER)
    if hero_hp <= 0:
        hero_hp=0
        _animate_death(hero_actor, -1.0)
        _battle_defeat()
    else:
        _animate_hit(hero_actor)

func _damage_enemy(dmg: float, text: String, fx_color := C_TEXT) -> void:
    enemy_hp -= dmg
    battle_log_label.text = text
    sfx_hit.play()
    _floating_text("-%d" % int(dmg), enemy_actor, fx_color)
    if enemy_hp <= 0:
        enemy_hp = 0
        _animate_death(enemy_actor, 1.0)
        _battle_victory()
    else:
        _animate_hit(enemy_actor)

func _animate_attack(node: Control, dx: float) -> void:
    if node == null or not is_instance_valid(node): return
    var origin := node.position
    var tw := node.create_tween()
    tw.tween_property(node, "position", origin + Vector2(dx, -4), 0.065).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tw.tween_property(node, "position", origin, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _animate_hit(node: Control) -> void:
    if node == null or not is_instance_valid(node): return
    var origin := node.position
    var flash := node.create_tween()
    flash.tween_property(node, "modulate", Color(1.0, 0.55, 0.55, 1.0), 0.055)
    flash.tween_property(node, "modulate", Color.WHITE, 0.09)
    var shake := node.create_tween()
    shake.tween_property(node, "position", origin + Vector2(8, 0), 0.035)
    shake.tween_property(node, "position", origin - Vector2(6, 0), 0.035)
    shake.tween_property(node, "position", origin, 0.05)

func _animate_dodge(node: Control) -> void:
    if node == null or not is_instance_valid(node): return
    var origin := node.position
    var tw := node.create_tween()
    tw.tween_property(node, "position", origin + Vector2(-26, -5), 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tw.tween_property(node, "position", origin, 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _animate_death(node: Control, direction: float) -> void:
    if node == null or not is_instance_valid(node): return
    var tw := node.create_tween()
    tw.set_parallel(true)
    tw.tween_property(node, "rotation", direction * 0.32, 0.38).set_trans(Tween.TRANS_BACK)
    tw.tween_property(node, "position", node.position + Vector2(direction * 24.0, 28.0), 0.38)
    tw.tween_property(node, "scale", Vector2(0.82, 0.82), 0.38)
    tw.tween_property(node, "modulate", Color(0.7, 0.7, 0.78, 0.15), 0.42)

func _floating_text(text: String, actor: Control, color: Color) -> void:
    if combat_area == null or actor == null or not is_instance_valid(actor): return
    var l := _label(text, 24, color, HORIZONTAL_ALIGNMENT_CENTER)
    l.position = actor.position + Vector2(35, 15)
    l.size = Vector2(140, 42)
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    combat_area.add_child(l)
    var tw := l.create_tween()
    tw.set_parallel(true)
    tw.tween_property(l, "position", l.position + Vector2(0, -54), 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tw.tween_property(l, "modulate", Color(color.r, color.g, color.b, 0.0), 0.55)
    tw.chain().tween_callback(l.queue_free)

func _spawn_battle_icon(path: String, actor: Control, tint: Color) -> void:
    if combat_area == null or actor == null or not is_instance_valid(actor): return
    var icon := TextureRect.new()
    icon.texture = load(path)
    icon.position = actor.position + Vector2(65, 45)
    icon.size = Vector2(82, 82)
    icon.pivot_offset = icon.size * 0.5
    icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon.modulate = tint
    icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    combat_area.add_child(icon)
    icon.scale = Vector2(0.35, 0.35)
    var tw := icon.create_tween()
    tw.set_parallel(true)
    tw.tween_property(icon, "scale", Vector2(1.25, 1.25), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tw.tween_property(icon, "rotation", 0.32, 0.32)
    tw.tween_property(icon, "modulate", Color(tint.r, tint.g, tint.b, 0.0), 0.40).set_delay(0.08)
    tw.chain().tween_callback(icon.queue_free)

func _spawn_battle_caption(text: String, pos: Vector2, color: Color) -> void:
    if combat_area == null: return
    var l := _label(text, 30, color, HORIZONTAL_ALIGNMENT_CENTER)
    l.position = pos - Vector2(90, 0)
    l.size = Vector2(180, 52)
    l.scale = Vector2(0.6, 0.6)
    l.pivot_offset = l.size * 0.5
    combat_area.add_child(l)
    var tw := l.create_tween()
    tw.tween_property(l, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tw.tween_interval(0.22)
    tw.tween_property(l, "modulate", Color(color.r, color.g, color.b, 0.0), 0.30)
    tw.tween_callback(l.queue_free)

func _has_item(id: String) -> bool:
    for it in board:
        if it != null and it["id"] == id: return true
    return false

func _update_battle_ui() -> void:
    if hero_hp_bar == null: return
    hero_hp_bar.value = hero_hp; enemy_hp_bar.value = enemy_hp
    hero_hp_label.text = "%d / %d" % [int(hero_hp), int(hero_max_hp)]
    enemy_hp_label.text = "%d / %d" % [int(enemy_hp), int(enemy_max_hp)]

func _battle_victory() -> void:
    if not battle_active: return
    battle_active = false
    sfx_victory.play()
    var reward := int(enemy_data["reward"]) + stage_index * 2
    scrap += reward
    stage_index += 1
    battle_log_label.text = "Победа. Найдено %d деталей." % reward
    battle_continue_button.visible = true
    battle_continue_button.text = "ЗАБРАТЬ ДОБЫЧУ"
    battle_continue_button.pressed.connect(_after_battle_continue)

func _after_battle_continue() -> void:
    if stage_index >= 5:
        _complete_chapter()
    else:
        show_loot_choice()

func show_loot_choice() -> void:
    _clear_screen()
    var ch: Dictionary = GameDataRef.CHAPTERS[chapter_index]
    _set_background(ch["background"])
    loot_choices = _roll_loot_choices()

    var v := _main_vbox(52, 26, 16)
    v.add_child(_label("Награда за бой", 34, C_GOLD, HORIZONTAL_ALIGNMENT_CENTER))
    v.add_child(_label("Выбери один артефакт. Никаких сундуков за рекламу — только решение для текущего билда.", 20, C_MUTED, HORIZONTAL_ALIGNMENT_CENTER))

    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 10)
    for i in range(loot_choices.size()):
        row.add_child(_make_loot_card(i))
    v.add_child(row)

    var full_hint := "Если сетка заполнена, выбранный предмет автоматически разбирается в детали."
    v.add_child(_label(full_hint, 18, C_MUTED, HORIZONTAL_ALIGNMENT_CENTER))
    v.add_child(_button("Пропустить · +4⚙", _skip_loot, 60))

func _roll_loot_choices() -> Array:
    var out := []
    var ids := GameDataRef.ITEMS.keys()
    for _i in range(3):
        var id: String = ids[_weighted_item_index(ids)]
        var tier := 1
        var tier_two_chance := 0.08 + stage_index * 0.045 + chapter_index * 0.03
        if rng.randf() < tier_two_chance: tier = 2
        out.append({"id": id, "tier": tier})
    return out

func _make_loot_card(index: int) -> VBoxContainer:
    var item: Dictionary = loot_choices[index]
    var d: Dictionary = GameDataRef.ITEMS[item["id"]]
    var card := VBoxContainer.new()
    card.custom_minimum_size.x = 205
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    card.add_theme_constant_override("separation", 8)

    var p := _panel()
    var inside := VBoxContainer.new()
    inside.add_theme_constant_override("separation", 8)
    var icon := _art(d["icon"], Vector2(0, 126))
    inside.add_child(icon)
    inside.add_child(_label(d["name"], 20, _tier_color(int(item["tier"])), HORIZONTAL_ALIGNMENT_CENTER))
    inside.add_child(_label("T%d · %s" % [int(item["tier"]), d["kind"]], 17, C_GOLD, HORIZONTAL_ALIGNMENT_CENTER))
    inside.add_child(_label(d["desc"], 16, C_MUTED, HORIZONTAL_ALIGNMENT_CENTER))
    inside.add_child(_button("ВЗЯТЬ", _choose_loot.bind(index), 54, true))
    p.add_child(_margin(inside, 12))
    card.add_child(p)
    return card

func _choose_loot(index: int) -> void:
    if index < 0 or index >= loot_choices.size(): return
    var item: Dictionary = loot_choices[index]
    var slot := _first_empty_slot()
    if slot >= 0:
        board[slot] = item.duplicate(true)
    else:
        scrap += max(3, int(GameDataRef.item_cost(item["id"], int(item["tier"])) * 0.55))
    _roll_shop()
    selected_slot = -1
    show_prepare()

func _skip_loot() -> void:
    scrap += 4
    _roll_shop()
    selected_slot = -1
    show_prepare()

func _battle_defeat() -> void:
    if not battle_active: return
    battle_active = false
    var earned := 4 + chapter_index * 3 + stage_index * 3
    save_data["embers"] = int(save_data["embers"]) + earned
    SaveManagerRef.save(save_data)
    battle_log_label.text = "Связь рвётся. Ты уносишь %d Искр для постоянных улучшений." % earned
    battle_continue_button.visible = true
    battle_continue_button.text = "В ЛАГЕРЬ"
    battle_continue_button.pressed.connect(show_home)

func _complete_chapter() -> void:
    var bonus := 14 + chapter_index * 8
    save_data["embers"] = int(save_data["embers"]) + bonus
    save_data["wins"] = int(save_data["wins"]) + 1
    if chapter_index < GameDataRef.CHAPTERS.size() - 1:
        save_data["max_chapter"] = max(int(save_data["max_chapter"]), chapter_index + 1)
    SaveManagerRef.save(save_data)
    show_story_card(false)

func _confirm_abandon() -> void:
    var earned := max(1, stage_index * 2)
    save_data["embers"] = int(save_data["embers"]) + earned
    SaveManagerRef.save(save_data)
    show_home()

# ---------- META ----------
func show_upgrades() -> void:
    _clear_screen(); _set_background("res://assets/backgrounds/archive.png")
    var v := _main_vbox(42, 28, 16)
    var head := HBoxContainer.new(); var back:=_button("‹",show_home,58); back.custom_minimum_size.x=72; head.add_child(back); var title:=_label("Узлы силы",34,C_TEXT); title.size_flags_horizontal=Control.SIZE_EXPAND_FILL; title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; head.add_child(title); v.add_child(head)
    var ember_row := HBoxContainer.new()
    ember_row.alignment = BoxContainer.ALIGNMENT_CENTER
    ember_row.add_theme_constant_override("separation", 8)
    ember_row.add_child(_art("res://assets/props/ember_shard.png", Vector2(46, 46)))
    ember_row.add_child(_label("Искры: %d" % int(save_data["embers"]), 28, C_GOLD))
    v.add_child(ember_row)
    v.add_child(_label("Это вся мета-прогрессия демо. Никаких премиальных валют: Искры даются за обычную игру.", 20, C_MUTED))
    _upgrade_card(v,"attack_knot","Узел натяжения","+4% базовой атаки за уровень",8,"res://assets/props/attack_up.png")
    _upgrade_card(v,"vital_knot","Узел дыхания","+6% базового здоровья за уровень",8,"res://assets/props/defense_up.png")
    _upgrade_card(v,"purse_knot","Карман мастера","+2 детали в начале забега за уровень",10,"res://assets/props/treasure_chest.png")
    v.add_child(_label("Забегов: %d  •  завершённых глав: %d" % [int(save_data["runs"]), int(save_data["wins"])], 20, C_MUTED, HORIZONTAL_ALIGNMENT_CENTER))

func _upgrade_card(parent: VBoxContainer, key: String, title: String, desc: String, base_cost: int, icon_path: String) -> void:
    var level := int(save_data[key]); var cost := base_cost + level * (base_cost / 2 + 2)
    var p:=_panel(); var box:=VBoxContainer.new(); box.add_theme_constant_override("separation",8)
    var head := HBoxContainer.new()
    head.add_theme_constant_override("separation", 12)
    head.add_child(_art(icon_path, Vector2(64, 64)))
    var title_box := VBoxContainer.new()
    title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title_box.add_child(_label("%s · ур. %d" % [title,level],26,C_TEXT))
    title_box.add_child(_label(desc,19,C_MUTED))
    head.add_child(title_box)
    box.add_child(head)
    var b:=_button("Улучшить · %d Искр" % cost, _buy_upgrade.bind(key, cost),56,true); b.disabled=int(save_data["embers"])<cost; box.add_child(b)
    p.add_child(_margin(box,16)); parent.add_child(p)

func _buy_upgrade(key:String,cost:int)->void:
    if int(save_data["embers"])<cost:return
    save_data["embers"]=int(save_data["embers"])-cost; save_data[key]=int(save_data[key])+1; SaveManagerRef.save(save_data); show_upgrades()

func show_archive() -> void:
    _clear_screen(); _set_background("res://assets/backgrounds/archive.png")
    var v:=_main_vbox(38,28,14)
    var head:=HBoxContainer.new(); var back:=_button("‹",show_home,58); back.custom_minimum_size.x=72; head.add_child(back); var title:=_label("Архив",34,C_TEXT); title.size_flags_horizontal=Control.SIZE_EXPAND_FILL; title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; head.add_child(title); v.add_child(head)
    var archive_art := _art("res://assets/props/bookshelf.png", Vector2(0, 150))
    v.add_child(archive_art)
    v.add_child(_label("Черновые записи истории. Главы открываются прохождением, а не покупкой.",20,C_MUTED))
    for i in range(GameDataRef.CHAPTERS.size()):
        var ch:Dictionary=GameDataRef.CHAPTERS[i]; var unlocked:=i<=int(save_data["max_chapter"])
        var p:=_panel(); var box:=VBoxContainer.new(); box.add_theme_constant_override("separation",6); box.add_child(_label(ch["name"],25,C_TEXT if unlocked else C_MUTED)); box.add_child(_label((ch["intro"]+"\n\n"+ch["outro"]) if unlocked else "Запись пока пуста.",18,C_MUTED)); p.add_child(_margin(box,16)); v.add_child(p)

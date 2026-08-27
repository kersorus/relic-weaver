extends SceneTree

const GameDataRef = preload("res://src/game_data.gd")
const SaveManagerRef = preload("res://src/save_manager.gd")

var failures: Array[String] = []

func _init() -> void:
    call_deferred("_run_checks")

func _run_checks() -> void:
    _check(
        str(ProjectSettings.get_setting("application/config/version", "")) == "1.1.1",
        "project version is 1.1.1"
    )
    _check(
        FileAccess.get_file_as_string("res://VERSION").strip_edges() == "1.1.1",
        "VERSION file matches project metadata"
    )
    var export_presets := FileAccess.get_file_as_string("res://export_presets.cfg")
    _check(
        export_presets.count("binary_format/embed_pck=true") == 2,
        "desktop exports embed PCK without release-name collisions"
    )
    _check(GameDataRef.ITEMS.size() >= 12, "item catalog has at least 12 artifacts")
    _check(GameDataRef.CHAPTERS.size() >= 4, "campaign has four release chapters")
    _check(GameDataRef.tier_mult(4) > GameDataRef.tier_mult(3), "tier scaling increases")
    _check(ResourceLoader.exists("res://src/item_slot.gd"), "draggable board slot script exists")
    _check(ResourceLoader.exists("res://src/shop_drag_icon.gd"), "draggable shop offer script exists")
    var main_source := FileAccess.get_file_as_string("res://src/main.gd")
    _check("сундуков за рекламу" not in main_source, "interface copy avoids artificial advertising language")
    _check_catalog_resources()

    var sanitized := SaveManagerRef.sanitize({
        "embers": -500,
        "attack_knot": 999,
        "settings": {"sfx_volume": 7.0, "battle_speed": 9.0, "haptics": false},
        "completed_chapters": [0, 0, 2, -1]
    })
    _check(int(sanitized["embers"]) == 0, "negative currency is rejected")
    _check(
        int(sanitized["attack_knot"]) == SaveManagerRef.MAX_UPGRADE_LEVEL,
        "upgrade level is capped"
    )
    _check(float(sanitized["settings"]["sfx_volume"]) == 1.0, "audio volume is clamped")
    _check(float(sanitized["settings"]["battle_speed"]) == 2.0, "battle speed is normalized")
    _check(not bool(sanitized["settings"]["haptics"]), "haptic preference is retained")
    _check(sanitized["completed_chapters"] == [0, 2], "completed chapters are normalized")
    _check_save_recovery()

    var packed := load("res://main.tscn") as PackedScene
    _check(packed != null, "main scene loads")
    if packed == null:
        call_deferred("_finish")
        return

    var game := packed.instantiate()
    get_root().add_child(game)
    await process_frame
    await process_frame
    _check(bool(game.get_meta("boot_ok", false)), "main scene reports boot_ok")
    _check(_tree_contains_text(game, "RELIC WEAVER"), "home screen is visible")
    _check(_tree_contains_text(game, "Версия 1.1.1"), "home screen shows the current version")
    _check(game.current_bg.scale == Vector2.ONE, "pixel background remains at a stable scale")
    game.show_settings()
    await process_frame
    _check(_tree_contains_text(game, "Тактильный отклик"), "settings expose optional haptics")
    _check(_tree_contains_text(game, "Скорость боя по умолчанию"), "settings expose remembered battle speed")
    _check(_tree_contains_text(game, "RELIC WEAVER · версия 1.1.1"), "settings render the version without a placeholder")
    game.show_home()
    await process_frame

    game.save_data["tutorial_seen"] = false
    game._start_run(0)
    await process_frame
    game.show_prepare()
    await process_frame
    _check(_tree_contains_text(game, "ОБУЧЕНИЕ  •  1/5"), "five-step tutorial opens for a new player")
    game._dismiss_tutorial()
    await process_frame
    _check(game.board.size() == GameDataRef.BOARD_SIZE, "run creates a complete board")
    _check(_count_items(game.board) == 3, "run starts with three artifacts")
    _check(game.shop.size() == 3, "shop has three offers")
    _check(_tree_contains_text(game, "Следующий противник"), "workshop previews the next enemy")
    _check(_tree_contains_text(game, "Сборка героя"), "workshop exposes complete build stats")
    _check(_tree_contains_text(game, "Лавка артефактов"), "shop has a clear section title")
    _check(_tree_contains_text(game, "Связи читаются без цвета"), "link legend does not rely on color")

    var original_board: Array = game.board.duplicate(true)
    game.board = _accessibility_link_board()
    var pattern_names := _link_pattern_names(game._board_links())
    _check(pattern_names.has("thread"), "thread links have a dot marker")
    _check(pattern_names.has("steel"), "steel links have a diamond marker")
    _check(pattern_names.has("arcane"), "arcane links have a ring marker")
    _check(pattern_names.has("mechanism"), "mechanism links have a double-tick marker")
    game.board = original_board
    game.show_prepare()
    await process_frame

    var dismantle_index := _first_item_index(game.board)
    var dismantled_item: Dictionary = game.board[dismantle_index].duplicate(true)
    var scrap_before_dismantle: int = int(game.scrap)
    var expected_refund: int = int(game._dismantle_value(dismantled_item))
    game.selected_slot = dismantle_index
    game._dismantle_selected()
    await process_frame
    _check(game.board[dismantle_index] != null, "dismantle requires explicit confirmation")
    _check(_tree_contains_text(game, "Разобрать %s?" % GameDataRef.ITEMS[dismantled_item["id"]]["name"]), "dismantle confirmation names the item")
    game._confirm_dismantle(dismantle_index)
    await process_frame
    _check(game.board[dismantle_index] == null, "confirmed dismantle removes the item")
    _check(int(game.scrap) == scrap_before_dismantle + expected_refund, "confirmed dismantle grants the shown refund")
    game.board[dismantle_index] = dismantled_item
    game.scrap = scrap_before_dismantle
    game.show_prepare()
    await process_frame

    var moved_id := str(game.board[6]["id"])
    game._slot_dropped(6, 5)
    await process_frame
    _check(game.board[6] == null and str(game.board[5]["id"]) == moved_id, "board items support drag-and-drop")

    var shop_item: Dictionary = game.shop[0].duplicate(true)
    var scrap_before_shop_drag: int = int(game.scrap)
    game._shop_item_dropped(0, 0)
    await process_frame
    _check(game.board[0] != null and game.board[0]["id"] == shop_item["id"], "shop items can be dragged into a chosen empty slot")
    _check(game.scrap < scrap_before_shop_drag, "dragging from the shop charges the item cost")
    game.board[0] = null
    game.scrap = scrap_before_shop_drag

    var score_before_auto_arrange: float = float(game._build_score())
    game._auto_arrange_board()
    await process_frame
    _check(game._build_score() + 0.001 >= score_before_auto_arrange, "auto-arrange never weakens the build")

    game.save_data["settings"]["battle_speed"] = 2.0
    game.start_battle()
    await process_frame
    _check(game.battle_active, "battle starts")
    _check(game.battle_speed == 2.0, "battle remembers the preferred speed")
    _check(_tree_contains_text(game, "×2"), "battle speed button reflects the preference")
    game._toggle_battle_speed()
    _check(game.battle_speed == 1.0, "battle speed can still be changed during combat")
    _check(float(game.save_data["settings"]["battle_speed"]) == 1.0, "battle speed changes are persisted")
    game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
    _check(game.battle_paused, "battle pauses when the application loses focus")
    _check(_tree_contains_text(game, "после сворачивания"), "automatic pause explains why combat stopped")
    game._toggle_battle_pause()
    _check(not game.battle_paused, "a system-paused battle can be resumed")
    _check(game.enemy_hp > 0.0, "battle enemy has health")
    _check(game.link_pulse_charge > 0.0, "active link pulse starts partially charged")
    var hp_before_pulse: float = float(game.enemy_hp)
    game.hero_hp = maxf(1.0, game.hero_max_hp - 24.0)
    var hero_hp_before_pulse: float = float(game.hero_hp)
    game.link_pulse_charge = 100.0
    game._use_link_pulse()
    _check(game.enemy_hp < hp_before_pulse, "active link pulse damages the enemy")
    _check(game.hero_hp > hero_hp_before_pulse, "active link pulse heals the hero")
    _check(game.enemy_stun >= 0.8, "active link pulse interrupts the enemy")
    _check(game.link_pulse_charge == 0.0, "active link pulse consumes its charge")
    game._damage_enemy(game.enemy_hp + 1000.0, "release check")
    _check(not game.battle_active, "battle stops after victory")
    _check(game.enemy_hp == 0.0, "dead enemy health is clamped to zero")
    _check(game.enemy_hp_bar.value == 0.0, "dead enemy health bar is empty immediately")
    _check(game.enemy_hp_label.text.begins_with("0 /"), "dead enemy health label shows zero immediately")
    _check(game.stage_index == 1, "victory advances the run")
    _check(game.loot_choices.size() == 3, "victory creates three loot choices")
    _check(_unique_loot_count(game.loot_choices) == 3, "loot choices are unique")

    game._after_battle_continue()
    await process_frame
    _check(_tree_contains_text(game, "Награда за бой"), "loot screen is reachable")
    game._choose_loot(0)
    await process_frame
    _check(game.run_phase == "prepare", "loot returns to preparation")
    _check(_count_items(game.board) == 4, "chosen loot is added to the board")

    game.show_home()
    await process_frame
    _check(_tree_contains_text(game, "ПРОДОЛЖИТЬ"), "saved run is offered on the home screen")
    game._resume_run()
    await process_frame
    _check(game.stage_index == 1, "resume restores battle progress")
    _check(_count_items(game.board) == 4, "resume restores the board")

    game._start_run(3)
    await process_frame
    _check(_count_items(game.board) == 6, "late chapters grant a viable recovered loadout")
    _check(game.scrap >= 32, "late chapters grant additional workshop scrap")
    game.stage_index = 4
    game.start_battle()
    await process_frame
    _check(game.enemy_id == "first_weaver", "final boss encounter is reachable")
    game._damage_enemy(game.enemy_hp + 1000.0, "release final check")
    _check(game.run_phase == "complete", "final victory is persisted")
    game._after_battle_continue()
    await process_frame
    _check(3 in game.save_data["completed_chapters"], "final chapter completion is recorded")
    _check(game.save_data["active_run"].is_empty(), "completed run is cleared")

    game.free()
    for _frame in range(4):
        await process_frame
    # Let this coroutine return before quitting. Its local PackedScene and
    # instantiated scene references would otherwise still be alive while
    # Godot tears down the ResourceLoader cache, producing false leak noise.
    call_deferred("_finish")

func _check_catalog_resources() -> void:
    for id in GameDataRef.ITEMS:
        var item: Dictionary = GameDataRef.ITEMS[id]
        _check(ResourceLoader.exists(item["icon"]), "item asset exists: %s" % id)
    for enemy_id in GameDataRef.ENEMIES:
        var enemy: Dictionary = GameDataRef.ENEMIES[enemy_id]
        _check(ResourceLoader.exists(enemy["sprite"]), "enemy asset exists: %s" % enemy_id)
    for chapter in GameDataRef.CHAPTERS:
        _check(ResourceLoader.exists(chapter["background"]), "chapter background exists")
        _check(chapter["enemies"].size() == 5, "chapter contains five battles")
        for enemy_id in chapter["enemies"]:
            _check(GameDataRef.ENEMIES.has(enemy_id), "chapter enemy exists: %s" % enemy_id)

func _check_save_recovery() -> void:
    var first := SaveManagerRef.defaults()
    first["embers"] = 17
    _check(SaveManagerRef.save(first), "first atomic save succeeds")
    var second := first.duplicate(true)
    second["embers"] = 23
    _check(SaveManagerRef.save(second), "second atomic save succeeds")
    var backup = JSON.parse_string(FileAccess.get_file_as_string(SaveManagerRef.BACKUP_PATH))
    _check(backup is Dictionary and int(backup["embers"]) == 17, "previous valid save is kept as backup")
    var corrupt := FileAccess.open(SaveManagerRef.SAVE_PATH, FileAccess.WRITE)
    _check(corrupt != null, "primary save can be opened for recovery test")
    if corrupt != null:
        corrupt.store_string("{broken")
        corrupt.flush()
        corrupt = null
    var recovered := SaveManagerRef.load_save()
    _check(int(recovered["embers"]) == 17, "invalid primary save is recovered from backup")
    var repaired := SaveManagerRef.defaults()
    _check(SaveManagerRef.save(repaired), "recovered save can be replaced with a valid primary")

func _accessibility_link_board() -> Array:
    var result: Array = []
    result.resize(GameDataRef.BOARD_SIZE)
    result.fill(null)
    result[0] = {"id": "blade", "tier": 1}
    result[1] = {"id": "buckler", "tier": 1}
    result[3] = {"id": "sigil", "tier": 1}
    result[4] = {"id": "rune", "tier": 1}
    result[5] = {"id": "cog", "tier": 1}
    result[6] = {"id": "rune", "tier": 1}
    result[10] = {"id": "thread", "tier": 1}
    result[11] = {"id": "bell", "tier": 1}
    return result

func _link_pattern_names(links: Array) -> Array[String]:
    var result: Array[String] = []
    for link in links:
        var pattern := str(link.get("pattern", ""))
        if pattern not in result:
            result.append(pattern)
    return result

func _first_item_index(items: Array) -> int:
    for index in range(items.size()):
        if items[index] != null:
            return index
    return -1

func _tree_contains_text(node: Node, expected: String) -> bool:
    if node is Label and expected in node.text:
        return true
    if node is Button and expected in node.text:
        return true
    for child in node.get_children():
        if _tree_contains_text(child, expected):
            return true
    return false

func _count_items(items: Array) -> int:
    var count := 0
    for item in items:
        if item != null:
            count += 1
    return count

func _unique_loot_count(items: Array) -> int:
    var ids: Dictionary = {}
    for item in items:
        ids[item["id"]] = true
    return ids.size()

func _check(condition: bool, description: String) -> void:
    if condition:
        print("RW_CHECK_OK: %s" % description)
    else:
        failures.append(description)
        push_error("RW_CHECK_FAIL: %s" % description)

func _finish() -> void:
    if failures.is_empty():
        print("RELIC_WEAVER_RELEASE_CHECKS_OK")
        quit(0)
    else:
        push_error("Relic Weaver release checks failed: %s" % ", ".join(failures))
        quit(1)

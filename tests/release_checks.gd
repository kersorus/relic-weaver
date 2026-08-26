extends SceneTree

const GameDataRef = preload("res://src/game_data.gd")
const SaveManagerRef = preload("res://src/save_manager.gd")

var failures: Array[String] = []

func _init() -> void:
    call_deferred("_run_checks")

func _run_checks() -> void:
    _check(
        str(ProjectSettings.get_setting("application/config/version", "")) == "1.0.0",
        "project version is 1.0.0"
    )
    _check(
        FileAccess.get_file_as_string("res://VERSION").strip_edges() == "1.0.0",
        "VERSION file matches project metadata"
    )
    _check(GameDataRef.ITEMS.size() >= 12, "item catalog has at least 12 artifacts")
    _check(GameDataRef.CHAPTERS.size() >= 4, "campaign has four release chapters")
    _check(GameDataRef.tier_mult(4) > GameDataRef.tier_mult(3), "tier scaling increases")
    _check_catalog_resources()

    var sanitized := SaveManagerRef.sanitize({
        "embers": -500,
        "attack_knot": 999,
        "settings": {"sfx_volume": 7.0},
        "completed_chapters": [0, 0, 2, -1]
    })
    _check(int(sanitized["embers"]) == 0, "negative currency is rejected")
    _check(
        int(sanitized["attack_knot"]) == SaveManagerRef.MAX_UPGRADE_LEVEL,
        "upgrade level is capped"
    )
    _check(float(sanitized["settings"]["sfx_volume"]) == 1.0, "audio volume is clamped")
    _check(sanitized["completed_chapters"] == [0, 2], "completed chapters are normalized")

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

    game._start_run(0)
    await process_frame
    game.show_prepare()
    await process_frame
    _check(game.board.size() == GameDataRef.BOARD_SIZE, "run creates a complete board")
    _check(_count_items(game.board) == 3, "run starts with three artifacts")
    _check(game.shop.size() == 3, "shop has three offers")

    game.start_battle()
    await process_frame
    _check(game.battle_active, "battle starts")
    _check(game.enemy_hp > 0.0, "battle enemy has health")
    game._damage_enemy(game.enemy_hp + 1000.0, "release check")
    _check(not game.battle_active, "battle stops after victory")
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

    game.queue_free()
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

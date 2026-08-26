class_name SaveManager
extends RefCounted

const SAVE_PATH := "user://relic_weaver_save.json"

static func defaults() -> Dictionary:
    return {
        "embers": 0,
        "max_chapter": 0,
        "attack_knot": 0,
        "vital_knot": 0,
        "purse_knot": 0,
        "tutorial_seen": false,
        "runs": 0,
        "wins": 0
    }

static func load_save() -> Dictionary:
    var data := defaults()
    if not FileAccess.file_exists(SAVE_PATH):
        return data
    var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if f == null:
        return data
    var parsed = JSON.parse_string(f.get_as_text())
    if parsed is Dictionary:
        for key in data.keys():
            if parsed.has(key):
                data[key] = parsed[key]
    return data

static func save(data: Dictionary) -> void:
    var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if f != null:
        f.store_string(JSON.stringify(data, "  "))

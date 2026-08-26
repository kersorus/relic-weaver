class_name SaveManager
extends RefCounted

const SAVE_PATH := "user://relic_weaver_save.json"
const SAVE_VERSION := 2
const MAX_UPGRADE_LEVEL := 10

static func defaults() -> Dictionary:
    return {
        "save_version": SAVE_VERSION,
        "embers": 0,
        "max_chapter": 0,
        "attack_knot": 0,
        "vital_knot": 0,
        "purse_knot": 0,
        "tutorial_seen": false,
        "runs": 0,
        "wins": 0,
        "completed_chapters": [],
        "active_run": {},
        "settings": {
            "sfx_volume": 0.85,
            "reduced_motion": false,
            "screen_shake": true
        }
    }

static func load_save() -> Dictionary:
    if not FileAccess.file_exists(SAVE_PATH):
        return defaults()
    var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if f == null:
        push_warning("Relic Weaver: save file could not be opened; defaults loaded")
        return defaults()
    var parsed = JSON.parse_string(f.get_as_text())
    if not parsed is Dictionary:
        push_warning("Relic Weaver: invalid save JSON; defaults loaded")
        return defaults()
    return sanitize(parsed)

static func sanitize(raw_data: Variant) -> Dictionary:
    var data := defaults()
    if not raw_data is Dictionary:
        return data
    var raw: Dictionary = raw_data

    data["embers"] = clampi(_as_int(raw.get("embers", 0)), 0, 999999)
    data["max_chapter"] = clampi(_as_int(raw.get("max_chapter", 0)), 0, 99)
    data["attack_knot"] = clampi(_as_int(raw.get("attack_knot", 0)), 0, MAX_UPGRADE_LEVEL)
    data["vital_knot"] = clampi(_as_int(raw.get("vital_knot", 0)), 0, MAX_UPGRADE_LEVEL)
    data["purse_knot"] = clampi(_as_int(raw.get("purse_knot", 0)), 0, MAX_UPGRADE_LEVEL)
    data["tutorial_seen"] = bool(raw.get("tutorial_seen", false))
    data["runs"] = clampi(_as_int(raw.get("runs", 0)), 0, 999999)
    data["wins"] = clampi(_as_int(raw.get("wins", 0)), 0, 999999)

    var completed: Array = []
    var raw_completed = raw.get("completed_chapters", [])
    if raw_completed is Array:
        for value in raw_completed:
            var chapter := _as_int(value)
            if chapter >= 0 and chapter < 100 and chapter not in completed:
                completed.append(chapter)
    data["completed_chapters"] = completed

    var raw_run = raw.get("active_run", {})
    if raw_run is Dictionary:
        data["active_run"] = raw_run.duplicate(true)

    var settings: Dictionary = data["settings"]
    var raw_settings = raw.get("settings", {})
    if raw_settings is Dictionary:
        settings["sfx_volume"] = clampf(_as_float(raw_settings.get("sfx_volume", 0.85)), 0.0, 1.0)
        settings["reduced_motion"] = bool(raw_settings.get("reduced_motion", false))
        settings["screen_shake"] = bool(raw_settings.get("screen_shake", true))
    data["settings"] = settings
    return data

static func _as_int(value: Variant) -> int:
    if value is int or value is float:
        return int(value)
    return 0

static func _as_float(value: Variant) -> float:
    if value is int or value is float:
        return float(value)
    return 0.0

static func save(data: Dictionary) -> bool:
    var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if f == null:
        push_warning("Relic Weaver: save file could not be written")
        return false
    f.store_string(JSON.stringify(sanitize(data), "  "))
    f.flush()
    return true

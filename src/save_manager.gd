class_name SaveManager
extends RefCounted

const SAVE_PATH := "user://relic_weaver_save.json"
const BACKUP_PATH := "user://relic_weaver_save.backup.json"
const TEMP_PATH := "user://relic_weaver_save.tmp.json"
const SAVE_VERSION := 3
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
            "screen_shake": true,
            "battle_speed": 1.0,
            "haptics": true
        }
    }

static func load_save() -> Dictionary:
    var primary = _read_dictionary(SAVE_PATH)
    if primary is Dictionary:
        return sanitize(primary)
    var backup = _read_dictionary(BACKUP_PATH)
    if backup is Dictionary:
        push_warning("Relic Weaver: primary save is unavailable; backup restored")
        return sanitize(backup)
    if FileAccess.file_exists(SAVE_PATH) or FileAccess.file_exists(BACKUP_PATH):
        push_warning("Relic Weaver: save files are invalid; defaults loaded")
    return defaults()

static func _read_dictionary(path: String) -> Variant:
    if not FileAccess.file_exists(path):
        return null
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return null
    var json := JSON.new()
    if json.parse(file.get_as_text()) != OK:
        return null
    var parsed = json.data
    return parsed if parsed is Dictionary else null

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
        settings["battle_speed"] = 2.0 if _as_float(raw_settings.get("battle_speed", 1.0)) >= 1.5 else 1.0
        settings["haptics"] = bool(raw_settings.get("haptics", true))
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
    var serialized := JSON.stringify(sanitize(data), "  ")
    if not _write_text(TEMP_PATH, serialized):
        push_warning("Relic Weaver: temporary save file could not be written")
        return false
    if not _read_dictionary(TEMP_PATH) is Dictionary:
        push_warning("Relic Weaver: temporary save verification failed")
        return false

    var current = _read_dictionary(SAVE_PATH)
    if current is Dictionary:
        var current_text := FileAccess.get_file_as_string(SAVE_PATH)
        if not _write_text(BACKUP_PATH, current_text):
            push_warning("Relic Weaver: backup save could not be written")
            return false

    var primary_absolute := ProjectSettings.globalize_path(SAVE_PATH)
    var temporary_absolute := ProjectSettings.globalize_path(TEMP_PATH)
    if FileAccess.file_exists(SAVE_PATH):
        var remove_error := DirAccess.remove_absolute(primary_absolute)
        if remove_error != OK:
            push_warning("Relic Weaver: old save could not be replaced")
            return false
    var rename_error := DirAccess.rename_absolute(temporary_absolute, primary_absolute)
    if rename_error != OK:
        push_warning("Relic Weaver: atomic save replacement failed; backup retained")
        return false
    return true

static func _write_text(path: String, text: String) -> bool:
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(text)
    file.flush()
    return file.get_error() == OK

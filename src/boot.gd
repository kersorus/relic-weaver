extends Control

@onready var boot_layer: Control = $BootLayer
@onready var status_label: Label = $BootLayer/Center/Panel/Margin/VBox/Status
@onready var details_label: Label = $BootLayer/Center/Panel/Margin/VBox/Details

func _ready() -> void:
    print("RW_BOOT: boot scene alive")
    status_label.text = "Запуск мастерской…"
    details_label.text = "Загружаю игровой интерфейс"
    call_deferred("_start_game")

func _start_game() -> void:
    print("RW_BOOT: loading main.tscn")
    status_label.text = "Загрузка сцены…"

    var packed := load("res://main.tscn") as PackedScene
    if packed == null:
        _fail("Не удалось загрузить main.tscn", "Проверь лог Godot/Actions: основной ресурс сцены не загрузился.")
        return

    print("RW_BOOT: instantiating main scene")
    var game := packed.instantiate()
    if game == null:
        _fail("Не удалось создать игровую сцену", "main.tscn найден, но instantiate() вернул null.")
        return

    if game is Control:
        var game_control := game as Control
        game_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    add_child(game)
    move_child(boot_layer, get_child_count() - 1)
    status_label.text = "Инициализация интерфейса…"
    details_label.text = "Проверяю, что главный экран действительно создан"

    # Give the main script several frames for _ready() and deferred layout work.
    for _i in range(4):
        await get_tree().process_frame

    if not is_instance_valid(game):
        _fail("Игровая сцена закрылась при запуске", "Смотри runtime smoke-test в GitHub Actions.")
        return

    if bool(game.get_meta("boot_ok", false)):
        print("RW_BOOT: game reported boot_ok")
        boot_layer.visible = false
        return

    _fail(
        "Основной скрипт не завершил запуск",
        "Сцена загрузилась, но main.gd не дошёл до домашнего экрана. GitHub Actions теперь покажет runtime-ошибку."
    )

func _fail(title: String, details: String) -> void:
    push_error("RW_BOOT_FAIL: %s — %s" % [title, details])
    status_label.text = title
    details_label.text = details

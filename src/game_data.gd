class_name GameData
extends RefCounted

const MAX_TIER := 4
const BOARD_COLS := 5
const BOARD_ROWS := 4
const BOARD_SIZE := BOARD_COLS * BOARD_ROWS

const ITEMS := {
    "blade": {
        "name": "Клинок сторожа", "kind": "Оружие", "icon": "res://assets/items/blade.png",
        "desc": "+атака. Каждые несколько ударов наносит рубящий бонус.",
        "base_cost": 6, "weight": 14, "tags": ["steel", "strike"]
    },
    "buckler": {
        "name": "Круглый щит", "kind": "Защита", "icon": "res://assets/items/buckler.png",
        "desc": "+здоровье и броня. Лучше работает рядом с металлом.",
        "base_cost": 6, "weight": 13, "tags": ["steel", "guard"]
    },
    "sigil": {
        "name": "Знак разрыва", "kind": "Магия", "icon": "res://assets/items/sigil.png",
        "desc": "Периодически бьёт чистой магией. Усиливается нитями.",
        "base_cost": 7, "weight": 12, "tags": ["arcane", "pulse"]
    },
    "boot": {
        "name": "Сапог гонца", "kind": "Скорость", "icon": "res://assets/items/boot.png",
        "desc": "+скорость атаки и небольшой шанс уклонения.",
        "base_cost": 6, "weight": 11, "tags": ["motion"]
    },
    "charm": {
        "name": "Красный оберег", "kind": "Жизнь", "icon": "res://assets/items/charm.png",
        "desc": "Даёт вампиризм. На высоких уровнях лечит после тяжёлого удара.",
        "base_cost": 8, "weight": 10, "tags": ["blood", "arcane"]
    },
    "cog": {
        "name": "Часовая шестерня", "kind": "Механизм", "icon": "res://assets/items/cog.png",
        "desc": "+скорость и критический шанс. Любит соседство с рунами.",
        "base_cost": 8, "weight": 10, "tags": ["clock", "motion"]
    },
    "lantern": {
        "name": "Тихий фонарь", "kind": "Поддержка", "icon": "res://assets/items/lantern.png",
        "desc": "Медленно восстанавливает здоровье в бою.",
        "base_cost": 7, "weight": 9, "tags": ["light", "guard"]
    },
    "thread": {
        "name": "Связующая нить", "kind": "Связь", "icon": "res://assets/items/thread.png",
        "desc": "Главный синергетик: усиливает соседние предметы и получает силу от соседей.",
        "base_cost": 8, "weight": 12, "tags": ["link", "arcane"]
    },
    "rune": {
        "name": "Руна отражения", "kind": "Руна", "icon": "res://assets/items/rune.png",
        "desc": "+крит. Рядом с магией добавляет магический урон к атакам.",
        "base_cost": 9, "weight": 8, "tags": ["rune", "arcane"]
    },
    "bell": {
        "name": "Погребальный колокол", "kind": "Контроль", "icon": "res://assets/items/bell.png",
        "desc": "Иногда оглушает врага и наносит удар по стойкости.",
        "base_cost": 9, "weight": 8, "tags": ["sound", "guard"]
    },
    "mirror": {
        "name": "Дорожное зеркало", "kind": "Защита", "icon": "res://assets/items/mirror.png",
        "desc": "+уклонение. После уклонения следующий удар героя сильнее.",
        "base_cost": 10, "weight": 7, "tags": ["light", "motion"]
    },
    "spindle": {
        "name": "Веретено узлов", "kind": "Реликвия", "icon": "res://assets/items/spindle.png",
        "desc": "Гибрид атаки и здоровья. За каждую соседнюю нить получает дополнительную силу.",
        "base_cost": 11, "weight": 6, "tags": ["link", "blood", "relic"]
    }
}

const CHAPTERS := [
    {
        "name": "I. Под старой церковью",
        "short": "Старая церковь",
        "background": "res://assets/backgrounds/chapel.png",
        "intro": "Отец говорил, что колокол нельзя трогать после заката. После его смерти под церковью впервые за несколько веков ответило что-то другое.",
        "outro": "Каменная дверь открылась не наружу, а будто в память. Из темноты потянулась тонкая светящаяся связь — и выбрала тебя.",
        "enemies": ["grave_rat", "grave_rat", "chapel_shade", "old_warden", "bound_mage"]
    },
    {
        "name": "II. Дорога, которой не было",
        "short": "Имперская дорога",
        "background": "res://assets/backgrounds/road.png",
        "intro": "До столицы семь дней пути. Но после пробуждения дороги стали вести себя странно: знакомые мосты повторялись, а чужие люди называли тебя по имени.",
        "outro": "У ворот столицы стражник протянул пропуск, выписанный вчера твоим почерком. Ты никогда прежде не видел этот город.",
        "enemies": ["road_guard", "grave_rat", "road_guard", "chapel_shade", "old_warden"]
    },
    {
        "name": "III. Архив часовой башни",
        "short": "Городской архив",
        "background": "res://assets/backgrounds/archive.png",
        "intro": "В архиве нет книги о древнем маге. Зато есть книги, в которых вычеркнуты ровно те страницы, что должны были о нём рассказать.",
        "outro": "В полночь часы пошли назад. На последней чистой странице проступила фраза: «Связь не передаёт силу. Она решает, где сила уже была».",
        "enemies": ["ink_scribe", "clock_husk", "ink_scribe", "old_warden", "bound_mage"]
    }
]

const ENEMIES := {
    "grave_rat": {"name":"Могильная крыса", "sprite":"res://assets/actors/grave_rat.png", "hp":78.0, "atk":9.0, "speed":1.18, "reward":6, "trait":"Грызёт быстро"},
    "chapel_shade": {"name":"Тень прихожанина", "sprite":"res://assets/actors/chapel_shade.png", "hp":118.0, "atk":13.0, "speed":0.88, "reward":8, "trait":"Каждый третий удар сильнее"},
    "road_guard": {"name":"Сломанный дозорный", "sprite":"res://assets/actors/road_guard.png", "hp":146.0, "atk":14.0, "speed":0.80, "reward":9, "trait":"Высокая защита"},
    "ink_scribe": {"name":"Чернильный писец", "sprite":"res://assets/actors/ink_scribe.png", "hp":132.0, "atk":17.0, "speed":0.90, "reward":10, "trait":"Порча: усиливается со временем"},
    "old_warden": {"name":"Последний сторож", "sprite":"res://assets/actors/old_warden.png", "hp":220.0, "atk":20.0, "speed":0.76, "reward":13, "trait":"Блокирует часть ударов"},
    "clock_husk": {"name":"Пустой часовой", "sprite":"res://assets/actors/clock_husk.png", "hp":184.0, "atk":18.0, "speed":1.02, "reward":12, "trait":"Ускоряется при низком здоровье"},
    "bound_mage": {"name":"Связанный маг", "sprite":"res://assets/actors/bound_mage.png", "hp":300.0, "atk":24.0, "speed":0.84, "reward":18, "trait":"Босс: импульс связи"}
}

static func tier_name(tier: int) -> String:
    return ["", "Обычный", "Сшитый", "Редкий", "Реликтовый"][clampi(tier, 1, MAX_TIER)]

static func tier_mult(tier: int) -> float:
    return [0.0, 1.0, 1.85, 3.15, 5.0][clampi(tier, 1, MAX_TIER)]

static func item_cost(id: String, tier: int = 1) -> int:
    return int(ITEMS[id]["base_cost"] * (1.0 + 0.6 * (tier - 1)))

static func chapter_scale(chapter: int, stage: int) -> float:
    return 1.0 + chapter * 0.42 + stage * 0.11

# Relic Weaver — Узлы старого мира

Полностью офлайн vertical-slice merge / backpack / auto-battler RPG на Godot 4.

Игра использует жанровую петлю «собери билд → слей дубликаты → автобой», но не копирует персонажей, интерфейс, экономику или контент Overgeared Hero. Главная механика — **связи соседства**: положение артефактов на поле меняет их эффективность, а `Связующая нить` усиливает окружающие предметы.

Текущая версия проекта: **0.3.0**.

## Что уже работает

- 3 сюжетные главы по 5 боёв;
- 7 типов противников и боссы;
- 12 оригинальных предметов;
- сетка мастерской 5×4;
- покупка предметов, перестановка тапами, swap и merge T1→T4;
- синергии соседства и отдельные эффекты предметов;
- автобой: атака, крит, броня, уклонение, вампиризм, регенерация, магические импульсы, оглушение;
- визуальный animation pass боя: idle-breathing, выпад при атаке, hit flash/shake, dodge и death-анимация;
- всплывающие числа урона/лечения и отдельные эффекты сигила/колокола;
- переключатель скорости боя ×1 / ×2;
- короткий визуальный burst при merge предметов;
- после победы игрок **выбирает 1 из 3 наград**, вместо автоматического случайного предмета;
- если сетка заполнена, выбранную награду можно автоматически конвертировать в детали;
- 3 постоянных улучшения за обычную игровую валюту;
- локальный save в `user://relic_weaver_save.json`;
- полностью офлайн, без рекламы, серверов, аккаунтов и SDK аналитики;
- portrait UI под 720×1280, мышь и touch;
- пиксельные ассеты: 12 предметов, 8 персонажей и 12 props/UI-иконок;
- исходные generated sheets лежат в `assets/source_art/` и исключены из импорта Godot через `.gdignore`;
- GitHub Actions собирает Android APK, Linux x86_64 и Windows x86_64.

## Управление

В мастерской:

1. Купи предмет внизу экрана.
2. Тапни предмет на сетке.
3. Тапни другую клетку:
   - пустая клетка — перенос;
   - другой предмет — обмен местами;
   - такой же предмет того же T-уровня — merge.
4. Нажми **В БОЙ**.

В бою герой сражается автоматически. Кнопка `×1/×2` меняет скорость симуляции.

После победы выбери одну из трёх предложенных наград или забери дополнительные детали.

## Запуск проекта

Нужен Godot 4.3+.

```bash
godot --editor project.godot
```

Либо открыть `project.godot` в редакторе Godot и нажать **Run Project**.

## Локальная сборка

В репозитории есть `export_presets.cfg`.

Если установлен Godot 4.3 с export templates:

```bash
mkdir -p build/android build/linux build/windows

godot --headless --path . --export-debug "Android" build/android/RelicWeaver-debug.apk
godot --headless --path . --export-release "Linux/X11" build/linux/RelicWeaver.x86_64
godot --headless --path . --export-release "Windows Desktop" build/windows/RelicWeaver.exe
```

Android-пресет не запрашивает INTERNET permission (`permissions/internet=false`). CI собирает **debug APK**, чтобы его можно было скачать из Actions и установить без release-keystore.

## GitHub Actions

Workflow: `.github/workflows/build.yml`.

Запускается:

- при push в `main`;
- при pull request;
- вручную через **Actions → Build Relic Weaver → Run workflow**;
- при push тега `v*`.

CI сначала запускает headless import/validation Godot, а затем экспортирует:

- Android debug APK;
- Linux x86_64;
- Windows x86_64;
- `SHA256SUMS.txt` для собранных файлов.

Artifacts хранятся 14 дней. Повторный push в ту же ветку отменяет старую незавершённую сборку. Импортированные Godot-ресурсы кешируются между CI-run'ами.

Если запушить тег вроде `v0.3.0`, workflow дополнительно создаст GitHub Release и приложит к нему бинарники и checksums.

## Обновление уже существующего GitHub-репозитория из Termux

**Новый репозиторий создавать не нужно.** Архив новой версии можно развернуть поверх уже существующего локального checkout.

Пример: архив лежит в `Downloads`, а существующий репозиторий — `~/relic-weaver`.

```bash
pkg install git unzip
termux-setup-storage

cd ~/relic-weaver

git status
git pull --rebase

unzip -o ~/storage/downloads/relic_weaver_v0.3_update.zip -d .
rm -f test_write

git status
git add -A
git commit -m "Update Relic Weaver to v0.3"
git push origin main
```

`unzip` не трогает каталог `.git`, поэтому remote, история и настройки существующего репозитория сохраняются.

После `git push origin main` GitHub Actions запустится автоматически.

Чтобы затем создать релиз:

```bash
git tag v0.3.0
git push origin v0.3.0
```

Если в локальном репозитории есть незакоммиченные изменения, сначала сохрани их commit'ом или через `git stash`.

## Архитектура

- `src/main.gd` — UI, run state, магазин, merge, расчёт билда, бой, battle VFX и выбор награды;
- `src/game_data.gd` — предметы, главы, противники и формулы tiers;
- `src/save_manager.gd` — локальное JSON-сохранение;
- `assets/items/` — 12 пиксельных иконок предметов;
- `assets/actors/` — 8 пиксельных персонажей;
- `assets/props/` — декоративные props и UI-иконки;
- `assets/source_art/` — исходные generated sheets, не попадающие в импорт Godot;
- `assets/backgrounds/` — фоны трёх глав;
- `assets/audio/` — короткие SFX;
- `export_presets.cfg` — Android/Linux/Windows export presets;
- `.github/workflows/build.yml` — CI-сборка, cache, artifacts и tagged releases.

## Что логично делать следующим

1. Настоящие frame-by-frame sprite sheets для hero/enemies вместо только tween-анимаций.
2. Несимметричные предметы 1×2 / 2×2 и вращение.
3. Подсветка активных связей прямо между клетками мастерской.
4. Элиты с модификаторами и выбором риска/награды.
5. Активные «жесты связи» между боями.
6. Ещё герои с разными правилами мастерской, а не просто разными статами.
7. Seeded runs и локальные испытания дня без подключения к сети.
8. Музыка и расширенный набор SFX.

## Проверка

В workflow есть реальная проверка проекта через:

```bash
godot --headless --editor --path . --quit
```

Если GDScript или импорт ресурсов сломан, CI остановится до экспорта artifacts.

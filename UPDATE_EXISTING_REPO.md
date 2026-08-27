# Обновление существующего репозитория из Termux

Архив `relic_weaver_v1.0.1_update.zip` содержит файлы проекта **без `.git`** и предназначен для распаковки поверх уже существующего checkout.

```bash
cd ~/relic-weaver

git status
git pull --rebase

unzip -o ~/storage/downloads/relic_weaver_v1.0.1_update.zip -d .
rm -f test_write

git status
git add -A
git commit -m "Release Relic Weaver v1.0.1"
git push origin main
```

После push сборка запустится во вкладке GitHub Actions.

Для release:

```bash
git tag v1.0.1
git push origin v1.0.1
```

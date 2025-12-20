# DiabolicUI3 - Development Guide

Руководство по разработке для DiabolicUI3.

## Структура проекта

```
X:\Games\World of Warcraft\
├── diabolic-dev\                           ← РАБОЧАЯ ПАПКА (git репозиторий)
│   ├── .git\                              ← Git репозиторий
│   ├── .github\workflows\                 ← GitHub Actions
│   ├── TODO.md                            ← Список задач (не коммитится)
│   ├── DEVELOPMENT.md                     ← Этот файл
│   └── ...все исходные файлы
│
└── _retail_\Interface\AddOns\
    └── DiabolicUI3\                       ← ИГРОВАЯ ПАПКА (устанавливает CurseForge)
        └── ...файлы из релиза
```

## Важно! CurseForge клиент перезаписывает папку

⚠️ **НИКОГДА не работай напрямую в `_retail_\Interface\AddOns\DiabolicUI3\`!**

CurseForge клиент при обновлении аддона:
- Полностью удаляет папку DiabolicUI3
- Распаковывает новый архив
- Теряется .git репозиторий и все файлы из .gitignore

## Workflow разработки

### 1. Разработка

Работай в папке `diabolic-dev\`:

```bash
cd "X:\Games\World of Warcraft\diabolic-dev"
```

Все изменения делай здесь. Git репозиторий сохранён и защищён от CurseForge.

### 2. Тестирование в игре

Скопируй изменения в игровую папку для тестов:

```bash
robocopy "X:\Games\World of Warcraft\diabolic-dev" "X:\Games\World of Warcraft\_retail_\Interface\AddOns\DiabolicUI3" /MIR /XD .git .github /XF .gitignore .pkgmeta TODO.md RELEASE_NOTES*.md CHANGELOG_RELEASE.md CHANGES.txt DEVELOPMENT.md
```

Параметры:
- `/MIR` - зеркалирование (полная копия)
- `/XD .git .github` - исключить папки .git и .github
- `/XF` - исключить файлы для разработки

Или упрощённая версия (только изменённые файлы):

```bash
robocopy "X:\Games\World of Warcraft\diabolic-dev" "X:\Games\World of Warcraft\_retail_\Interface\AddOns\DiabolicUI3" /E /XD .git .github /XF .gitignore .pkgmeta TODO.md RELEASE_NOTES*.md DEVELOPMENT.md
```

### 3. Коммит изменений

⚠️ **ВАЖНО: Push на GitHub делай ТОЛЬКО по просьбе пользователя!**

Локальные коммиты можно и нужно делать свободно:

```bash
cd "X:\Games\World of Warcraft\diabolic-dev"
git add .
git commit -m "Описание изменений"
# Push делаем ТОЛЬКО когда пользователь попросит!
```

Push на GitHub (ТОЛЬКО по просьбе пользователя):

```bash
git push origin github
```

### 4. Создание релиза

⚠️ **ТОЛЬКО по просьбе пользователя!**

```bash
cd "X:\Games\World of Warcraft\diabolic-dev"
git tag -a release-X.X.X -m "Описание релиза"
git push origin release-X.X.X
```

GitHub Actions автоматически:
1. Создаст архив DiabolicUI3.zip
2. Опубликует релиз на GitHub
3. CurseForge синхронизируется (5-15 минут)

### 5. Обновление CHANGELOG

Перед каждым релизом обнови `CHANGELOG.md`:

```markdown
## [X.X.X] - 2025-01-XX
### Added
- Новая функция

### Fixed
- Исправлен баг
```

CurseForge использует CHANGELOG.md для создания CHANGES.txt.

## Файлы в .gitignore

Эти файлы НЕ коммитятся, но используются локально:

- `TODO.md` - список задач для разработки
- `RELEASE_NOTES*.md` - заметки к релизам
- `CURSE_DESCRIPTION.html` - описание для CurseForge
- `CHANGELOG_RELEASE.md` - черновики changelog
- `CHANGES.txt` - генерируется CurseForge автоматически
- `DiabolicUI3.rar` - локальные архивы

## Восстановление после потери репозитория

Если случайно работал в `_retail_\Interface\AddOns\DiabolicUI3\` и CurseForge перезаписал:

```bash
cd "X:\Games\World of Warcraft"
git clone https://github.com/Arahort/diabolic.git diabolic-dev
cd diabolic-dev
git checkout github
```

Всё восстановлено! Продолжай работу в `diabolic-dev\`.

## Полезные команды

### Проверка статуса
```bash
cd "X:\Games\World of Warcraft\diabolic-dev"
git status
```

### Просмотр изменений
```bash
git diff
```

### Просмотр истории
```bash
git log --oneline -10
```

### Проверка тегов
```bash
git tag -l "release-*"
```

### Откат изменений
```bash
git restore .
```

## GitHub Actions

Workflow в `.github/workflows/release.yml` автоматически создаёт релизы:

- Триггер: push тега `release-*`
- Создаёт архив DiabolicUI3.zip
- Публикует релиз на GitHub
- Исключает файлы из .pkgmeta ignore

## CurseForge упаковка

Файл `.pkgmeta` контролирует упаковку на CurseForge:

```yaml
package-as: DiabolicUI3
manual-changelog: CHANGELOG.md
enable-nolib-creation: no

ignore:
  - TODO.md
  - .github
  - .gitignore
  ...
```

## Советы

1. ✅ Всегда работай в `diabolic-dev\`
2. ✅ Локальные коммиты делай часто, маленькими порциями
3. ✅ Push на GitHub делай ТОЛЬКО по просьбе пользователя
4. ✅ Обновляй CHANGELOG.md перед релизом
5. ✅ Тестируй в игре перед push
6. ✅ Жди 10-15 минут после push тега для синхронизации CurseForge
7. ❌ Не работай в `_retail_\Interface\AddOns\DiabolicUI3\`
8. ❌ Не удаляй и не пересоздавай теги без необходимости
9. ❌ Не делай push без разрешения пользователя

## Контакты

- GitHub: https://github.com/Arahort/diabolic
- CurseForge: https://www.curseforge.com/wow/addons/diabolicui-arahort-edition
- Автор: Arahort (alex@arahort.pro)

# 🏋️ Fittnes — Персональный тренер по силовым тренировкам

Профессиональное мобильное приложение для силовых тренировок в зале:
дневник тренировок, база упражнений с техникой, умные рекомендации весов,
графики прогресса и модель восстановления мышц.

Уровень продукта — Strong / Hevy / Fitbod, с более научным подходом к силе.

## Стек

| Слой | Технология |
|------|-----------|
| Framework | Flutter 3.19+ / Dart 3 |
| State / DI | Riverpod 2 (codegen) |
| Навигация | go_router (StatefulShellRoute) |
| Каталог упражнений | Bundled JSON → индексированный in-memory репозиторий |
| БД (local-first) | Drift / SQLite для логов тренировок *(Модуль 2)* |
| Графики | fl_chart *(Модуль 3)* |
| Анимации | flutter_animate + Hero |
| Анатомия | flutter_svg (слоистая подсветка мышц) |

Архитектура: **Clean Architecture + Feature-First** (`presentation → domain ← data`),
Repository Pattern, SOLID, MVVM через Riverpod-нотифаеры. Local-first, офлайн;
облачная синхронизация — отдельный модуль.

## Структура

```
lib/
├─ main.dart              # entry point (edge-to-edge, ProviderScope)
├─ app/                   # MaterialApp, роутер, DI
│  └─ router/             # go_router + glass bottom-nav shell
├─ core/                  # дизайн-система и переиспользуемое
│  ├─ theme/              # токены, glassmorphism (ThemeExtension), Material 3
│  └─ widgets/            # GlassCard, PrimaryButton, StatTile, ...
└─ features/              # home · exercises · progress · profile · ...
   └─ <feature>/          # data / domain / presentation
```

## Запуск

Проект собран как исходники модулей. Перед первым запуском создайте
платформенные папки и подтяните зависимости:

```bash
flutter create . --project-name fittnes --platforms=android,ios
flutter pub get
flutter run
```

Тесты и анализ:

```bash
flutter analyze
flutter test
```

> Кодогенерация (Riverpod/Drift/freezed) подключается с Модуля 1:
> `dart run build_runner build --delete-conflicting-outputs`.

## Дорожная карта (модулями)

- [x] **Модуль 0 — Фундамент**: дизайн-система, glass-тема, core-виджеты,
      навигация (bottom-nav shell), главный экран-витрина.
- [x] **Модуль 1 — База упражнений**: доменные сущности, in-memory репозиторий,
      сид-каталог (JSON), живой поиск + фасеты (мышца/оборудование/уровень),
      экран техники (зацикленная анимация) + векторная подсветка мышц (`MuscleMap`).
- [x] **Модуль 2A — Движок тренировки**: доменные модели (сессия/подход/PR),
      e1RM (Epley), контроллер активной сессии, экран логирования подходов
      (вес/повторы/RPE/RIR, типы подходов, суперсеты), авто-таймер отдыха,
      подсказки прошлой тренировки и рекомендованный вес, PR — на in-memory
      репозитории за интерфейсом `WorkoutRepository`.
- [ ] **Модуль 2B — Персистентность**: Drift/SQLite за тем же интерфейсом +
      экран истории тренировок.
- [ ] **Модуль 3 — Прогресс + Рекомендации**: движок e1RM, автопрогрессия,
      графики силы/тоннажа/PR.
- [ ] **Модуль 4 — Программы, Профиль, Recovery**: готовые/пользовательские
      программы, замеры, темы, модель усталости мышц.
- [ ] **Модуль 5 — Синхронизация, экспорт, уведомления, виджеты**.

## Данные упражнений

Каталог грузится из `assets/exercises/exercises_seed.json` в индексированный
in-memory репозиторий (справочные данные только для чтения — БД не нужна).
Схема JSON совместима с [free-exercise-db](https://github.com/yuhonas/free-exercise-db)
(MIT, ~800 упражнений): чтобы расширить базу до 500+, достаточно
сконвертировать датасет в этот формат и заменить asset — код менять не нужно
(`ExerciseDto`/`Muscle.fromDataset` уже понимают эти поля).

## Дизайн-система (кратко)

- Тёмная тема, glassmorphism, Material 3, плавные анимации.
- Бренд: фиолетовый градиент `#6C5CE7 → #8B7CF6`, акцент — мятный `#00E5A0`.
- Скругления 24/16/12, 4-pt отступы, tabular-figures для цифр.
- Все токены — в `lib/core/theme/`, стекло — через `AppGlassTheme` (ThemeExtension).

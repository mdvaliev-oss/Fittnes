# CLAUDE.md — контекст проекта Fittnes

Файл для Claude Code: держит решения, договорённости и состояние проекта, чтобы
новая сессия сразу была продуктивной. Обновляй его при значимых изменениях.

## Что это

**Fittnes** — мобильное приложение «Персональный тренер по силовым тренировкам»
(Flutter, Android/iOS). Уровень продукта — Strong / Hevy / Fitbod, но с более
научным подходом к силе. Весь UI и контент — **на русском языке**.

- Репозиторий: `mdvaliev-oss/fittnes`
- Рабочая ветка: `claude/session-tdabmo` (PR не создавался; пушим сюда)
- Язык кода/комментариев: английский; UI-строки — русский.

## Технологии

| Слой | Выбор |
|------|-------|
| Framework | Flutter 3.44 / Dart 3 (тестировалось на 3.44.7) |
| State/DI | Riverpod 2 — **провайдеры пишем вручную, без riverpod codegen** |
| Навигация | go_router (StatefulShellRoute для bottom-nav) |
| БД (логи тренировок) | Drift / SQLite — **нужен build_runner (codegen)** |
| Профиль/настройки/свои программы | shared_preferences (JSON) |
| Каталог упражнений | bundled JSON → in-memory репозиторий (read-only, без БД) |
| Графики | fl_chart |
| Напоминания | flutter_local_notifications + timezone |
| Прочее | flutter_svg, google_fonts (Inter); анимации — свои виджеты в `core/widgets` |

## Архитектура и конвенции

- **Clean Architecture + Feature-First**: `features/<name>/{data,domain,presentation}`.
  Правило зависимостей: `presentation → domain ← data`.
- **Domain — чистый Dart** (без Flutter/Drift/JSON). Сущности иммутабельные, с
  `copyWith` и (где нужно для экспорта) `toJson`/`fromJson`.
- **Repository Pattern + SOLID + MVVM** через Riverpod-нотифаеры.
- **Local-first**, облака нет (пользователь выбрал local-only в самом начале).
- Линт строгий (`analysis_options.yaml`): включён `require_trailing_commas`.
  После правок всегда: `dart format lib test && dart fix --apply`, затем
  `flutter analyze` (цель — **No issues found**).
- Цвета: используем `Color.withValues(alpha:)` (Flutter 3.44+), не `withOpacity`.

## Структура

```
lib/
├─ app/            # MaterialApp, router (go_router + glass bottom-nav), DI
├─ core/
│  ├─ theme/       # дизайн-токены, AppGlassTheme (ThemeExtension → context.glass)
│  ├─ database/    # Drift AppDatabase (app_database.dart, part *.g.dart)
│  ├─ settings/    # AppSettings (тема/единицы/напоминания) в SharedPreferences
│  ├─ backup/      # BackupService (экспорт/импорт всех данных в JSON)
│  ├─ reminders/   # ReminderService (flutter_local_notifications, guard'ы)
│  ├─ utils/       # OneRepMax (Epley), formatClock
│  └─ widgets/     # GlassCard, PrimaryButton, StatTile, AmbientBackground, ...
└─ features/
   ├─ home/        # дашборд: hero-карточка, живые метрики, входы в разделы
   ├─ exercises/   # каталог, поиск/фильтры, экран техники + MuscleMap (CustomPainter)
   ├─ workout/     # активная сессия (ActiveWorkoutController), таймер, Drift-репо, история
   ├─ programs/    # пресеты + пользовательские программы + конструктор
   ├─ progress/    # графики силы/тоннажа + личные рекорды (fl_chart)
   ├─ recovery/    # модель усталости мышц → heat-карта (MuscleBodyMap)
   ├─ recommendations/  # ProgressionEngine (двойная прогрессия × RPE/RIR)
   ├─ bodyweight/  # вес тела: ввод кг/lb, история, график (Drift body_weights)
   └─ profile/     # профиль, настройки (единицы, таймер отдыха), экспорт/импорт
```

## Дизайн-система

Тёмная тема, glassmorphism, Material 3, плавные анимации.
- Бренд-градиент фиолетовый `#6C5CE7 → #8B7CF6`, акцент мятный `#00E5A0`,
  warning `#FFB020`, danger `#FF5C5C`.
- Токены — в `lib/core/theme/`; стекло через `AppGlassTheme` (`context.glass`).
- Скругления 24/16/12, 4-pt отступы, tabular-figures для цифр.

## Ключевые решения (зафиксированы с пользователем)

1. **Техника упражнений**: зацикленная GIF/WebP + векторная подсветка мышц.
   Пока реализовано: `TechniqueViewer` (анимированный плейсхолдер до реального
   медиа — подставляется через `Exercise.mediaUrl`) и `MuscleMap`/`MuscleBodyMap`
   (CustomPainter, спереди/сзади). 3D — отложено.
2. **Каталог упражнений**: открытый датасет (схема совместима с
   `free-exercise-db`, MIT) + своё поле `pattern`. Сейчас
   `assets/exercises/exercises_seed.json` — 131 курируемое упражнение на русском;
   тест `seed_integrity_test` требует ≥120 записей, описание ≥80 символов,
   явный `pattern`, уровень/оборудование без фолбэков.
3. **Бэкенд**: local-only. Drift для тренировок, SharedPreferences для остального.
4. **БД-соединение**: `lib/core/database/app_database.dart` использует
   `NativeDatabase` (dart:io) — это для мобильных. **Web не является целью**;
   для web-превью использовался conditional-import слой (native/web wasm),
   который НЕ коммитится (см. ниже).

## Статус модулей — ВСЕ ГОТОВЫ

- [x] 0 — Фундамент (дизайн-система, навигация)
- [x] 1 — База упражнений (каталог, техника, MuscleMap)
- [x] 2A — Движок тренировки (подходы/RPE/RIR/типы/суперсеты, авто-таймер)
- [x] 2B — Персистентность на Drift + экран истории + живые метрики
- [x] 3 — Прогресс (fl_chart) + ProgressionEngine (умные рекомендации)
- [x] 4A — Программы (пресеты) + Профиль + Настройки (реальная смена темы)
- [x] 4B — Recovery (усталость мышц, heat-карта)
- [x] 4C — Конструктор пользовательских программ
- [x] 5 — Экспорт/импорт данных (JSON) + локальные напоминания
- [x] 6 — Единицы кг/фунт (реальная конверсия), каталог 72 упражнения,
  фирменная иконка/сплэш, ru-локаль
- [x] 7 — Трекер питания — **УДАЛЁН по решению пользователя** (v0.4). Drift
  **schema v3**: `onUpgrade` дропает `custom_foods`/`food_entries` и создаёт
  `body_weights`. Бэкап schemaVersion 3; старые бэкапы v1/v2 импортируются,
  ключи `customFoods`/`foodEntries` игнорируются. Питание больше не добавлять.
- [x] 8 — Переработка v0.4.0 (пользователь: «убрать питание, вес в LB/кг,
  обновить упражнения, добавить анимации»):
  - `features/bodyweight` — вес тела: ввод в кг/lb (хранение в кг через
    `WeightUnitX.toKg`), история + дельты, график, карточка на Главной и в
    «Прогрессе», бэкап `bodyWeights`, синк с `UserProfile.weightKg`.
    Переключатель `WeightUnitToggle` (кг|lb) в шапке тренировки + тапабельный
    суффикс в `SetRow` (переформатирует поля вживую).
  - Упражнения: сид 131 запись с полем `pattern` (генератор в scratchpad
    `seed/build_seed.py`), `MovementPattern` в domain (31 паттерн + fallback
    классификатор). Анимация техники — `widgets/technique/` (rig.dart: IK,
    keyframes.dart: позы/фикстуры/акценты, side/front painters, figure_style).
    Каталог: `MuscleGroup` чипы, лист фильтров, избранное
    (`favoriteExercisesProvider`, prefs `exercises.favorites`), список/сетка.
  - `AppSettings.defaultRestSeconds` (15–600) → `RestDurationPicker` в Профиле
    и по шестерёнке в `RestTimerBar`; `addExerciseRef` берёт отдых из настроек.
  - Микро-анимации: `core/widgets/pressable_scale.dart`, `staggered_fade_in.dart`,
    пружинящая галочка подхода, пульс таймера, `pr_celebration.dart`
    (`beatsPersonalRecord` в domain/services). Reduce-motion уважается.
  - `flutter_animate` больше не используется (убран из pubspec).

- [x] 9 — Hotfix 0.4.1: чёрный экран на старте. Причина — незакоммиченный
  `pubspec.lock`: CI подтянул `shared_preferences_android 2.5.0` (новый
  Pigeon-JNI бэкенд), `SharedPreferences.getInstance()` зависал до `runApp`.
  Фикс: пин `shared_preferences_android: 2.4.27`, **`pubspec.lock` теперь в
  git** (CI: `flutter pub get --enforce-lockfile`), `core/startup/startup_guard.dart`
  (prefs с таймаутом 4 с → in-memory fallback + `prefsDegradedProvider`;
  `StartupErrorApp` показывает текст исключения вместо чёрного экрана),
  напоминания инициализируются после `runApp`. Тесты в CI теперь блокируют APK.

**Версия приложения:** держи `pubspec.yaml` `version:` и
`lib/core/app_info.dart` `kAppVersion` в синхроне; версия видна в Профиле.

**Зависимости:** lock-файл закоммичен и сгенерирован на той же версии Flutter,
что в CI (3.44.7). Обновлять зависимости только осознанно (`flutter pub upgrade`
→ проверка на телефоне). Пин `shared_preferences_android` не снимать, пока
новый JNI-бэкенд не проверен на реальном устройстве.

**Не входит (осознанно):** облачная синхронизация, домашние виджеты
(платформо-зависимые), онлайн-база продуктов/штрихкоды. Возможные улучшения:
onboarding-флоу, golden-тесты, юнит-осознанный шаг прогрессии.

## Сборка, тесты, запуск

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # ОБЯЗАТЕЛЬНО (Drift)
flutter analyze        # ожидаем: No issues found!
flutter test           # ожидаем: All tests passed!
flutter run            # на подключённом устройстве
```

- `app_database.g.dart` и прочие `*.g.dart` — в `.gitignore`; без build_runner
  проект не соберётся.
- Widget-тесты используют `test/support/pump_app.dart` (высокий surface, чтобы
  строились ленивые списки).

## Тест на телефоне

- APK собирает **GitHub Actions**: `.github/workflows/android-apk.yml` →
  артефакт `fittnes-release-apk` (запускается на пуш в ветку или вручную).
  Полный гайд — `MOBILE.md`.
- `android/` и `ios/` закоммичены. applicationId `com.fittnes.fittnes`,
  имя «Fittnes», `minSdk 23`, включён core library desugaring (для
  flutter_local_notifications), добавлены разрешения POST_NOTIFICATIONS /
  RECEIVE_BOOT_COMPLETED.

## Особенности окружения (агент/CI)

- В dev-контейнере агента прокси **блокирует Google** (`dl.google.com`,
  `gstatic.com`) и **GitHub raw/releases** → нельзя ставить Android SDK/NDK и
  качать ассеты. Поэтому APK собирается только в GitHub Actions, а не локально.
- Flutter в контейнере ставится клоном в `/opt/flutter` (эфемерно, может
  пропасть после рестарта). Ставить **тег 3.44.7** (как в CI):
  `git clone --depth 1 -b 3.44.7 https://github.com/flutter/flutter.git /opt/flutter`
  — иначе `pubspec.lock` потребует более новый SDK и CI с `--enforce-lockfile`
  упадёт.
- Для web-превью со скриншотами нужен ВРЕМЕННЫЙ слой (НЕ коммитить):
  conditional DB-connection (native/web), `web/sqlite3.wasm` + скомпилированный
  `web/drift_worker.js` (берутся из пакета drift в pub-cache), бандл-шрифт
  DejaVu (кириллица оффлайн, т.к. google_fonts не качается), демо-сид данных,
  сборка `flutter build web --release --no-web-resources-cdn`. После скриншотов
  всё откатывается (`git checkout` + `rm`), дерево остаётся чистым.

## Договорённости по работе

- Работать модулями, каждый — рабочий, с тестами, отдельным коммитом и пушем.
- Коммиты подписывать (Co-Authored-By Claude), пушить в `claude/session-tdabmo`.
- Выбирать более современное/красивое решение и объяснять почему.
- Тесты писать на чистую логику (движки, репозитории, сериализация) + widget-
  тесты ключевых экранов через Riverpod-оверрайды.

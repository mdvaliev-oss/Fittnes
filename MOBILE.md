# 📱 Тестирование на телефоне

Приложение — Flutter, поддерживает **Android** и **iOS**. Ниже — самый простой
путь получить установочный файл без настройки окружения у себя.

---

## Вариант A (проще всего) — APK из GitHub Actions

CI собирает готовый `.apk`, который ставится на любой Android-телефон.

1. На GitHub открой вкладку **Actions** репозитория.
2. Слева выбери workflow **«Build Android APK»**.
   - Он запускается **автоматически** при каждом пуше в ветку
     `claude/session-tdabmo`.
   - Или нажми **Run workflow** → выбери ветку `claude/session-tdabmo` →
     **Run** (ручной запуск).
3. Дождись зелёной галочки (~6–10 мин). Открой завершённый запуск.
4. Внизу, в разделе **Artifacts**, скачай **`fittnes-release-apk`**
   (это zip — внутри `app-release.apk`).
5. Перекинь `app-release.apk` на телефон (кабель, Telegram, Google Drive…).
6. На телефоне открой файл и установи. При первом запуске Android попросит
   разрешить **«Установка из неизвестных источников»** для приложения, из
   которого открываешь APK (Файлы/Chrome/Telegram) — разреши.

> APK подписан отладочным ключом — этого достаточно для личного тестирования.
> Для публикации в Google Play нужен собственный keystore (см. ниже).

---

## Вариант B — собрать локально (если есть Flutter)

Нужен установленный **Flutter 3.24+** и **Android Studio** (Android SDK).

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # генерация Drift
flutter build apk --release
# APK: build/app/outputs/flutter-apk/app-release.apk
```

Либо запустить прямо на подключённом телефоне (USB, включён режим разработчика
и отладка по USB):

```bash
flutter run --release
```

---

## iOS

Для iOS Apple требует подпись и Mac с Xcode — готового `.ipa` без этого собрать
нельзя. На Mac:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
open ios/Runner.xcworkspace   # выбрать свою команду подписи (Signing & Team)
flutter run --release          # на подключённом iPhone
```

---

## Что уже настроено

- `android/` и `ios/` сгенерированы; applicationId `com.fittnes.fittnes`,
  имя приложения **Fittnes**, `minSdk 23`.
- Для локальных напоминаний включён **core library desugaring** и добавлены
  разрешения `POST_NOTIFICATIONS` / `RECEIVE_BOOT_COMPLETED`.
- Drift/SQLite и `shared_preferences` работают из коробки.

## Заметки по тестированию

- **Напоминания**: при включении тумблера в Профиле Android 13+ спросит
  разрешение на уведомления — разреши, чтобы приходило ежедневное напоминание.
- **Данные** хранятся локально (SQLite + preferences) и переживают перезапуск.
  Экспорт/импорт — в Профиле → «Данные».
- Первый экран открывается пустым (нет истории) — начни тренировку с главной,
  добавь упражнения, заверши; появятся история, прогресс и восстановление.

## Своя подпись для релиза (опционально)

Создай keystore и `android/key.properties`, затем замени в
`android/app/build.gradle.kts` debug-подпись на свою (см.
[docs.flutter.dev/deployment/android](https://docs.flutter.dev/deployment/android)).

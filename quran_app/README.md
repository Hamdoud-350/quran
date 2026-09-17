# Holy Quran Audio — Streaming & Offline (Flutter + Material 3)

Production-ready Flutter app. Clean Architecture + Riverpod.
APIs: **MP3Quran v3** (streaming) + **Quran.com v4** (metadata + ayah timings). No keys needed.

## Architecture

```
lib/
  main.dart                        # AudioService.init + AudioSession + ProviderScope
  core/theme/app_theme.dart         # Material 3, Material You, dark/light
  data/
    models/        reciter.dart / surah.dart / ayah_timing.dart / ambient_sound.dart
    datasources/   mp3quran_api.dart / qurancom_api.dart
    repositories/  quran_repository.dart (façade + offline fallback) / surah_fallback.dart (114)
    local/         favorites_store.dart (SharedPreferences)
  features/
    audio/         audio_handler.dart (background/lock-screen)
                   quran_player_controller.dart (Riverpod: timings, repeat, sleep)
                   ambient_mixer.dart (6 looping players, independent volumes)
    downloads/     download_manager.dart (Dio -> app docs /quran/*.mp3)
  ui/
    screens/       home, reciters, surah_list, player, downloads, favorites
    widgets/       now_playing_bar, wave_visualizer, ambient_mixer_sheet, sleep_timer_dialog
```

**Audio strategy (hybrid, reliable):**
- Stream per-surah MP3: `moshaf.server + 001.mp3` (MP3Quran).
- Highlight ayahs with Quran.com `chapter_recitations/7/{surah}` timestamps
  (`verse_key`, `timestamp_from/to`). Falls back gracefully when offline.
- Background: `audio_service` + `just_audio` (lock-screen title/reciter/seek).
- Ambient: 6 separate looped `just_audio` players under the Quran volume.
- Offline: `DownloadManager` (Dio download to `getApplicationDocumentsDirectory()/quran/`).

## Setup (build the APK)

### Option A — Android Studio (easiest, recommended)
1. Install Flutter SDK (stable) + Android Studio + Android SDK 34.
2. Copy this `quran_app/` folder, then:
   ```
   flutter pub get
   flutter run            # debug on emulator/device
   flutter build apk --release
   ```
   APK: `build/app/outputs/flutter-apk/app-release.apk`
3. Add 6 ambient loops (royalty-free) as:
   `assets/audio/ambient/{rain,ocean,river,wind,birds,fire}.mp3`
4. Merge `android_MANIFEST_SNIPPET.xml` permissions/service into
   `android/app/src/main/AndroidManifest.xml`.
5. `minSdkVersion 23`, compileSdk 34 (audio_service requirement).

### Option B — No local setup (GitHub Actions cloud build)
1. `git init && git add . && git commit -m init && git push` to GitHub.
2. Actions tab → **Build APK** → APK artifact `quran-apk` (arm64-v8a).
3. Download on phone → install (allow unknown apps).

### Option C — I build it here
This workspace has Java 21 + Node but **no Flutter/Android SDK yet**.
Say the word and I will download Flutter + cmdline-tools (~2 GB) and run
`flutter build apk` in this terminal — takes 20–40 min first time.

## Key API contracts

- Reciters: `GET https://mp3quran.net/api/v3/reciters?language=ar`
- Chapters: `GET https://api.quran.com/api/v4/chapters?language=en`
- Timings:  `GET https://api.quran.com/api/v4/chapter_recitations/7/{1..114}?segments=true`
- Audio URL: `{moshaf.server}{NNN}.mp3`, NNN = surah zero-padded (001..114)

## Production notes

- Errors never crash playback: timings/download failures degrade silently.
- Sleep timer + repeat state live in `QuranPlayer`, not widgets.
- To add reciter images on lock screen: set `MediaItem.artUri`.
- For ayah text display: add `GET /verses/by_chapter/{n}?words=true&text_uthmani=true`.
- Sign release APK: `keytool -genkey ...` + `android/key.properties`.

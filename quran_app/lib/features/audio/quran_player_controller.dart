import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../data/models/ayah_timing.dart';
import '../../data/models/reciter.dart';
import '../../data/models/surah.dart';
import '../../data/repositories/quran_repository.dart';
import 'audio_handler.dart';

/// Currently loaded track (surah + reciter + moshaf).
class NowPlaying {
  final Reciter reciter;
  final Moshaf moshaf;
  final Surah surah;
  final String audioUrl;
  final String? localPath;
  const NowPlaying({
    required this.reciter,
    required this.moshaf,
    required this.surah,
    required this.audioUrl,
    this.localPath,
  });
}

enum RepeatMode { off, ayah, surah }

class PlayerState {
  final NowPlaying? track;
  final bool playing;
  final Duration position;
  final Duration duration;
  final List<AyahTiming> timings;
  final int? currentAyah; // highlighted
  final RepeatMode repeat;
  final double quranVolume;
  final Duration? sleepIn;

  const PlayerState({
    this.track,
    this.playing = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.timings = const [],
    this.currentAyah,
    this.repeat = RepeatMode.off,
    this.quranVolume = 1.0,
    this.sleepIn,
  });

  PlayerState copyWith({
    NowPlaying? track,
    bool? playing,
    Duration? position,
    Duration? duration,
    List<AyahTiming>? timings,
    int? currentAyah,
    RepeatMode? repeat,
    double? quranVolume,
    Duration? sleepIn,
  }) =>
      PlayerState(
        track: track ?? this.track,
        playing: playing ?? this.playing,
        position: position ?? this.position,
        duration: duration ?? this.duration,
        timings: timings ?? this.timings,
        currentAyah: currentAyah ?? this.currentAyah,
        repeat: repeat ?? this.repeat,
        quranVolume: quranVolume ?? this.quranVolume,
        sleepIn: sleepIn,
      );
}

/// Riverpod controller binding QuranAudioHandler (background) +
/// timings (highlighting) + repeat-for-memorization + sleep timer.
class QuranPlayer extends StateNotifier<PlayerState> {
  QuranPlayer(this._ref) : super(const PlayerState());

  final Ref _ref;
  QuranAudioHandler get _h => _ref.read(audioHandlerProvider);
  StreamSubscription? _posSub;
  StreamSubscription? _playSub;
  StreamSubscription? _durSub;
  Timer? _sleepTimer;
  Timer? _sleepCountdown;

  Future<void> playSurah(Reciter reciter, Moshaf moshaf, Surah surah,
      {String? localPath}) async {
    final url = moshaf.surahUrl(surah.number);
    final track = NowPlaying(
      reciter: reciter,
      moshaf: moshaf,
      surah: surah,
      audioUrl: url,
      localPath: localPath,
    );
    state = state.copyWith(track: track, timings: [], currentAyah: null);
    await _h.playSurah(
      audioUrl: Uri.parse(url),
      surahTitle: 'سورة ${surah.nameArabic}',
      reciter: reciter.name,
      localPath: localPath,
    );
    _listen();
    // Fetch ayah timings async (non-blocking).
    final timings =
        await _ref.read(quranRepositoryProvider).timings(surah.number);
    if (state.track == track) {
      state = state.copyWith(timings: timings);
    }
  }

  void _listen() {
    _posSub?.cancel();
    _playSub?.cancel();
    _durSub?.cancel();
    final p = _h.player;
    _posSub = p.positionStream.listen((pos) {
      var ayah = state.currentAyah;
      if (state.timings.isNotEmpty) {
        ayah = ayahAt(state.timings, pos);
      }
      // Ayah repeat for memorization: loop inside [from,to].
      if (state.repeat == RepeatMode.ayah && ayah != null) {
        final t = state.timings.firstWhere((e) => e.ayah == ayah,
            orElse: () => state.timings.first);
        if (pos >= t.to) {
          _h.seek(t.from);
          return;
        }
      }
      state = state.copyWith(position: pos, currentAyah: ayah);
      if (state.repeat == RepeatMode.surah &&
          state.duration > Duration.zero &&
          pos >= state.duration - const Duration(milliseconds: 500)) {
        _h.seek(Duration.zero);
        _h.play();
      }
    });
    _playSub = p.playerStateStream.listen((s) {
      state = state.copyWith(playing: s.playing);
    });
    _durSub = p.durationStream.listen((d) {
      if (d != null) state = state.copyWith(duration: d);
    });
  }

  Future<void> toggle() async =>
      state.playing ? _h.pause() : _h.play();
  Future<void> seek(Duration d) => _h.seek(d);
  Future<void> seekToAyah(int ayah) async {
    final t = state.timings.where((e) => e.ayah == ayah);
    if (t.isNotEmpty) await _h.seek(t.first.from);
  }

  Future<void> setQuranVolume(double v) async {
    state = state.copyWith(quranVolume: v);
    await _h.setQuranVolume(v);
  }

  void cycleRepeat() {
    final next = switch (state.repeat) {
      RepeatMode.off => RepeatMode.surah,
      RepeatMode.surah => RepeatMode.ayah,
      RepeatMode.ayah => RepeatMode.off,
    };
    state = state.copyWith(repeat: next);
  }

  /// Sleep timer (مؤقت النوم): pause after [after].
  void startSleepTimer(Duration after) {
    cancelSleepTimer();
    state = state.copyWith(sleepIn: after);
    _sleepCountdown = Timer.periodic(const Duration(seconds: 1), (_) {
      final left = (state.sleepIn ?? Duration.zero) - const Duration(seconds: 1);
      if (left.isNegative) {
        cancelSleepTimer();
      } else {
        state = state.copyWith(sleepIn: left);
      }
    });
    _sleepTimer = Timer(after, () async {
      await _h.pause();
      cancelSleepTimer();
    });
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepCountdown?.cancel();
    _sleepTimer = null;
    _sleepCountdown = null;
    if (state.sleepIn != null) state = state.copyWith(sleepIn: Duration.zero);
    state = const PlayerState(
      // keep track fields
      playing: false,
    ).copyWith(
      track: state.track,
      position: state.position,
      duration: state.duration,
      timings: state.timings,
      currentAyah: state.currentAyah,
      repeat: state.repeat,
      quranVolume: state.quranVolume,
    );
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _playSub?.cancel();
    _durSub?.cancel();
    _sleepTimer?.cancel();
    _sleepCountdown?.cancel();
    super.dispose();
  }
}

final audioHandlerProvider = Provider<QuranAudioHandler>((_) {
  throw UnimplementedError('Override in main.dart with live handler');
});

final quranPlayerProvider =
    StateNotifierProvider<QuranPlayer, PlayerState>((ref) {
  return QuranPlayer(ref);
});

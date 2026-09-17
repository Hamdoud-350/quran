import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../data/models/ambient_sound.dart';

/// Independent looping players mixed UNDER the Quran audio.
/// Each ambient sound has its own AudioPlayer + volume (0..1).
/// Tears down cleanly; survives Quran track changes.
class AmbientMixer extends StateNotifier<Map<String, double>> {
  AmbientMixer() : super({for (final s in AmbientSound.all) s.id: 0.0}) {
    for (final s in AmbientSound.all) {
      _players[s.id] = AudioPlayer()..setLoopMode(LoopMode.one);
    }
  }

  final Map<String, AudioPlayer> _players = {};
  bool _ready = false;

  Future<void> _ensureLoaded(String id) async {
    if (_ready) return;
    // Lazy-load all loops once (small local assets).
    for (final s in AmbientSound.all) {
      try {
        await _players[s.id]!.setAsset(s.asset);
      } catch (_) {
        // Missing asset file -> silently skip (dev can add mp3 later).
      }
    }
    _ready = true;
  }

  /// 0 = muted, >0 = audible. Starts/stops player automatically.
  Future<void> setVolume(String id, double volume) async {
    await _ensureLoaded(id);
    state = {...state, id: volume};
    final p = _players[id];
    if (p == null) return;
    await p.setVolume(volume);
    if (volume <= 0.01) {
      if (p.playing) await p.pause();
    } else {
      if (!p.playing) await p.play();
    }
  }

  double volumeOf(String id) => state[id] ?? 0.0;
  bool get anyActive => state.values.any((v) => v > 0.01);

  @override
  void dispose() {
    for (final p in _players.values) {
      p.dispose();
    }
    super.dispose();
  }
}

final ambientMixerProvider =
    StateNotifierProvider<AmbientMixer, Map<String, double>>((ref) {
  return AmbientMixer();
});

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// Background audio handler: lock-screen controls, headset buttons,
/// notification with surah title + reciter. Survives app backgrounding.
///
/// Wiring (in main.dart):
///   final handler = await AudioService.init(
///     builder: () => QuranAudioHandler(),
///     config: const AudioServiceConfig(
///       androidNotificationChannelId: 'com.quran.audio.channel',
///       androidNotificationChannelName: 'Quran Playback',
///       androidNotificationOngoing: true,
///     ),
///   );
class QuranAudioHandler extends BaseAudioHandler with SeekHandler {
  QuranAudioHandler() {
    _player = AudioPlayer();
    _wire();
  }

  late final AudioPlayer _player;
  AudioPlayer get player => _player;

  void _wire() {
    _player.playbackEventStream.map(_toPlaybackState).pipe(playbackState);
    _player.sequenceStateStream.listen((seq) {
      final src = seq?.currentSource;
      if (src is UriAudioSource) {
        mediaItem.add(src.tag as MediaItem?);
      }
    });
  }

  PlaybackState _toPlaybackState(PlaybackEvent e) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        _player.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: e.currentIndex,
    );
  }

  Future<void> playSurah({
    required Uri audioUrl,
    required String surahTitle, // "سورة البقرة"
    required String reciter, // reciter name
    String? localPath, // offline file
  }) async {
    final source = localPath != null
        ? AudioSource.file(localPath,
            tag: MediaItem(
              id: localPath,
              title: surahTitle,
              artist: reciter,
              album: 'Holy Quran',
            ))
        : AudioSource.uri(audioUrl,
            tag: MediaItem(
              id: audioUrl.toString(),
              title: surahTitle,
              artist: reciter,
              album: 'Holy Quran',
            ));
    mediaItem.add(source.tag as MediaItem);
    await _player.setAudioSource(source);
    await _player.play();
  }

  @override
  Future<void> play() => _player.play();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> stop() => _player.stop();
  @override
  Future<void> seek(Duration position) => _player.seek(position);
  @override
  Future<void> skipToNext() async => seek((_player.position) + const Duration(seconds: 10));
  @override
  Future<void> skipToPrevious() async {
    final back = _player.position - const Duration(seconds: 10);
    await seek(back.isNegative ? Duration.zero : back);
  }

  Future<void> setQuranVolume(double v) => _player.setVolume(v);
}

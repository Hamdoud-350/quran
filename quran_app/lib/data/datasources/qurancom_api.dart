import 'package:dio/dio.dart';
import '../models/surah.dart';
import '../models/ayah_timing.dart';

/// Connector for Quran.com v4 — free, no key.
/// - Chapters:  GET /chapters?language=en
/// - Timings:   GET /chapter_recitations/{recitationId}/{surah}
///   Famous recitation ids: 1=AbdulBaset Murattal, 2=Abdullah Awad,
///   3=Al-Dossari, 7=Mishary Alafasy (most complete timestamps).
class QuranComApi {
  QuranComApi([Dio? dio])
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://api.quran.com/api/v4',
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 20),
            ));

  final Dio _dio;

  Future<List<Surah>> fetchChapters() async {
    final res = await _dio.get('/chapters', queryParameters: {
      'language': 'en',
    });
    final list = (res.data['chapters'] as List? ?? []);
    return list
        .map((e) => Surah.fromQuranComJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Verse-by-verse timestamps for ayah highlighting.
  /// Returns empty list when the recitation has no timing data.
  Future<List<AyahTiming>> fetchTimings({
    required int surah,
    int recitationId = 7,
  }) async {
    try {
      final res = await _dio.get('/chapter_recitations/$recitationId/$surah',
          queryParameters: {'segments': true});
      final stamps =
          (res.data['audio_file']?['timestamps'] as List? ?? []);
      return stamps
          .map((e) => AyahTiming.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return []; // offline / missing -> UI falls back to no-highlight mode
    }
  }
}

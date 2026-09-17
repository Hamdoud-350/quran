import 'package:dio/dio.dart';
import '../models/reciter.dart';

/// Connector for MP3Quran v3 — free, no key.
/// Docs pattern: https://mp3quran.net/api/v3/reciters?language=ar|en
///              https://mp3quran.net/api/v3/suwar?language=ar (surah meta)
class Mp3QuranApi {
  Mp3QuranApi([Dio? dio])
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://mp3quran.net/api/v3',
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 20),
            ));

  final Dio _dio;

  /// All reciters with their moshafs (servers + surah lists).
  Future<List<Reciter>> fetchReciters({String language = 'ar'}) async {
    final res = await _dio.get('/reciters', queryParameters: {
      'language': language,
    });
    final list = (res.data['reciters'] as List? ?? []);
    return list.map((e) => Reciter.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Search reciters by arabic/latin name.
  List<Reciter> search(List<Reciter> all, String query) {
    final q = query.trim();
    if (q.isEmpty) return all;
    return all.where((r) => r.name.contains(q)).toList();
  }
}

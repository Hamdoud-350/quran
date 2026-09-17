import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/mp3quran_api.dart';
import '../datasources/qurancom_api.dart';
import '../models/reciter.dart';
import '../models/surah.dart';
import '../models/ayah_timing.dart';
import 'surah_fallback.dart';

/// Single façade over both APIs + offline fallback surah list.
/// UI never talks to Dio directly — only through this repository.
class QuranRepository {
  QuranRepository({Mp3QuranApi? mp3, QuranComApi? qcom})
      : mp3 = mp3 ?? Mp3QuranApi(),
        qcom = qcom ?? QuranComApi();

  final Mp3QuranApi mp3;
  final QuranComApi qcom;

  Future<List<Reciter>> reciters() => mp3.fetchReciters(language: 'ar');

  Future<List<Surah>> surahs() async {
    try {
      return await qcom.fetchChapters();
    } catch (_) {
      return SurahFallback.all; // offline: embedded 114 names
    }
  }

  Future<List<AyahTiming>> timings(int surah) =>
      qcom.fetchTimings(surah: surah, recitationId: 7);
}

final quranRepositoryProvider = Provider<QuranRepository>((ref) {
  return QuranRepository();
});

final recitersProvider = FutureProvider<List<Reciter>>((ref) {
  return ref.watch(quranRepositoryProvider).reciters();
});

final surahsProvider = FutureProvider<List<Surah>>((ref) {
  return ref.watch(quranRepositoryProvider).surahs();
});

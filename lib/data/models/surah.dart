import 'package:equatable/equatable.dart';

/// Surah metadata. Primary source: Quran.com v4
/// GET https://api.quran.com/api/v4/chapters?language=en
/// Local fallback covers all 114 surahs offline (names embedded below).
class Surah extends Equatable {
  final int number;
  final String nameArabic;
  final String nameSimple; // English transliteration
  final String nameEnglish; // translation
  final int versesCount;
  final String revelationPlace;

  const Surah({
    required this.number,
    required this.nameArabic,
    required this.nameSimple,
    required this.nameEnglish,
    required this.versesCount,
    required this.revelationPlace,
  });

  factory Surah.fromQuranComJson(Map<String, dynamic> j) => Surah(
        number: (j['id'] as num).toInt(),
        nameArabic: (j['name_arabic'] ?? '').toString(),
        nameSimple: (j['name_simple'] ?? '').toString(),
        nameEnglish: ((j['translated_name'] as Map?)?['name'] ?? '').toString(),
        versesCount: (j['verses_count'] as num).toInt(),
        revelationPlace: (j['revelation_place'] ?? '').toString(),
      );

  /// True if query matches number, arabic, or english name.
  bool matches(String q) {
    q = q.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (int.tryParse(q) == number) return true;
    return nameArabic.contains(q.trim()) ||
        nameSimple.toLowerCase().contains(q) ||
        nameEnglish.toLowerCase().contains(q);
  }

  @override
  List<Object?> get props =>
      [number, nameArabic, nameSimple, nameEnglish, versesCount];
}

import 'package:equatable/equatable.dart';

/// A reciter (قارئ) + one of his moshafs (editions).
/// MP3Quran v3: GET https://mp3quran.net/api/v3/reciters?language=ar
/// => { "reciters": [ { "id":1, "name":"...", "letter":"...", "moshaf":[ {...} ] } ] }
class Moshaf extends Equatable {
  final int id;
  final String name;
  final String server; // e.g. https://server13.mp3quran.net/husr/
  final List<int> surahList;
  final String surahTotal;

  const Moshaf({
    required this.id,
    required this.name,
    required this.server,
    required this.surahList,
    required this.surahTotal,
  });

  factory Moshaf.fromJson(Map<String, dynamic> j) {
    final rawList = (j['surah_list'] as String? ?? '').split(',');
    return Moshaf(
      id: _toInt(j['id']),
      name: (j['name'] ?? '').toString(),
      server: _withSlash((j['server'] ?? '').toString()),
      surahList: rawList
          .map((e) => int.tryParse(e.trim()))
          .whereType<int>()
          .toList(),
      surahTotal: (j['surah_total'] ?? '').toString(),
    );
  }

  /// Full streaming URL for a surah: server + 001.mp3 (zero-padded 3 digits)
  String surahUrl(int surahNumber) {
    final n = surahNumber.toString().padLeft(3, '0');
    return '$server$n.mp3';
  }

  static String _withSlash(String s) => s.endsWith('/') ? s : '$s/';
  static int _toInt(dynamic v) =>
      v is int ? v : int.tryParse(v.toString()) ?? 0;

  @override
  List<Object?> get props => [id, name, server, surahList];
}

class Reciter extends Equatable {
  final int id;
  final String name; // Arabic name
  final String letter;
  final List<Moshaf> moshafs;

  const Reciter({
    required this.id,
    required this.name,
    required this.letter,
    required this.moshafs,
  });

  factory Reciter.fromJson(Map<String, dynamic> j) {
    final m = (j['moshaf'] as List? ?? [])
        .map((e) => Moshaf.fromJson(e as Map<String, dynamic>))
        .toList();
    return Reciter(
      id: _toInt(j['id']),
      name: (j['name'] ?? '').toString(),
      letter: (j['letter'] ?? '').toString(),
      moshafs: m,
    );
  }

  Moshaf get defaultMoshaf => moshafs.first;
  bool hasSurah(int n) => moshafs.any((m) => m.surahList.contains(n));

  static int _toInt(dynamic v) =>
      v is int ? v : int.tryParse(v.toString()) ?? 0;

  @override
  List<Object?> get props => [id, name, moshafs];
}

import 'package:equatable/equatable.dart';

/// Per-ayah timestamp inside a surah audio file (ms).
/// Primary source: Quran.com v4 chapter_recitations:
/// GET https://api.quran.com/api/v4/chapter_recitations/{recitation_id}/{surah}
/// => { "audio_file": { "audio_url": "...", "timestamps": [ {"verse_key":"2:1","timestamp_from":0,"timestamp_to":12000}, ... ] } }
class AyahTiming extends Equatable {
  final String verseKey; // "2:255"
  final int surah;
  final int ayah;
  final Duration from;
  final Duration to;

  const AyahTiming({
    required this.verseKey,
    required this.surah,
    required this.ayah,
    required this.from,
    required this.to,
  });

  factory AyahTiming.fromJson(Map<String, dynamic> j) {
    final key = (j['verse_key'] ?? '1:1').toString();
    final parts = key.split(':');
    return AyahTiming(
      verseKey: key,
      surah: int.tryParse(parts.first) ?? 1,
      ayah: parts.length > 1 ? (int.tryParse(parts[1]) ?? 1) : 1,
      from: Duration(milliseconds: (j['timestamp_from'] as num? ?? 0).toInt()),
      to: Duration(milliseconds: (j['timestamp_to'] as num? ?? 0).toInt()),
    );
  }

  bool contains(Duration pos) => pos >= from && pos < to;

  @override
  List<Object?> get props => [verseKey, from, to];
}

/// Maps a playback position -> currently recited ayah.
int? ayahAt(List<AyahTiming> list, Duration pos) {
  for (final t in list) {
    if (t.contains(pos)) return t.ayah;
  }
  return null;
}

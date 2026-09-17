import 'package:equatable/equatable.dart';

/// Ambient nature sound mixed UNDER the Quran audio.
/// Files live in assets/audio/ambient/*.mp3 (looped with just_audio).
/// Ship your own royalty-free loops with these exact names, or fetch
/// from Openverse/pixabay (rain, ocean, river, wind, birds, fire).
class AmbientSound extends Equatable {
  final String id; // 'rain'
  final String nameAr;
  final String nameEn;
  final String asset; // asset path
  final String emoji; // fallback icon (no image assets needed)

  const AmbientSound({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.asset,
    required this.emoji,
  });

  static const all = <AmbientSound>[
    AmbientSound(id: 'rain', nameAr: 'مطر', nameEn: 'Rain', asset: 'assets/audio/ambient/rain.mp3', emoji: '🌧'),
    AmbientSound(id: 'ocean', nameAr: 'أمواج', nameEn: 'Ocean', asset: 'assets/audio/ambient/ocean.mp3', emoji: '🌊'),
    AmbientSound(id: 'river', nameAr: 'ماء', nameEn: 'Water', asset: 'assets/audio/ambient/river.mp3', emoji: '💧'),
    AmbientSound(id: 'wind', nameAr: 'رياح', nameEn: 'Wind', asset: 'assets/audio/ambient/wind.mp3', emoji: '🍃'),
    AmbientSound(id: 'birds', nameAr: 'طيور', nameEn: 'Birds', asset: 'assets/audio/ambient/birds.mp3', emoji: '🐦'),
    AmbientSound(id: 'fire', nameAr: 'نار', nameEn: 'Fire', asset: 'assets/audio/ambient/fire.mp3', emoji: '🔥'),
  ];

  @override
  List<Object?> get props => [id];
}

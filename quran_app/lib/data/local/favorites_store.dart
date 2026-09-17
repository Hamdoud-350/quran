import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Favorites: bookmark reciters, surahs, specific ayahs.
/// Keys persisted in SharedPreferences as string sets:
///   fav_reciters = {"12"}, fav_surahs = {"2:12_moshaf..."}, fav_ayahs={"2:255"}
class Favorites extends StateNotifier<FavData> {
  Favorites() : super(const FavData()) {
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = FavData(
      reciters: p.getStringList('fav_reciters')?.toSet() ?? {},
      surahs: p.getStringList('fav_surahs')?.toSet() ?? {},
      ayahs: p.getStringList('fav_ayahs')?.toSet() ?? {},
    );
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList('fav_reciters', state.reciters.toList());
    await p.setStringList('fav_surahs', state.surahs.toList());
    await p.setStringList('fav_ayahs', state.ayahs.toList());
  }

  void toggleReciter(String id) {
    final s = {...state.reciters};
    s.contains(id) ? s.remove(id) : s.add(id);
    state = state.copyWith(reciters: s);
    _save();
  }

  void toggleSurah(String id) {
    final s = {...state.surahs};
    s.contains(id) ? s.remove(id) : s.add(id);
    state = state.copyWith(surahs: s);
    _save();
  }

  void toggleAyah(String verseKey) {
    final s = {...state.ayahs};
    s.contains(verseKey) ? s.remove(verseKey) : s.add(verseKey);
    state = state.copyWith(ayahs: s);
    _save();
  }
}

class FavData {
  final Set<String> reciters;
  final Set<String> surahs;
  final Set<String> ayahs;
  const FavData({this.reciters = const {}, this.surahs = const {}, this.ayahs = const {}});
  FavData copyWith({Set<String>? reciters, Set<String>? surahs, Set<String>? ayahs}) =>
      FavData(reciters: reciters ?? this.reciters, surahs: surahs ?? this.surahs, ayahs: ayahs ?? this.ayahs);
}

final favoritesProvider = StateNotifierProvider<Favorites, FavData>((ref) {
  return Favorites();
});

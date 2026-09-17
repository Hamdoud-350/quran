import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/favorites_store.dart';

/// Saved reciters / surahs / ayahs.
class FavoritesScreen extends ConsumerWidget {
  final bool inTab;
  const FavoritesScreen({super.key, this.inTab = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(favoritesProvider);
    final notifier = ref.read(favoritesProvider.notifier);
    final body = ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _Section(
          title: 'Reciters — القرّاء (${f.reciters.length})',
          items: f.reciters.toList(),
          onClear: (id) => notifier.toggleReciter(id),
        ),
        _Section(
          title: 'Surahs — السور (${f.surahs.length})',
          items: f.surahs.toList(),
          onClear: (id) => notifier.toggleSurah(id),
        ),
        _Section(
          title: 'Ayahs — الآيات (${f.ayahs.length})',
          items: f.ayahs.toList(),
          onClear: (id) => notifier.toggleAyah(id),
        ),
        if (f.reciters.isEmpty && f.surahs.isEmpty && f.ayahs.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Tap ☆ / ♡ / 🔖 anywhere to save favorites for memorization.',
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
    if (inTab) return body;
    return Scaffold(appBar: AppBar(title: const Text('Saved — المفضلة')), body: body);
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<String> items;
  final void Function(String) onClear;
  const _Section({required this.title, required this.items, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: items
            .map((id) => ListTile(
                  dense: true,
                  title: Text(id),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => onClear(id),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/quran_repository.dart';
import '../../data/local/favorites_store.dart';

/// All reciters with AR search + filter + favorite star.
class RecitersScreen extends ConsumerStatefulWidget {
  final bool inTab;
  const RecitersScreen({super.key, this.inTab = false});
  @override
  ConsumerState<RecitersScreen> createState() => _S();
}

class _S extends ConsumerState<RecitersScreen> {
  String q = '';
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(recitersProvider);
    final favs = ref.watch(favoritesProvider);
    final body = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SearchBar(
            hintText: 'ابحث عن قارئ — العفاسي / Husary',
            leading: const Icon(Icons.search),
            onChanged: (v) => setState(() => q = v),
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (all) {
              final list = all
                  .where((r) => q.isEmpty || r.name.contains(q.trim()))
                  .toList();
              return ListView.builder(
                itemCount: list.length,
                itemBuilder: (c, i) {
                  final r = list[i];
                  final isFav = favs.reciters.contains('${r.id}');
                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                          child: Text(r.name.characters.first)),
                      title: Text(r.name),
                      subtitle: Text(
                          '${r.moshafs.length} moshaf • ${r.defaultMoshaf.surahTotal} surah'),
                      trailing: IconButton(
                        icon: Icon(isFav
                            ? Icons.star
                            : Icons.star_outline),
                        color: isFav ? Colors.amber : null,
                        onPressed: () => ref
                            .read(favoritesProvider.notifier)
                            .toggleReciter('${r.id}'),
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ReciterSurahsPage(reciterId: r.id),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
    if (widget.inTab) return body;
    return Scaffold(appBar: AppBar(title: const Text('Reciters — القرّاء')), body: body);
  }
}

class ReciterSurahsPage extends ConsumerWidget {
  final int reciterId;
  const ReciterSurahsPage({super.key, required this.reciterId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reciters = ref.watch(recitersProvider);
    final surahs = ref.watch(surahsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Surahs')),
      body: reciters.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (all) {
          final r = all.firstWhere((e) => e.id == reciterId);
          return surahs.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (ss) {
              final avail =
                  ss.where((s) => r.hasSurah(s.number)).toList();
              return ListView.builder(
                itemCount: avail.length,
                itemBuilder: (c, i) => SurahTileRef(
                    surahNumber: avail[i].number, reciterId: reciterId),
              );
            },
          );
        },
      ),
    );
  }
}

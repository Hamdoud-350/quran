import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/surah.dart';
import '../../data/repositories/quran_repository.dart';
import '../../data/local/favorites_store.dart';
import '../../features/audio/quran_player_controller.dart';
import '../../features/downloads/download_manager.dart';
import 'player_screen.dart';

/// Smooth Material 3 surah card: number badge, AR/EN names,
/// play + download + favorite actions.
class SurahTile extends ConsumerWidget {
  final Surah surah;
  const SurahTile({super.key, required this.surah});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text('${surah.number}',
              style: TextStyle(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.bold)),
        ),
        title: Text('سورة ${surah.nameArabic}',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle:
            Text('${surah.nameSimple} • ${surah.nameEnglish} • ${surah.versesCount} ayahs'),
        trailing: const Icon(Icons.play_circle_fill, size: 32),
        onTap: () => _quickPlay(context, ref),
      ),
    );
  }

  Future<void> _quickPlay(BuildContext context, WidgetRef ref) async {
    // Default: first reciter's default moshaf (user picks reciter in Reciters tab).
    final reciters = await ref.read(recitersProvider.future);
    if (reciters.isEmpty) return;
    final r = reciters.first;
    final local = ref
        .read(downloadManagerProvider.notifier)
        .localPathFor(r.id, r.defaultMoshaf.id, surah.number);
    await ref
        .read(quranPlayerProvider.notifier)
        .playSurah(r, r.defaultMoshaf, surah, localPath: local);
    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.92,
          builder: (_, c) => PlayerScreen(scrollController: c),
        ),
      );
    }
  }
}

/// Variant bound to a specific reciter (from ReciterSurahsPage).
class SurahTileRef extends ConsumerWidget {
  final int surahNumber;
  final int reciterId;
  const SurahTileRef(
      {super.key, required this.surahNumber, required this.reciterId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahs = ref.watch(surahsProvider).valueOrNull ?? [];
    final reciters = ref.watch(recitersProvider).valueOrNull ?? [];
    if (surahs.isEmpty || reciters.isEmpty) {
      return const ListTile(title: Text('...'));
    }
    final surah = surahs.firstWhere((s) => s.number == surahNumber);
    final reciter = reciters.firstWhere((r) => r.id == reciterId);
    final moshaf = reciter.moshafs.firstWhere(
      (m) => m.surahList.contains(surahNumber),
      orElse: () => reciter.defaultMoshaf,
    );
    final dl = ref.watch(downloadManagerProvider)[ref
        .read(downloadManagerProvider.notifier)
        .keyFor(reciter.id, moshaf.id, surah.number)];
    final favs = ref.watch(favoritesProvider);
    final favKey = '${reciter.id}_${moshaf.id}_${surah.number}';
    final isFav = favs.surahs.contains(favKey);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text('${surah.number}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        title: Text('سورة ${surah.nameArabic}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${reciter.name} • ${moshaf.name}'),
            if (dl != null && dl.status == DlStatus.downloading)
              LinearProgressIndicator(value: dl.progress),
            if (dl != null && dl.status == DlStatus.done)
              const Text('✓ Offline available',
                  style: TextStyle(color: Colors.green)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Download for offline',
              icon: Icon(dl?.status == DlStatus.done
                  ? Icons.offline_pin
                  : Icons.download_outlined),
              onPressed: () => ref
                  .read(downloadManagerProvider.notifier)
                  .download(
                    reciterId: reciter.id,
                    moshafId: moshaf.id,
                    surah: surah.number,
                    label: 'سورة ${surah.nameArabic} — ${reciter.name}',
                    url: moshaf.surahUrl(surah.number),
                  ),
            ),
            IconButton(
              icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_outline),
              onPressed: () => ref
                  .read(favoritesProvider.notifier)
                  .toggleSurah(favKey),
            ),
            IconButton(
              iconSize: 32,
              icon: const Icon(Icons.play_circle_fill),
              onPressed: () async {
                final local = ref
                    .read(downloadManagerProvider.notifier)
                    .localPathFor(reciter.id, moshaf.id, surah.number);
                await ref
                    .read(quranPlayerProvider.notifier)
                    .playSurah(reciter, moshaf, surah, localPath: local);
                if (context.mounted) {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => DraggableScrollableSheet(
                      expand: false,
                      initialChildSize: 0.92,
                      builder: (_, c) =>
                          PlayerScreen(scrollController: c),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Full surah catalogue (used by deep links / tests).
class SurahListScreen extends ConsumerWidget {
  const SurahListScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(surahsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Surahs — السور')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) => ListView.builder(
          itemCount: list.length,
          itemBuilder: (c, i) => SurahTile(surah: list[i]),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/downloads/download_manager.dart';
import '../../features/audio/quran_player_controller.dart';
import '../../data/repositories/quran_repository.dart';

/// Offline manager: browse + play + delete downloaded surahs. No internet needed.
class DownloadsScreen extends ConsumerWidget {
  final bool inTab;
  const DownloadsScreen({super.key, this.inTab = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dls = ref.watch(downloadManagerProvider);
    final done = dls.values.where((e) => e.status == DlStatus.done).toList();
    final busy = dls.values.where((e) => e.status == DlStatus.downloading).toList();
    final body = done.isEmpty && busy.isEmpty
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No downloads yet.\nOpen a reciter → surah → download icon.\nFiles play here fully offline.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        : ListView(
            children: [
              ...busy.map((e) => ListTile(
                    leading: const CircularProgressIndicator(),
                    title: Text(e.label),
                    subtitle: LinearProgressIndicator(value: e.progress),
                  )),
              ...done.map((e) => Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: const Icon(Icons.offline_pin, color: Colors.green),
                      title: Text(e.label),
                      subtitle: Text(e.path),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Play offline',
                            icon: const Icon(Icons.play_arrow),
                            onPressed: () => _playOffline(context, ref, e),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => ref
                                .read(downloadManagerProvider.notifier)
                                .remove(e.key),
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          );
    if (inTab) return body;
    return Scaffold(appBar: AppBar(title: const Text('Offline — التحميلات')), body: body);
  }

  Future<void> _playOffline(
      BuildContext context, WidgetRef ref, DlEntry e) async {
    // Key format: reciter_moshaf_surah
    final parts = e.key.split('_').map(int.tryParse).toList();
    if (parts.length != 3 || parts.any((p) => p == null)) return;
    final reciters = await ref.read(recitersProvider.future);
    final surahs = await ref.read(surahsProvider.future);
    final r = reciters.firstWhere((x) => x.id == parts[0]);
    final m = r.moshafs.firstWhere((x) => x.id == parts[1],
        orElse: () => r.defaultMoshaf);
    final s = surahs.firstWhere((x) => x.number == parts[2]);
    await ref
        .read(quranPlayerProvider.notifier)
        .playSurah(r, m, s, localPath: e.path);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Playing offline: ${e.label}')));
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/audio/quran_player_controller.dart';
import '../screens/player_screen.dart';

/// Persistent mini-player pinned above the NavigationBar.
/// Tapping expands the full [PlayerScreen] bottom sheet.
class NowPlayingBar extends ConsumerWidget {
  const NowPlayingBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(quranPlayerProvider);
    final t = s.track;
    if (t == null) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final progress = s.duration.inMilliseconds > 0
        ? (s.position.inMilliseconds / s.duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.92,
          builder: (_, c) => PlayerScreen(scrollController: c),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              dense: true,
              leading: CircleAvatar(
                backgroundColor: cs.primary,
                child: Text(t.reciter.name.characters.first,
                    style: TextStyle(color: cs.onPrimary)),
              ),
              title: Text('سورة ${t.surah.nameArabic}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.bold)),
              subtitle: Text(
                  '${t.reciter.name}${s.currentAyah != null ? ' • Ayah ${s.currentAyah}' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: cs.onPrimaryContainer)),
              trailing: IconButton(
                icon: Icon(s.playing ? Icons.pause_circle : Icons.play_circle,
                    size: 36, color: cs.onPrimaryContainer),
                onPressed: () =>
                    ref.read(quranPlayerProvider.notifier).toggle(),
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16)),
              child: LinearProgressIndicator(
                  value: progress, minHeight: 3),
            ),
          ],
        ),
      ),
    );
  }
}

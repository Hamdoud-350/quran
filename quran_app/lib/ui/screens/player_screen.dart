import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/audio/quran_player_controller.dart';
import '../../features/audio/ambient_mixer.dart';
import '../../data/local/favorites_store.dart';
import '../widgets/wave_visualizer.dart';
import '../widgets/ambient_mixer_sheet.dart';
import '../widgets/sleep_timer_dialog.dart';

/// Full player: animated wave, seek bar, next/prev (±10s),
/// Quran volume, ambient mixer, sleep timer, ayah repeat,
/// verse-by-verse list with live highlighting.
class PlayerScreen extends ConsumerWidget {
  final ScrollController scrollController;
  const PlayerScreen({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(quranPlayerProvider);
    final ctl = ref.read(quranPlayerProvider.notifier);
    final t = s.track;
    if (t == null) {
      return const Center(child: Text('Nothing playing'));
    }
    final cs = Theme.of(context).colorScheme;
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Reciter art placeholder (initial letter) — lock screen uses same title.
        Center(
          child: CircleAvatar(
            radius: 52,
            backgroundColor: cs.primaryContainer,
            child: Text(t.reciter.name.characters.first,
                style: TextStyle(fontSize: 44, color: cs.onPrimaryContainer)),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text('سورة ${t.surah.nameArabic}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
        ),
        Center(
          child: Text('${t.reciter.name} • ${t.moshaf.name}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  )),
        ),
        const SizedBox(height: 8),
        WaveVisualizer(playing: s.playing),
        // Seek bar
        Slider(
          min: 0,
          max: s.duration.inMilliseconds.toDouble().clamp(1, double.infinity),
          value: s.position.inMilliseconds
              .toDouble()
              .clamp(0, s.duration.inMilliseconds.toDouble().clamp(1, double.infinity)),
          onChanged: (v) => ctl.seek(Duration(milliseconds: v.toInt())),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(_fmt(s.position)), Text(_fmt(s.duration))],
        ),
        // Transport
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'Back 10s',
              icon: const Icon(Icons.replay_10),
              iconSize: 32,
              onPressed: () => ctl.seek(s.position - const Duration(seconds: 10)),
            ),
            const SizedBox(width: 8),
            FilledButton(
              style: FilledButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(20),
              ),
              onPressed: ctl.toggle,
              child: Icon(s.playing ? Icons.pause : Icons.play_arrow, size: 36),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Forward 10s',
              icon: const Icon(Icons.forward_10),
              iconSize: 32,
              onPressed: () => ctl.seek(s.position + const Duration(seconds: 10)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Repeat + sleep + ambient + favorite ayah
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            FilterChip(
              label: Text(switch (s.repeat) {
                RepeatMode.off => 'Repeat: Off',
                RepeatMode.surah => 'Repeat: Surah حلقة',
                RepeatMode.ayah => 'Repeat: Ayah تكرار',
              }),
              selected: s.repeat != RepeatMode.off,
              onSelected: (_) => ctl.cycleRepeat(),
            ),
            ActionChip(
              avatar: const Icon(Icons.bedtime_outlined, size: 18),
              label: Text(s.sleepIn != null && s.sleepIn! > Duration.zero
                  ? 'Sleep ${_fmt(s.sleepIn!)}'
                  : 'Sleep مؤقت'),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const SleepTimerDialog(),
              ),
            ),
            ActionChip(
              avatar: const Icon(Icons.nature_people_outlined, size: 18),
              label: const Text('Ambient طبيعة'),
              onPressed: () => showModalBottomSheet(
                context: context,
                showDragHandle: true,
                builder: (_) => const AmbientMixerSheet(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Quran volume
        Row(
          children: [
            const Icon(Icons.menu_book_outlined),
            Expanded(
              child: Slider(
                label: 'Quran volume',
                value: s.quranVolume,
                onChanged: ctl.setQuranVolume,
              ),
            ),
          ],
        ),
        Consumer(builder: (c, r, _) {
          final mix = r.watch(ambientMixerProvider);
          final active = mix.entries.where((e) => e.value > 0.01).length;
          return active == 0
              ? const SizedBox.shrink()
              : Text('$active ambient sound(s) mixing…',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onSurfaceVariant));
        }),
        const Divider(height: 32),
        // Ayah-by-ayah list with live highlight
        Row(
          children: [
            Text('Verses — الآيات',
                style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            if (s.timings.isEmpty)
              const Text('timing unavailable offline'),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(t.surah.versesCount, (i) {
          final n = i + 1;
          final active = s.currentAyah == n;
          return _AyahRow(
            surah: t.surah.number,
            ayah: n,
            active: active,
            onTap: () => ctl.seekToAyah(n),
          );
        }),
      ],
    );
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}

class _AyahRow extends ConsumerWidget {
  final int surah;
  final int ayah;
  final bool active;
  final VoidCallback onTap;
  const _AyahRow(
      {required this.surah,
      required this.ayah,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final key = '$surah:$ayah';
    final isFav = ref.watch(favoritesProvider).ayahs.contains(key);
    return Card(
      color: active ? cs.primaryContainer : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: active ? cs.primary : cs.surfaceContainerHighest,
          child: Text('$ayah',
              style: TextStyle(
                  color: active ? cs.onPrimary : cs.onSurfaceVariant,
                  fontWeight: FontWeight.bold)),
        ),
        title: Text('Ayah $ayah — الآية $ayah'),
        subtitle: Text(key),
        trailing: IconButton(
          icon: Icon(isFav ? Icons.bookmark : Icons.bookmark_outline),
          onPressed: () =>
              ref.read(favoritesProvider.notifier).toggleAyah(key),
        ),
        onTap: onTap,
      ),
    );
  }
}

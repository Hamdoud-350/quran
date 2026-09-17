import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/ambient_sound.dart';
import '../../features/audio/ambient_mixer.dart';

/// Bottom sheet: 6 nature loops each with its own volume slider.
/// Mixes under Quran audio. Quran volume lives on the Player screen.
class AmbientMixerSheet extends ConsumerWidget {
  const AmbientMixerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mix = ref.watch(ambientMixerProvider);
    final ctl = ref.read(ambientMixerProvider.notifier);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ambient Sounds — اصوات طبيعية',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('Mix nature under recitation. Each has its own volume.',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final s in AmbientSound.all)
                    _Row(
                      sound: s,
                      value: mix[s.id] ?? 0,
                      onChanged: (v) => ctl.setVolume(s.id, v),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your own loops as assets/audio/ambient/{rain,ocean,river,wind,birds,fire}.mp3',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final AmbientSound sound;
  final double value;
  final ValueChanged<double> onChanged;
  const _Row({required this.sound, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(sound.emoji, style: const TextStyle(fontSize: 26)),
        const SizedBox(width: 12),
        SizedBox(
          width: 110,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(sound.nameAr,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(sound.nameEn,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        Expanded(
          child: Slider(value: value, onChanged: onChanged),
        ),
      ],
    );
  }
}

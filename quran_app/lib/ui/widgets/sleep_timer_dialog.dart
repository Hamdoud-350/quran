import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/audio/quran_player_controller.dart';

/// Sleep timer dialog (مؤقت النوم): pause playback after N minutes.
class SleepTimerDialog extends ConsumerWidget {
  const SleepTimerDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const options = [5, 10, 15, 30, 45, 60, 90];
    return AlertDialog(
      title: const Text('Sleep Timer — مؤقت النوم'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final m in options)
            ListTile(
              dense: true,
              leading: const Icon(Icons.timer_outlined),
              title: Text('$m minutes'),
              onTap: () {
                ref
                    .read(quranPlayerProvider.notifier)
                    .startSleepTimer(Duration(minutes: m));
                Navigator.of(context).pop();
              },
            ),
          TextButton(
            onPressed: () {
              ref.read(quranPlayerProvider.notifier).cancelSleepTimer();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel timer'),
          ),
        ],
      ),
    );
  }
}

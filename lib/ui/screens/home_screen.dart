import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/quran_repository.dart';
import '../../data/models/surah.dart';
import '../widgets/now_playing_bar.dart';
import 'reciters_screen.dart';
import 'surah_list_screen.dart';
import 'downloads_screen.dart';
import 'favorites_screen.dart';

/// Root: SliverAppBar + smart search (AR/EN) + NavigationBar.
/// Player sheet persists above the bar via [NowPlayingBar].
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeState();
}

class _HomeState extends ConsumerState<HomeScreen> {
  int index = 0;
  String query = '';

  @override
  Widget build(BuildContext context) {
    final surahsAsync = ref.watch(surahsProvider);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('القرآن الكريم'),
            centerTitle: false,
            actions: [
              IconButton(
                tooltip: 'Light / Dark follows system',
                icon: const Icon(Icons.dark_mode_outlined),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Dark/Light follows system (Material You)')),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(68),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SearchBar(
                  hintText: 'Search surah — البقرة / Baqarah / 2',
                  leading: const Icon(Icons.search),
                  onChanged: (v) => setState(() => query = v),
                ),
              ),
            ),
          ),
          surahsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Network error: $e')),
            ),
            data: (all) {
              final filtered =
                  all.where((s) => s.matches(query)).toList();
              if (index != 0) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              return SliverList.builder(
                itemCount: filtered.length,
                itemBuilder: (c, i) => SurahTile(surah: filtered[i]),
              );
            },
          ),
          if (index == 1)
            const SliverFillRemaining(child: RecitersScreen(inTab: true)),
          if (index == 2)
            const SliverFillRemaining(child: DownloadsScreen(inTab: true)),
          if (index == 3)
            const SliverFillRemaining(child: FavoritesScreen(inTab: true)),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const NowPlayingBar(),
          NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (i) => setState(() => index = i),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book),
                  label: 'Surahs'),
              NavigationDestination(
                  icon: Icon(Icons.record_voice_over_outlined),
                  selectedIcon: Icon(Icons.record_voice_over),
                  label: 'Reciters'),
              NavigationDestination(
                  icon: Icon(Icons.download_outlined),
                  selectedIcon: Icon(Icons.download),
                  label: 'Offline'),
              NavigationDestination(
                  icon: Icon(Icons.favorite_outline),
                  selectedIcon: Icon(Icons.favorite),
                  label: 'Saved'),
            ],
          ),
        ],
      ),
    );
  }
}

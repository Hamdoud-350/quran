import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

enum DlStatus { idle, downloading, done, error }

class DlEntry {
  final String key; // "reciterId_moshafId_surah"
  final String label; // "سورة البقرة — مشاري العفاسي"
  final String url;
  final String path;
  final double progress;
  final DlStatus status;
  const DlEntry({
    required this.key,
    required this.label,
    required this.url,
    required this.path,
    this.progress = 0,
    this.status = DlStatus.idle,
  });

  DlEntry copyWith({double? progress, DlStatus? status, String? path}) =>
      DlEntry(
        key: key,
        label: label,
        url: url,
        path: path ?? this.path,
        progress: progress ?? this.progress,
        status: status ?? this.status,
      );
}

/// Downloads complete surahs to app documents for offline listening.
/// Files: <docs>/quran/<key>.mp3
class DownloadManager extends StateNotifier<Map<String, DlEntry>> {
  DownloadManager() : super({}) {
    _index();
  }

  final _dio = Dio();

  Future<Directory> get _dir async {
    final d = await getApplicationDocumentsDirectory();
    final q = Directory('${d.path}/quran');
    if (!await q.exists()) await q.create(recursive: true);
    return q;
  }

  Future<void> _index() async {
    try {
      final q = await _dir;
      final files = q.listSync().whereType<File>().where((f) => f.path.endsWith('.mp3'));
      final map = <String, DlEntry>{};
      for (final f in files) {
        final key = f.uri.pathSegments.last.replaceAll('.mp3', '');
        map[key] = DlEntry(
          key: key, label: key, url: '', path: f.path,
          progress: 1, status: DlStatus.done,
        );
      }
      if (map.isNotEmpty) state = {...state, ...map};
    } catch (_) {}
  }

  String keyFor(int reciterId, int moshafId, int surah) =>
      '${reciterId}_${moshafId}_$surah';

  Future<void> download({
    required int reciterId,
    required int moshafId,
    required int surah,
    required String label,
    required String url,
  }) async {
    final key = keyFor(reciterId, moshafId, surah);
    final q = await _dir;
    final path = '${q.path}/$key.mp3';
    if (await File(path).exists()) {
      state = {...state, key: DlEntry(key: key, label: label, url: url, path: path, progress: 1, status: DlStatus.done)};
      return;
    }
    state = {...state, key: DlEntry(key: key, label: label, url: url, path: path, progress: 0, status: DlStatus.downloading)};
    try {
      await _dio.download(url, path, onReceiveProgress: (got, total) {
        if (total > 0) {
          final e = state[key];
          if (e != null) {
            state = {...state, key: e.copyWith(progress: got / total)};
          }
        }
      });
      state = {...state, key: state[key]!.copyWith(progress: 1, status: DlStatus.done)};
    } catch (_) {
      state = {...state, key: state[key]!.copyWith(status: DlStatus.error)};
    }
  }

  Future<void> remove(String key) async {
    final e = state[key];
    if (e == null) return;
    try {
      final f = File(e.path);
      if (await f.exists()) await f.delete();
    } finally {
      final m = {...state}..remove(key);
      state = m;
    }
  }

  String? localPathFor(int reciterId, int moshafId, int surah) {
    final e = state[keyFor(reciterId, moshafId, surah)];
    return (e != null && e.status == DlStatus.done) ? e.path : null;
  }
}

final downloadManagerProvider =
    StateNotifierProvider<DownloadManager, Map<String, DlEntry>>((ref) {
  return DownloadManager();
});

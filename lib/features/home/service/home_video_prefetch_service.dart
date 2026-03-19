import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_application_1/features/home/model/home_video_clip.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class HomeVideoPrefetchService {
  HomeVideoPrefetchService._();

  static final HomeVideoPrefetchService instance = HomeVideoPrefetchService._();

  static const int _maxWarmupClips = 2;
  static const int _maxCachedFiles = 3;
  static const int _maxPrefetchBytes = 18 * 1024 * 1024;
  static const String _cacheFolderName = 'home_video_prefetch';

  final http.Client _client = http.Client();
  final Map<String, Future<String?>> _activeDownloads =
      <String, Future<String?>>{};

  Future<void> warmUpClips(List<HomeVideoClip> clips) async {
    final warmedUrls = <String>{};
    for (final clip in clips) {
      final videoUrl = clip.videoUrl.trim();
      if (!videoUrl.startsWith('http') || !warmedUrls.add(videoUrl)) {
        continue;
      }

      unawaited(prefetchVideo(videoUrl));
      if (warmedUrls.length >= _maxWarmupClips) {
        break;
      }
    }
  }

  Future<String> resolvePlayablePath(
    String sourcePath, {
    Duration warmupWait = const Duration(milliseconds: 350),
  }) async {
    final normalizedSourcePath = sourcePath.trim();
    if (!normalizedSourcePath.startsWith('http')) {
      return normalizedSourcePath;
    }

    final cachedPath = await getCachedPath(normalizedSourcePath);
    if (cachedPath != null) {
      return cachedPath;
    }

    try {
      final warmedPath = await prefetchVideo(
        normalizedSourcePath,
      ).timeout(warmupWait);
      if (warmedPath != null && warmedPath.isNotEmpty) {
        return warmedPath;
      }
    } catch (_) {
      // Fall back to the remote URL when warmup is still in progress.
    }

    return normalizedSourcePath;
  }

  Future<String?> getCachedPath(String sourcePath) async {
    final normalizedSourcePath = sourcePath.trim();
    if (!normalizedSourcePath.startsWith('http')) {
      return normalizedSourcePath;
    }

    final cacheFile = await _cacheFileForUrl(normalizedSourcePath);
    if (await cacheFile.exists()) {
      return cacheFile.path;
    }

    return null;
  }

  Future<String?> prefetchVideo(String sourcePath) async {
    final normalizedSourcePath = sourcePath.trim();
    if (!normalizedSourcePath.startsWith('http')) {
      return normalizedSourcePath;
    }

    final cachedPath = await getCachedPath(normalizedSourcePath);
    if (cachedPath != null) {
      return cachedPath;
    }

    final inFlight = _activeDownloads[normalizedSourcePath];
    if (inFlight != null) {
      return inFlight;
    }

    final download = _downloadToCache(normalizedSourcePath);
    _activeDownloads[normalizedSourcePath] = download;
    download.whenComplete(() {
      _activeDownloads.remove(normalizedSourcePath);
    });
    return download;
  }

  Future<String?> _downloadToCache(String sourcePath) async {
    final request = http.Request('GET', Uri.parse(sourcePath));
    final response = await _client.send(request);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      await response.stream.drain<void>();
      return null;
    }

    final announcedLength = response.contentLength;
    if (announcedLength != null && announcedLength > _maxPrefetchBytes) {
      await response.stream.drain<void>();
      return null;
    }

    final cacheFile = await _cacheFileForUrl(sourcePath);
    if (!await cacheFile.parent.exists()) {
      await cacheFile.parent.create(recursive: true);
    }

    if (await cacheFile.exists()) {
      return cacheFile.path;
    }

    IOSink? sink;
    var writtenBytes = 0;

    try {
      sink = cacheFile.openWrite();
      final activeSink = sink;
      await for (final chunk in response.stream) {
        writtenBytes += chunk.length;
        if (writtenBytes > _maxPrefetchBytes) {
          await activeSink.flush();
          await activeSink.close();
          sink = null;
          if (await cacheFile.exists()) {
            await cacheFile.delete();
          }
          return null;
        }
        activeSink.add(chunk);
      }

      await activeSink.flush();
      await activeSink.close();
      sink = null;

      await _trimCache();
      return cacheFile.path;
    } catch (_) {
      await sink?.flush();
      await sink?.close();
      if (await cacheFile.exists()) {
        await cacheFile.delete();
      }
      return null;
    }
  }

  Future<File> _cacheFileForUrl(String sourcePath) async {
    final cacheDirectory = await _cacheDirectory();
    final extension = _resolveExtension(sourcePath);
    final fileName = '${_hashSourcePath(sourcePath)}.$extension';
    return File('${cacheDirectory.path}/$fileName');
  }

  Future<Directory> _cacheDirectory() async {
    final rootDirectory = await getTemporaryDirectory();
    return Directory('${rootDirectory.path}/$_cacheFolderName');
  }

  Future<void> _trimCache() async {
    final cacheDirectory = await _cacheDirectory();
    if (!await cacheDirectory.exists()) {
      return;
    }

    final entries = await cacheDirectory
        .list()
        .where((entry) => entry is File)
        .cast<File>()
        .toList();
    if (entries.length <= _maxCachedFiles) {
      return;
    }

    entries.sort((a, b) {
      final aTime = a.statSync().modified;
      final bTime = b.statSync().modified;
      return aTime.compareTo(bTime);
    });

    final excessEntries = entries.length - _maxCachedFiles;
    for (var index = 0; index < excessEntries; index++) {
      try {
        await entries[index].delete();
      } catch (_) {
        // Ignore cache cleanup failures.
      }
    }
  }

  String _resolveExtension(String sourcePath) {
    final uri = Uri.tryParse(sourcePath);
    if (uri == null || uri.pathSegments.isEmpty) {
      return 'mp4';
    }

    final lastSegment = uri.pathSegments.last;
    final dotIndex = lastSegment.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == lastSegment.length - 1) {
      return 'mp4';
    }

    final extension = lastSegment.substring(dotIndex + 1).toLowerCase();
    if (extension.isEmpty) {
      return 'mp4';
    }

    return extension;
  }

  String _hashSourcePath(String sourcePath) {
    var hash = 5381;
    for (final codeUnit in utf8.encode(sourcePath)) {
      hash = ((hash << 5) + hash + codeUnit) & 0x7fffffff;
    }
    return hash.toRadixString(16);
  }
}

import 'package:flutter/foundation.dart';
import 'package:video_compress/video_compress.dart';

class PreparedVideoUpload {
  const PreparedVideoUpload({
    required this.bytes,
    required this.fileName,
  });

  final Uint8List bytes;
  final String fileName;
}

class VideoUploadPrepareService {
  VideoUploadPrepareService._();

  static final VideoUploadPrepareService instance =
      VideoUploadPrepareService._();

  Future<PreparedVideoUpload> prepareForUpload({
    required String filePath,
    required String fileName,
    required Uint8List fallbackBytes,
  }) async {
    final normalizedFileName = fileName.trim();
    final extension = _extensionOf(normalizedFileName);

    if (!_shouldTranscode(extension: extension, filePath: filePath)) {
      return PreparedVideoUpload(
        bytes: fallbackBytes,
        fileName: normalizedFileName,
      );
    }

    MediaInfo? mediaInfo;
    try {
      mediaInfo = await VideoCompress.compressVideo(
        filePath,
        quality: VideoQuality.DefaultQuality,
        deleteOrigin: false,
        includeAudio: true,
        frameRate: 30,
      );

      final compressedFile = mediaInfo?.file;
      if (compressedFile == null || !await compressedFile.exists()) {
        throw const VideoUploadPrepareException(
          'Unable to convert the video into a supported format.',
        );
      }

      final compressedBytes = await compressedFile.readAsBytes();
      final mp4FileName = _replaceExtension(normalizedFileName, 'mp4');
      return PreparedVideoUpload(
        bytes: compressedBytes,
        fileName: mp4FileName,
      );
    } catch (_) {
      final isProblematicFormat = extension == 'mov' || extension == 'm4v';
      if (isProblematicFormat) {
        throw const VideoUploadPrepareException(
          'This video must be converted to MP4 before upload, but conversion failed.',
        );
      }

      return PreparedVideoUpload(
        bytes: fallbackBytes,
        fileName: normalizedFileName,
      );
    } finally {
      try {
        await VideoCompress.deleteAllCache();
      } catch (_) {
        // Ignore cache cleanup failures.
      }
    }
  }

  bool _shouldTranscode({
    required String extension,
    required String filePath,
  }) {
    if (kIsWeb || filePath.trim().isEmpty) {
      return false;
    }

    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return false;
    }

    return extension == 'mov' ||
        extension == 'm4v' ||
        extension == 'avi' ||
        extension == 'webm';
  }

  String _extensionOf(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == fileName.length - 1) {
      return '';
    }
    return fileName.substring(dotIndex + 1).toLowerCase();
  }

  String _replaceExtension(String fileName, String newExtension) {
    final dotIndex = fileName.lastIndexOf('.');
    final baseName = dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;
    final normalizedBaseName = baseName.trim().isEmpty ? 'clip' : baseName;
    return '$normalizedBaseName.$newExtension';
  }
}

class VideoUploadPrepareException implements Exception {
  const VideoUploadPrepareException(this.message);

  final String message;

  @override
  String toString() => message;
}

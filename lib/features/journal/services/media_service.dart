import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:uuid/uuid.dart';
import '../model/journal_entry.dart';

class MediaService {
  final ImagePicker _picker = ImagePicker();
  final _uuid = const Uuid();

  // Medya seçme metodları
  Future<MediaItem?> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;

    final String path = await _saveMediaFile(image.path, MediaType.image);
    return MediaItem(
      path: path,
      type: MediaType.image,
    );
  }

  Future<MediaItem?> pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video == null) return null;

    final String path = await _saveMediaFile(video.path, MediaType.video);
    final String? thumbnailPath = await _generateVideoThumbnail(path);

    return MediaItem(
      path: path,
      type: MediaType.video,
      thumbnailPath: thumbnailPath,
    );
  }

  Future<MediaItem?> pickAudio() async {
    final XFile? audio = await _picker.pickMedia();
    if (audio == null) return null;

    final String path = await _saveMediaFile(audio.path, MediaType.audio);
    return MediaItem(
      path: path,
      type: MediaType.audio,
    );
  }

  // Medya dosyasını kaydetme
  Future<String> _saveMediaFile(String sourcePath, MediaType type) async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String mediaDir = '${appDir.path}/media';
    await Directory(mediaDir).create(recursive: true);

    final String extension = sourcePath.split('.').last;
    final String fileName = '${_uuid.v4()}.$extension';
    final String targetPath = '$mediaDir/$fileName';

    await File(sourcePath).copy(targetPath);
    return targetPath;
  }

  // Video için küçük resim oluşturma
  Future<String?> _generateVideoThumbnail(String videoPath) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String thumbnailsDir = '${appDir.path}/thumbnails';
      await Directory(thumbnailsDir).create(recursive: true);

      final String thumbnailPath = '$thumbnailsDir/${_uuid.v4()}.jpg';
      await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: thumbnailPath,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 200,
        quality: 75,
      );

      return thumbnailPath;
    } catch (e) {
      if (kDebugMode) {
        print('Thumbnail oluşturma hatası: $e');
      }
      return null;
    }
  }

  // Medya dosyasını silme
  Future<void> deleteMedia(MediaItem mediaItem) async {
    try {
      final file = File(mediaItem.path);
      if (await file.exists()) {
        await file.delete();
      }

      if (mediaItem.thumbnailPath != null) {
        final thumbnailFile = File(mediaItem.thumbnailPath!);
        if (await thumbnailFile.exists()) {
          await thumbnailFile.delete();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Medya silme hatası: $e');
      }
    }
  }
} 
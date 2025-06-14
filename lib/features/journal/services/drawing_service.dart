import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:math';

class DrawingService {
  Future<String?> drawingToBase64(
    List<Path> paths,
    List<Color> pathColors,
    List<double> pathWidths,
    Size size,
  ) async {
    try {
      // Yeni bir resim oluştur
      final image = img.Image(
        width: size.width.toInt(),
        height: size.height.toInt(),
      );

      // Her çizgiyi resme çiz
      for (int i = 0; i < paths.length; i++) {
        final path = paths[i];
        final color = pathColors[i];
        final width = pathWidths[i];

        // Path'i noktalara dönüştür
        final pathMetrics = path.computeMetrics();
        for (final metric in pathMetrics) {
          for (double distance = 0; distance < metric.length; distance += 1) {
            final tangent = metric.getTangentForOffset(distance);
            if (tangent != null) {
              final x = tangent.position.dx.toInt();
              final y = tangent.position.dy.toInt();
              
              // Çizgi kalınlığı için çevresindeki noktaları da boya
              for (int dx = -width.toInt(); dx <= width.toInt(); dx++) {
                for (int dy = -width.toInt(); dy <= width.toInt(); dy++) {
                  final nx = x + dx;
                  final ny = y + dy;
                  if (nx >= 0 && nx < image.width && ny >= 0 && ny < image.height) {
                    final distance = sqrt(dx * dx + dy * dy);
                    if (distance <= width) {
                      image.setPixelRgba(
                        nx,
                        ny,
                        color.red,
                        color.green,
                        color.blue,
                        color.alpha,
                      );
                    }
                  }
                }
              }
            }
          }
        }
      }

      // Resmi PNG formatına dönüştür
      final pngBytes = img.encodePng(image);
      return base64Encode(pngBytes);
    } catch (e) {
      if (kDebugMode) {
        print('Çizim kaydedilirken hata oluştu: $e');
      }
      return null;
    }
  }

  Future<Image> base64ToDrawing(String base64Data) async {
    try {
      final bytes = base64Decode(base64Data);
      final image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('Resim çözümlenemedi');
      }

      return Image.memory(
        Uint8List.fromList(bytes),
        fit: BoxFit.contain,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Çizim yüklenirken hata oluştu: $e');
      }
      // Hata durumunda boş bir resim döndür
      final emptyImage = img.Image(width: 1, height: 1);
      return Image.memory(
        Uint8List.fromList(img.encodePng(emptyImage)),
        fit: BoxFit.contain,
      );
    }
  }

  Future<String?> saveDrawingToFile(String base64Data) async {
    try {
      final bytes = base64Decode(base64Data);
      final appDir = await getApplicationDocumentsDirectory();
      final drawingsDir = Directory('${appDir.path}/drawings');
      if (!await drawingsDir.exists()) {
        await drawingsDir.create(recursive: true);
      }

      final fileName = 'drawing_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${drawingsDir.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      if (kDebugMode) {
        print('Çizim dosyaya kaydedilirken hata oluştu: $e');
      }
      return null;
    }
  }

  Future<void> deleteDrawing(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Çizim dosyası silinirken hata oluştu: $e');
      }
    }
  }

  Future<Uint8List?> resizeDrawing(String base64Data, int maxWidth, int maxHeight) async {
    try {
      final bytes = base64Decode(base64Data);
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      final resized = img.copyResize(
        image,
        width: maxWidth,
        height: maxHeight,
        interpolation: img.Interpolation.linear,
      );

      return Uint8List.fromList(img.encodePng(resized));
    } catch (e) {
      if (kDebugMode) {
        print('Çizim yeniden boyutlandırılırken hata oluştu: $e');
      }
      return null;
    }
  }
} 
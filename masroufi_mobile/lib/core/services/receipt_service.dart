import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ReceiptService {
  static final ImagePicker _picker = ImagePicker();

  /// Captures an image from camera or picks from gallery,
  /// compresses it with optimal readability parameters (1800x2400, 82% quality),
  /// and saves a persistent copy inside the app's secure documents folder.
  static Future<String?> pickAndSaveReceipt({required bool fromCamera}) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 2400,
        imageQuality: 82,
      );

      if (picked == null) return null;

      final appDir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory('${appDir.path}/receipts');
      if (!await receiptsDir.exists()) {
        await receiptsDir.create(recursive: true);
      }

      final ext = picked.path.contains('.') ? picked.path.substring(picked.path.lastIndexOf('.')) : '.jpg';
      final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}$ext';
      final targetPath = '${receiptsDir.path}/$fileName';

      final savedFile = await File(picked.path).copy(targetPath);
      return savedFile.path;
    } catch (e) {
      debugPrint('Error picking and saving receipt: $e');
      return null;
    }
  }

  /// Deletes the physical receipt image file from disk
  static Future<void> deleteReceiptFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting receipt file: $e');
    }
  }

  /// Calculates total disk space consumed by receipts in MB
  static Future<double> getTotalReceiptsSizeMB() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory('${appDir.path}/receipts');
      if (!await receiptsDir.exists()) return 0.0;
      int totalBytes = 0;
      await for (final file in receiptsDir.list(recursive: false)) {
        if (file is File) {
          totalBytes += await file.length();
        }
      }
      return totalBytes / (1024 * 1024);
    } catch (_) {
      return 0.0;
    }
  }
}

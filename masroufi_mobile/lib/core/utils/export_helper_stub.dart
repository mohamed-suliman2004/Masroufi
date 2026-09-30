import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

Future<void> saveAndLaunchFile(List<int> bytes, String fileName) async {
  try {
    Directory? dir;
    if (Platform.isAndroid) {
      dir = Directory('/storage/emulated/0/Download');
      if (!await dir.exists()) {
        dir = await getExternalStorageDirectory();
      }
    } else if (Platform.isIOS) {
      dir = await getApplicationDocumentsDirectory();
    }

    if (dir != null && await dir.exists()) {
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
    }
  } catch (_) {}

  await Printing.sharePdf(bytes: Uint8List.fromList(bytes), filename: fileName);
}

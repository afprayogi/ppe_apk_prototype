import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImageStorageService {
  static Future<String> saveScanImage(Uint8List bytes, String recordId) async {
    final dir  = await getApplicationDocumentsDirectory();
    final scan = Directory(p.join(dir.path, 'scan_images'));
    if (!scan.existsSync()) scan.createSync(recursive: true);

    final file = File(p.join(scan.path, '$recordId.png'));
    await file.writeAsBytes(bytes);
    return file.path;
  }

  static Future<void> deleteImage(String? path) async {
    if (path == null) return;
    final f = File(path);
    if (f.existsSync()) f.deleteSync();
  }
}

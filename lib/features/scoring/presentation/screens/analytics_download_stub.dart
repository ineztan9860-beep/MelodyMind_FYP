// Stub implementation for non-web platforms (Android, iOS, Windows, etc.)
// On native platforms we save to the app's documents directory.
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Saves [content] as a text file named [fileName] in the Downloads directory
/// on native platforms.
Future<void> downloadTextFile(String content, String fileName) async {
  try {
    Directory? dir;
    if (Platform.isAndroid || Platform.isIOS) {
      dir = await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
    } else {
      dir = await getApplicationDocumentsDirectory();
    }
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(content);
    // ignore: avoid_print
    print('Report saved to: ${file.path}');
  } catch (e) {
    // ignore: avoid_print
    print('Failed to save report: $e');
  }
}

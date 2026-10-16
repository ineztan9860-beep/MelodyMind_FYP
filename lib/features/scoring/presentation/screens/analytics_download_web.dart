// Web implementation of report download using package:web + dart:js_interop
import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Downloads [content] as a text file named [fileName] on Web.
void downloadTextFile(String content, String fileName) {
  final bytes = content.codeUnits;
  final jsArray = bytes.map((b) => b.toJS).toList().toJS;
  final blob = web.Blob([jsArray].toJS);
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}

import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<bool> copyText(String text) async {
  try {
    await web.window.navigator.clipboard.writeText(text).toDart;
    return true;
  } catch (_) {
    // The modern API requires HTTPS (localhost is the only HTTP exception).
  }

  web.HTMLTextAreaElement? textArea;
  try {
    textArea = web.HTMLTextAreaElement()
      ..value = text
      ..readOnly = true;
    textArea.style
      ..position = 'fixed'
      ..left = '-10000px'
      ..top = '0'
      ..opacity = '0';
    web.document.body?.append(textArea);
    textArea
      ..focus()
      ..select();
    return web.document.execCommand('copy');
  } catch (_) {
    return false;
  } finally {
    textArea?.remove();
  }
}

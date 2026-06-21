import 'clipboard_service_stub.dart'
    if (dart.library.js_interop) 'clipboard_service_web.dart' as implementation;

Future<bool> copyText(String text) => implementation.copyText(text);

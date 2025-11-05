import 'package:flutter/foundation.dart';

class Log {
  static void i(String message, {String tag = 'APP'}) {
    final now = DateTime.now().toIso8601String();
    debugPrint('[$now][$tag] $message');
  }
}

import 'package:flutter/foundation.dart';

/// Target execution platform for the PolyCode engine runtime.
enum PolyPlatform {
  web,
  android,
  ios,
  macos,
  linux,
  windows;

  static PolyPlatform get current {
    if (kIsWeb) return PolyPlatform.web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return PolyPlatform.android;
      case TargetPlatform.iOS:
        return PolyPlatform.ios;
      case TargetPlatform.macOS:
        return PolyPlatform.macos;
      case TargetPlatform.linux:
        return PolyPlatform.linux;
      case TargetPlatform.windows:
        return PolyPlatform.windows;
      case TargetPlatform.fuchsia:
        return PolyPlatform.linux;
    }
  }
}

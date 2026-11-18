import 'dart:io' show Platform;

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';

/// Windows builds use BDW_HIDE_ON_STARTUP — window must be shown from Dart.
void bootstrapWindowsAppWindow() {
  if (!Platform.isWindows) return;

  doWhenWindowReady(() {
    const defaultSize = Size(1280, 720);
    appWindow.minSize = const Size(960, 640);
    appWindow.size = defaultSize;
    appWindow.alignment = Alignment.center;
    appWindow.title = 'Dental Flow';
    appWindow.show();
  });
}
import 'dart:ui';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NavigationController extends GetxController {
  @override
  void onInit() {
    doWhenWindowReady(() {
      appWindow.title = 'Dental Flow';
      final ctx = Get.context;
      if (ctx != null) {
        final screenSize = MediaQuery.sizeOf(ctx);
        if (screenSize.width > 0 && screenSize.height > 0) {
          appWindow.minSize = Size(
            screenSize.width.clamp(960, 3840),
            screenSize.height.clamp(640, 2160),
          );
          appWindow.size = screenSize;
          appWindow.alignment = Alignment.center;
        }
      }
      appWindow.show();
    });

    super.onInit();
  }

  final selectedIndex = 0.obs;
  final showNotificationsPanel = false.obs;

  void select(int index) => selectedIndex.value = index;

  void toggleNotificationsPanel() =>
      showNotificationsPanel.value = !showNotificationsPanel.value;

  void closeNotificationsPanel() => showNotificationsPanel.value = false;

  void openNotificationsPanel() => showNotificationsPanel.value = true;
}

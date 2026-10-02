import 'dart:ui';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NavigationController extends GetxController {
  @override
  void onInit() {
    doWhenWindowReady(() {
      final Size screenSize = MediaQuery.of(Get.context!).size;

      appWindow.minSize = Size(screenSize.width, screenSize.height);

      appWindow.size = Size(screenSize.width, screenSize.height);
      appWindow.alignment = Alignment.center;
      appWindow.title = "Dental Flow";
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

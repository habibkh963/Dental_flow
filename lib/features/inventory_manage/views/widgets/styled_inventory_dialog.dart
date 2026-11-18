import 'package:flutter/material.dart';

import '../../../shared/widgets/app_dialog_shell.dart';

/// غلاف حوار موحّد للمخزون والنفقات (نفس أسلوب الإجراءات السريعة).
Widget styledInventoryDialog({
  required String title,
  required Widget body,
  required List<Widget> actions,
  double width = 440,
}) {
  return Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
    child: AppDialogFrame(
      title: title,
      width: width,
      body: body,
      actions: actions,
    ),
  );
}
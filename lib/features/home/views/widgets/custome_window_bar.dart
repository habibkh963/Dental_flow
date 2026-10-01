import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:dental_managment_system/assets/assets.dart';
import 'package:dental_managment_system/core/colors.dart';
import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomWindowBar extends StatelessWidget {
  const CustomWindowBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50.h,
      decoration: BoxDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: WindowTitleBarBox(child: MoveWindow(child: SizedBox())),
          ),

          WindowTitleBarBox(
            child: CircleAvatar(
              backgroundColor: Colors.white,

              child: MinimizeWindowButton(
                animate: true,

                colors: WindowButtonColors(
                  iconNormal: AppColors.approvedColor,
                  mouseOver: Colors.transparent,
                  normal: Colors.transparent,
                ),
              ),
            ),
          ),
          WindowTitleBarBox(
            child: CircleAvatar(
              backgroundColor: Colors.white,

              child: InkWell(
                onTap: () {
                  CloseWindowButton().onPressed!();
                },
                child: Icon(
                  Icons.power_settings_new_rounded,
                  color: Colors.red,
                ),
              ),
            ),
          ),
          WindowTitleBarBox(
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: MaximizeWindowButton(
                animate: true,

                colors: WindowButtonColors(
                  iconNormal: AppColors.approvedColor,
                  mouseOver: Colors.transparent,
                  normal: Colors.transparent,
                ),
              ),
            ),
          ),

          Expanded(child: WindowTitleBarBox(child: MoveWindow())),
        ],
      ),
    );
  }
}

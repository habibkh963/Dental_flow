import 'package:dental_managment_system/assets/assets.dart';
import 'package:dental_managment_system/core/colors.dart';
import 'package:dental_managment_system/features/home/views/widgets/custome_window_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../home/views/widgets/app_shell.dart';
import '../controllers/auth_controller.dart';

class PasswordScreen extends StatelessWidget {
  final TextEditingController passController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        color: AppColors.mainColor.withAlpha(50),
        child: Column(
          children: [
            CustomWindowBar(),
            Expanded(
              child: Image.asset(Assets.of(context).logo_png, width: 300.w),
            ),
            Expanded(
              flex: 2,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(50),
                  width: 800.w,

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Unlock Now',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () {
                          final controller = Get.find<AuthController>();
                          if (controller.checkPassword(passController.text)) {
                            Get.offAll(() => AppShell()); // شاشة رئيسية
                          } else {
                            Get.snackbar(
                              'Error',
                              'Wrong password',
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                          }
                        },
                        child: Text('Unlock', style: GoogleFonts.poppins()),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

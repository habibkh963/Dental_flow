import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/colors.dart';
import '../../../services/doctor_activation_service.dart';
import '../../home/views/widgets/app_shell.dart';
import '../controllers/auth_controller.dart';
import '../screens/doctor_activation_screen.dart';
import '../screens/password_creen.dart';

/// يحدد الشاشة الأولى: تفعيل محلي (مرة واحدة عبر API) → كلمة مرور → التطبيق.
class AppStartupGate extends StatelessWidget {
  const AppStartupGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Obx(() {
      if (!auth.isReady.value) {
        return const _StartupSplash();
      }

      if (!DoctorActivationService.instance.isActivationComplete) {
        return const DoctorActivationScreen();
      }

      if (auth.hasPassword()) {
        return PasswordScreen();
      }

      return AppShell();
    });
  }
}

class _StartupSplash extends StatelessWidget {
  const _StartupSplash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.mainColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Dental Flow',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.mainColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// بعد التفعيل اليدوي — إعادة فتح البوابة.
void navigateAfterActivation() {
  Get.offAll(() => const AppStartupGate());
}
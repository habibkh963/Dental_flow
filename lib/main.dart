import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';
import 'core/colors.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/screens/password_creen.dart';
import 'features/home/views/widgets/app_shell.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.instance.init();
  //
  runApp(DentalClinic());
}

class DentalClinic extends StatelessWidget {
  DentalClinic({super.key});
  final authController = Get.put(AuthController());

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2A9D8F)),
      useMaterial3: true,
    );
    final textTheme = GoogleFonts.poppinsTextTheme(baseTheme.textTheme);
    final theme = baseTheme.copyWith(
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(centerTitle: true),
    );

    return ScreenUtilInit(
      designSize: const Size(1920, 1080),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: 'Dental Clinic Manager',
          theme: theme,
          debugShowCheckedModeBanner: false,
          home: authController.hasPassword() ? PasswordScreen() : AppShell(),
        );
      },
    );
  }
}

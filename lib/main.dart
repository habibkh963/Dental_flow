import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/screens/password_creen.dart';
import 'features/home/views/widgets/app_shell.dart';
import 'features/inventory_manage/controller/daily_inventory_controller.dart';
import 'services/app_notification_service.dart';
import 'services/database_service.dart';

List<String> arabicIndex = [
  'ا',
  'ب',
  'ت',
  'ث',
  'ج',
  'ح',
  'خ',
  'د',
  'ذ',
  'ر',
  'ز',
  'س',
  'ش',
  'ص',
  'ض',
  'ط',
  'ظ',
  'ع',
  'غ',
  'ف',
  'ق',
  'ك',
  'ل',
  'م',
  'ن',
  'ه',
  'و',
  'ي',
];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.instance.init();
  await AppNotificationService.instance.initialize();
  Get.put(DailyInventoryController());
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
    initializeDateFormatting('ar'); // أو 'en', 'fr' حسب التطبيق

    return ScreenUtilInit(
      designSize: const Size(1920, 1080),
      minTextAdapt: true,
      splitScreenMode: true,

      builder: (context, child) {
        return GetMaterialApp(
          locale: const Locale('ar'),

          // supportedLocales: const [Locale('ar'), Locale('en')],
          title: 'Dental Clinic Manager',
          theme: theme,
          debugShowCheckedModeBanner: false,
          home: authController.hasPassword() ? PasswordScreen() : AppShell(),
        );
      },
    );
  }
}

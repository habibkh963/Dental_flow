import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/windows_app_window.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/widgets/app_startup_gate.dart';
import 'features/inventory_manage/controller/daily_inventory_controller.dart';
import 'features/settings_manage/controllers/app_currency_controller.dart';
import 'features/settings_manage/controllers/treatment_catalog_controller.dart';
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
  await GetStorage.init();
  await initializeDateFormatting('ar');
  await DatabaseService.instance.init();
  await AppNotificationService.instance.initialize();
  Get.put(DailyInventoryController());
  Get.put(TreatmentCatalogController(), permanent: true);
  Get.put(AppCurrencyController(), permanent: true);
  runApp(DentalClinic());
  bootstrapWindowsAppWindow();
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
          locale: const Locale('ar'),
          supportedLocales: const [
            Locale('ar'),
            Locale('en'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          title: 'Dental Clinic Manager',
          theme: theme,
          debugShowCheckedModeBanner: false,
          home: const AppStartupGate(),
        );
      },
    );
  }
}

import 'dart:developer';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class AuthController extends GetxController {
  RxString? passwordRx = ''.obs; // أو Load من DB
  var storage;

  @override
  void onInit() async {
    await GetStorage.init();
    storage = GetStorage();
    log('', name: '${storage.read('app_password')}');

    super.onInit();
    await loadPassword();
  }

  Future<void> loadPassword() async {
    var password = await storage.read('app_password');
    log('Loaded password: $password');
    passwordRx?.value = password;
  }

  bool checkPassword(String input) {
    return passwordRx?.value == input;
  }

  bool hasPassword() =>
      passwordRx?.value != null && passwordRx!.value.isNotEmpty;
}

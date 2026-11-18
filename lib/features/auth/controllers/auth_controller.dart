import 'dart:developer';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class AuthController extends GetxController {
  final _storage = GetStorage();
  final isReady = false.obs;
  late final RxString passwordRx;

  @override
  void onInit() {
    super.onInit();
    final stored = _storage.read('app_password');
    passwordRx = (stored?.toString() ?? '').obs;
    log('Loaded password: ${passwordRx.value.isNotEmpty ? '(set)' : '(empty)'}',
        name: 'AuthController');
    isReady.value = true;
  }

  bool checkPassword(String input) => passwordRx.value == input;

  bool hasPassword() => passwordRx.value.isNotEmpty;

  Future<void> setPassword(String value) async {
    passwordRx.value = value;
    await _storage.write('app_password', value);
  }
}
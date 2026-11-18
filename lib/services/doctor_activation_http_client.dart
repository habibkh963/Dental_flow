import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Windows desktop client with timeouts + User-Agent (some hosts drop default UA).
http.Client createDoctorActivationHttpClient() {
  if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
    return http.Client();
  }

  final httpClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 25)
    ..idleTimeout = const Duration(seconds: 25);

  return IOClient(httpClient);
}

const kDoctorActivationUserAgent = 'DentalFlow/1.0 (Windows; Flutter)';
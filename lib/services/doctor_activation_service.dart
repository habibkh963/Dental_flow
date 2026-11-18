import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

import '../core/doctor_activation_config.dart';
import 'doctor_activation_http_client.dart';

class DoctorActivationService {
  DoctorActivationService._();
  static final instance = DoctorActivationService._();

  static const _storageKey = 'doctor_activation_verified';
  static const _tokenKey = 'doctor_activation_token';
  static const _apiUrlKey = 'doctor_activation_api_url';
  static const _logName = 'DoctorActivationHTTP';

  final _box = GetStorage();
  http.Client? _client;

  /// @deprecated Use [isActivationComplete].
  bool get isActivated => isActivationComplete;

  String? get lastActivatedName =>
      _box.read('doctor_activation_name')?.toString();

  String? get storedToken => _box.read(_tokenKey)?.toString();

  /// تفعيل محلي: تم التحقق عبر API مرة واحدة + اسم ورمز محفوظان.
  bool get isActivationComplete {
    if (_box.read(_storageKey) != true) return false;
    final name = lastActivatedName?.trim() ?? '';
    final token = storedToken?.trim() ?? '';
    return name.isNotEmpty && token.isNotEmpty;
  }

  Future<void> clearActivation() async {
    await _box.remove(_storageKey);
    await _box.remove('doctor_activation_name');
    await _box.remove(_tokenKey);
    await _box.remove('doctor_activation_at');
    _log('Activation cleared');
  }

  String get apiUrl =>
      _box.read(_apiUrlKey)?.toString().trim().isNotEmpty == true
          ? _box.read(_apiUrlKey).toString().trim()
          : kDoctorActivationApiUrl;

  Future<void> setApiUrl(String url) async {
    final trimmed = url.trim();
    if (trimmed.isNotEmpty) {
      await _box.write(_apiUrlKey, trimmed);
    }
  }

  void _log(String message) {
    developer.log(message, name: _logName);
    if (kDebugMode) {
      debugPrint('[$_logName] $message');
    }
  }

  Future<void> markActivated({
    required String name,
    required String token,
  }) async {
    await _box.write(_storageKey, true);
    await _box.write('doctor_activation_name', name.trim());
    await _box.write(_tokenKey, token.trim());
    await _box.write(
      'doctor_activation_at',
      DateTime.now().toIso8601String(),
    );
  }

  /// إعادة التحقق مع الخادم يدوياً (الإعدادات) — لا يُستدعى عند كل فتح.
  Future<({bool ok, String message})> verifyStoredActivation() async {
    if (!isActivationComplete) {
      return (ok: false, message: 'يلزم تفعيل التطبيق');
    }
    return verifyWithServer(
      name: lastActivatedName!,
      token: storedToken!,
    );
  }

  /// للتطوير فقط عند تعطل خادم SSL.
  Future<void> skipActivationForDebug() async {
    assert(kDebugMode);
    await markActivated(name: 'debug_skip', token: 'debug_skip_token');
    _log('DEBUG: activation skipped locally');
  }

  Future<({bool ok, String message})> verifyWithServer({
    required String name,
    required String token,
    String? apiUrlOverride,
  }) async {
    final trimmedName = name.trim();
    final trimmedToken = token.trim();

    if (trimmedName.isEmpty) {
      return (ok: false, message: 'أدخل اسم الطبيب');
    }
    if (trimmedToken.isEmpty) {
      return (ok: false, message: 'أدخل رمز التفعيل (token)');
    }

    final url = (apiUrlOverride?.trim().isNotEmpty == true)
        ? apiUrlOverride!.trim()
        : apiUrl;
    await setApiUrl(url);

    final payload = {'name': trimmedName, 'token': trimmedToken};
    final body = jsonEncode(payload);

    Uri uri;
    try {
      uri = Uri.parse(url);
      if (!uri.hasScheme || uri.host.isEmpty) {
        return (ok: false, message: 'رابط الخادم غير صالح');
      }
    } catch (e) {
      return (ok: false, message: 'رابط الخادم غير صالح: $e');
    }

    _log('POST $uri');
    _log('Request headers: Content-Type, User-Agent');
    _log('Request body: ${jsonEncode({'name': trimmedName, 'token': '***'})}');

    final started = DateTime.now();
    _client ??= createDoctorActivationHttpClient();

    try {
      final response = await _client!
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent': kDoctorActivationUserAgent,
            },
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      final elapsed = DateTime.now().difference(started).inMilliseconds;
      _log('Response in ${elapsed}ms');
      _log('Status: ${response.statusCode}');
      _log('Response body: ${response.body}');

      final parsed = _parseActivationResponse(response, trimmedName, trimmedToken);
      if (parsed.ok) {
        await markActivated(name: trimmedName, token: trimmedToken);
        return (ok: true, message: parsed.message);
      }
      if (parsed.message.isNotEmpty) {
        return (ok: false, message: parsed.message);
      }

      final snippet = response.body.length > 200
          ? '${response.body.substring(0, 200)}...'
          : response.body;
      return (
        ok: false,
        message:
            'فشل التفعيل (${response.statusCode})${snippet.isNotEmpty ? ': $snippet' : ''}',
      );
    } on HandshakeException catch (e, st) {
      _log('HandshakeException: $e');
      _log('$st');
      return (
        ok: false,
        message:
            'فشل التشفير SSL/TLS مع الخادم.\n'
            'السبب الشائع: الخادم يقطع الاتصال أثناء المصافحة (ليست مشكلة في الاسم أو التوكن).\n'
            'تحقق من الرابط، شهادة HTTPS على odin.cemsbankcentral.com، الجدار الناري، أو اتصل بم host الـ API.\n'
            'التفاصيل: $e',
      );
    } on SocketException catch (e, st) {
      _log('SocketException: $e');
      _log('$st');
      return (ok: false, message: 'لا يوجد اتصال بالخادم: $e');
    } on TlsException catch (e, st) {
      _log('TlsException: $e');
      _log('$st');
      return (
        ok: false,
        message:
            'خطأ شهادة/تشفير TLS: $e\nجرّب تحديث الرابط مع مسؤول الخادم.',
      );
    } on http.ClientException catch (e, st) {
      _log('ClientException: $e');
      _log('$st');
      return (ok: false, message: 'خطأ شبكة: $e');
    } catch (e, st) {
      _log('Error: $e');
      _log('$st');
      return (ok: false, message: 'تعذر الاتصال: $e');
    }
  }

  ({bool ok, String message}) _parseActivationResponse(
    http.Response response,
    String requestedName,
    String requestedToken,
  ) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return (ok: false, message: '');
    }

    final raw = response.body.trim();
    if (raw.isEmpty) {
      return (ok: true, message: 'تم تفعيل التطبيق بنجاح');
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return (ok: true, message: 'تم تفعيل التطبيق بنجاح');
      }

      final success = decoded['success'];
      if (success is bool && !success) {
        final msg = decoded['message']?.toString();
        return (
          ok: false,
          message: msg?.isNotEmpty == true ? msg! : 'فشل التفعيل',
        );
      }

      final data = decoded['data'];
      if (data is List && data.isNotEmpty) {
        for (final row in data) {
          if (row is! Map) continue;
          final map = Map<String, dynamic>.from(row);
          final apiName = map['name']?.toString().trim() ?? '';
          final apiToken = map['token']?.toString().trim() ?? '';
          if (_namesMatch(apiName, requestedName) &&
              apiToken == requestedToken) {
            return (ok: true, message: 'تم تفعيل التطبيق بنجاح');
          }
        }
        return (
          ok: false,
          message: 'الاسم أو رمز التفعيل لا يطابق بيانات الخادم',
        );
      }

      if (success is bool && success) {
        return (ok: true, message: 'تم تفعيل التطبيق بنجاح');
      }
    } catch (_) {}

    return (ok: true, message: 'تم تفعيل التطبيق بنجاح');
  }

  bool _namesMatch(String a, String b) {
    final x = a.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final y = b.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    return x == y;
  }
}
import 'package:dental_managment_system/assets/assets.dart';
import 'package:dental_managment_system/core/colors.dart';
import 'package:dental_managment_system/features/auth/widgets/app_startup_gate.dart';
import 'package:dental_managment_system/features/home/views/widgets/custome_window_bar.dart';
import 'package:dental_managment_system/core/doctor_activation_config.dart';
import 'package:dental_managment_system/services/doctor_activation_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class DoctorActivationScreen extends StatefulWidget {
  const DoctorActivationScreen({super.key, this.initialError});

  final String? initialError;

  @override
  State<DoctorActivationScreen> createState() => _DoctorActivationScreenState();
}

class _DoctorActivationScreenState extends State<DoctorActivationScreen> {
  final _nameController = TextEditingController();
  final _tokenController = TextEditingController();
  final _apiUrlController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscureToken = true;
  bool _showAdvanced = false;

  @override
  void initState() {
    super.initState();
    final svc = DoctorActivationService.instance;
    final lastName = svc.lastActivatedName;
    if (lastName != null && lastName.isNotEmpty) {
      _nameController.text = lastName;
    }
    final lastToken = svc.storedToken;
    if (lastToken != null && lastToken.isNotEmpty) {
      _tokenController.text = lastToken;
    }
    _apiUrlController.text = svc.apiUrl.isNotEmpty
        ? svc.apiUrl
        : kDoctorActivationApiUrl;
    _error = widget.initialError;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tokenController.dispose();
    _apiUrlController.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    if (kDebugMode) {
      debugPrint(
        '[DoctorActivation] Activating with name="${_nameController.text.trim()}"',
      );
    }

    final result = await DoctorActivationService.instance.verifyWithServer(
      name: _nameController.text,
      token: _tokenController.text,
      apiUrlOverride: _apiUrlController.text,
    );

    if (!mounted) return;

    if (result.ok) {
      if (!mounted) return;
      setState(() => _loading = false);
      navigateAfterActivation();
      return;
    }

    setState(() {
      _loading = false;
      _error = result.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const CustomWindowBar(),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 520),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.mainColor.withValues(alpha: 0.25),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(Assets.of(context).logo_png, height: 120.h),
                      const SizedBox(height: 16),
                      Text(
                        'تفعيل التطبيق',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'أدخل الاسم والرمز — يُتحقق من الخادم مرة واحدة ثم يُحفظ محلياً دون إنترنت لاحقاً.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'اسم الطبيب (name)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() => _error = null),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _tokenController,
                        obscureText: _obscureToken,
                        decoration: InputDecoration(
                          labelText: 'رمز التفعيل (token)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.key_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureToken
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () =>
                                setState(() => _obscureToken = !_obscureToken),
                          ),
                        ),
                        onSubmitted: (_) {
                          if (!_loading) _activate();
                        },
                        onChanged: (_) => setState(() => _error = null),
                      ),

                      if (_showAdvanced) ...[
                        const SizedBox(height: 4),
                        TextField(
                          controller: _apiUrlController,
                          decoration: InputDecoration(
                            labelText: 'رابط API',
                            hintText: kDoctorActivationApiUrl,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.link),
                          ),
                          onChanged: (_) => setState(() => _error = null),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.cancelledColor,
                          ),
                        ),
                      ],
                      if (kDebugMode) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Debug: ابحث في الطرفية عن [DoctorActivationHTTP]',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _loading ? null : _activate,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.mainColor,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'تفعيل الآن',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                      if (kDebugMode) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _loading
                              ? null
                              : () async {
                                  await DoctorActivationService.instance
                                      .skipActivationForDebug();
                                  if (!mounted) return;
                                  navigateAfterActivation();
                                },
                          child: Text(
                            'تخطي التفعيل (وضع التطوير فقط)',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

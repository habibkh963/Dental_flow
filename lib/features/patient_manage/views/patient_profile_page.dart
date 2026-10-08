import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/colors.dart';
import '../../../core/models/treatment_catalog_item.dart';
import '../../../services/database_service.dart';
import '../../../services/treatment_catalog_service.dart';
import '../../billing_manage/views/widgets/invoice_dialog.dart';
import '../../home/views/widgets/custome_window_bar.dart';
import '../../settings_manage/controllers/treatment_catalog_controller.dart';
import '../controller/patient_profile_controller.dart';
import '../utils/patient_treatment_plan_utils.dart';
import 'widgets/cure_level_section.dart';

void openPatientProfile(BuildContext context, Map<String, dynamic> patient) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => PatientProfilePage(patient: patient)),
  );
}

class PatientProfilePage extends StatelessWidget {
  final Map<String, dynamic> patient;

  const PatientProfilePage({super.key, required this.patient});

  String get _tag => 'profile_${patient['id']}';

  static BoxDecoration get _cardDecoration => BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    color: Colors.white,
    border: Border.all(color: AppColors.mainColor.withValues(alpha: 0.28)),
    boxShadow: [
      BoxShadow(
        color: AppColors.mainColor.withValues(alpha: 0.1),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      PatientProfileController(patient: patient),
      tag: _tag,
    );

    final fullName =
        '${patient['last_name'] ?? ''} ${patient['first_name'] ?? ''}'.trim();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (Platform.isWindows) const CustomWindowBar(),
            _ProfileTopBar(
              fullName: fullName,
              onBack: Get.back,
              onInvoice: () => openInvoiceDialog(patient: controller.patient),
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.files.isEmpty) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppColors.mainColor,
                    ),
                  );
                }

                final p = controller.patient;

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PatientHeroCard(patient: p),
                      const SizedBox(height: 20),
                      _ProfileSectionCard(
                        title: 'معلومات التواصل',
                        icon: Icons.contact_phone_outlined,
                        child: Column(
                          children: [
                            _infoRow(
                              Icons.phone_outlined,
                              'الهاتف',
                              p['phone'],
                            ),
                            const Divider(height: 24),
                            _infoRow(
                              Icons.location_on_outlined,
                              'العنوان',
                              p['address'],
                            ),
                            const Divider(height: 24),
                            _infoRow(
                              Icons.email_outlined,
                              'البريد',
                              p['email'],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // _ProfileSectionCard(
                      //   title: 'خطة التمثيل / العلاج',
                      //   icon: Icons.medical_information_outlined,
                      //   child: _TreatmentPlanList(controller: controller),
                      // ),
                      const SizedBox(height: 16),
                      _ProfileSectionCard(
                        title: 'الأمراض / الحالات الخاصة',
                        icon: Icons.health_and_safety_outlined,
                        child: _MedicalConditionsList(
                          conditions: parseMedicalConditions(
                            p['diseases']?.toString(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      CureLevelSection(controller: controller),
                      const SizedBox(height: 20),
                      _ProfileSectionCard(
                        title: 'الملفات الطبية',
                        icon: Icons.folder_open_outlined,
                        trailing: FilledButton.icon(
                          onPressed: () => _uploadFile(context, controller),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.mainColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                          icon: const Icon(Icons.upload_file, size: 18),
                          label: Text(
                            'إضافة ملف',
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                        ),
                        child: controller.files.isEmpty
                            ? _emptyFilesPlaceholder()
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: controller.files.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (_, i) {
                                  return _FileCard(
                                    file: controller.files[i],
                                    onDeleted: () => controller.loadFiles(),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadFile(
    BuildContext context,
    PatientProfileController controller,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        await controller.uploadFile(file.name, file.path ?? '');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم رفع الملف', style: GoogleFonts.poppins()),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في رفع الملف: $e')));
      }
    }
  }

  static Widget _infoRow(IconData icon, String label, dynamic value) {
    final text = value?.toString().trim();
    final display = (text == null || text.isEmpty) ? '—' : text;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.mainColor),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            display,
            textAlign: TextAlign.end,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  static Widget _emptyFilesPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.mainColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.mainColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.insert_drive_file_outlined,
            size: 40,
            color: AppColors.mainColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'لا توجد ملفات مرفقة',
            style: GoogleFonts.poppins(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TreatmentPlanList extends StatelessWidget {
  const _TreatmentPlanList({required this.controller});

  final PatientProfileController controller;

  @override
  Widget build(BuildContext context) {
    final items = controller.plannedTreatments;
    if (items.isEmpty) {
      return Text(
        'لم تُسجَّل خطة تمثيل بعد',
        style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
      );
    }

    final catalogItems = Get.isRegistered<TreatmentCatalogController>()
        ? Get.find<TreatmentCatalogController>().items.toList()
        : <TreatmentCatalogItem>[];

    return Column(
      children: items.map((name) {
        final price = catalogItems.isEmpty
            ? null
            : TreatmentCatalogService.priceForName(name, catalogItems);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                price != null && price > 0
                    ? '${price.toStringAsFixed(0)} ل.س'
                    : 'بدون سعر في الإعدادات',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: price != null && price > 0
                      ? AppColors.mainColor
                      : Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _MedicalConditionsList extends StatelessWidget {
  const _MedicalConditionsList({required this.conditions});

  final List<String> conditions;

  @override
  Widget build(BuildContext context) {
    if (conditions.isEmpty) {
      return Text(
        'لا توجد أمراض أو حالات مسجلة',
        style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: conditions
          .map(
            (label) => Chip(
              label: Text(label, style: GoogleFonts.poppins(fontSize: 12)),
              backgroundColor: Colors.orange.shade50,
              side: BorderSide(color: Colors.orange.shade200),
            ),
          )
          .toList(),
    );
  }
}

class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar({
    required this.fullName,
    required this.onBack,
    required this.onInvoice,
  });

  final String fullName;
  final VoidCallback onBack;
  final VoidCallback onInvoice;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 28, 12),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'رجوع',
                  onPressed: onBack,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.mainColor.withValues(alpha: 0.1),
                    foregroundColor: AppColors.mainColor,
                    minimumSize: const Size(44, 44),
                  ),
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ملف المريض',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fullName.isEmpty ? 'مريض' : fullName,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: onInvoice,
                  icon: const Icon(Icons.receipt_long_outlined, size: 18),
                  label: Text('فاتورة', style: GoogleFonts.poppins()),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.mainColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PatientHeroCard extends StatelessWidget {
  const _PatientHeroCard({required this.patient});

  final Map<String, dynamic> patient;

  @override
  Widget build(BuildContext context) {
    final name = '${patient['last_name'] ?? ''} ${patient['first_name'] ?? ''}'
        .trim();
    final email = patient['email']?.toString().trim();
    final phone = patient['phone']?.toString().trim();

    return Container(
      width: double.infinity,
      decoration: PatientProfilePage._cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 6, color: AppColors.mainColor),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.mainColor.withValues(alpha: 0.15),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.mainColor,
                    size: 38,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? 'مريض' : name,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (email != null && email.isNotEmpty)
                        Text(
                          email,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        )
                      else
                        Text(
                          'لا يوجد بريد إلكتروني',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                ),
                if (phone != null && phone.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.mainColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.phone_in_talk_outlined,
                          size: 18,
                          color: AppColors.mainColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          phone,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.mainColor,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSectionCard extends StatelessWidget {
  const _ProfileSectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: PatientProfilePage._cardDecoration,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.mainColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainColor,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _FileCard extends StatelessWidget {
  const _FileCard({required this.file, required this.onDeleted});

  final Map<String, dynamic> file;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    final fileName = file['file_name'] ?? 'غير معروف';
    final filePath = file['file_path'] ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.mainColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.description_outlined, color: AppColors.mainColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (filePath.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    filePath.length > 48
                        ? '...${filePath.substring(filePath.length - 45)}'
                        : filePath,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'فتح',
            icon: const Icon(Icons.open_in_new_rounded, size: 20),
            color: AppColors.mainColor,
            onPressed: () {
              if (filePath.isNotEmpty && File(filePath).existsSync()) {
                Process.run('cmd', [
                  '/c',
                  'start',
                  '',
                  filePath,
                ], runInShell: true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'الملف غير موجود',
                      style: GoogleFonts.poppins(),
                    ),
                  ),
                );
              }
            },
          ),
          IconButton(
            tooltip: 'حذف',
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            color: AppColors.cancelledColor,
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('حذف الملف؟', style: GoogleFonts.poppins()),
                  content: Text(
                    'هل تريد تأكيد الحذف؟',
                    style: GoogleFonts.poppins(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text('إلغاء', style: GoogleFonts.poppins()),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(
                        'حذف',
                        style: GoogleFonts.poppins(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await DatabaseService.instance.deletePatientFile(file['id']);
                onDeleted();
              }
            },
          ),
        ],
      ),
    );
  }
}

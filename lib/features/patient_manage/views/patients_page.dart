import 'package:dental_managment_system/core/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../../../services/database_service.dart';
import '../controller/patients_controller.dart';
import 'widgets/patient_dialog.dart';
import '../../billing_manage/views/widgets/invoice_dialog.dart';

class PatientsPage extends StatelessWidget {
  final c = Get.put(
    PatientsController(),
    permanent: false,
    tag: UniqueKey().toString(),
  );

  PatientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔹 Header
          Row(
            children: [
              Text(
                'المرضى',

                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintStyle: GoogleFonts.poppins(color: AppColors.mainColor),

                    hintText: 'ابحث عن اسم المريض...',
                    prefixIcon: Icon(Icons.search, color: AppColors.mainColor),
                  ),
                  onChanged: (value) {
                    c.filterPatients(value); // تابع الفلترة
                  },
                ),
              ),
              const Spacer(),

              FilledButton.icon(
                onPressed: () => openPatientDialog(context, c),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  backgroundColor: AppColors.mainColor,
                ),
                icon: const Icon(Icons.add),
                label: Text('إضافة مريض ', style: GoogleFonts.poppins()),
              ),
            ],
          ),

          const SizedBox(height: 26),

          /// 🔹 Table Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white.withOpacity(0.9),
              boxShadow: [
                BoxShadow(
                  color: AppColors.mainColor.withOpacity(0.1),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text("المريض", style: GoogleFonts.poppins()),
                ),
                Expanded(child: Text("الهاتف", style: GoogleFonts.poppins())),
                Expanded(child: Text("الايميل", style: GoogleFonts.poppins())),
                Expanded(child: Text("العنوان", style: GoogleFonts.poppins())),
                Expanded(child: Text("الخيارات", style: GoogleFonts.poppins())),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: Obx(() {
              if (c.loading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (c.filteredPatients.isEmpty) {
                return Center(
                  child: Text('لا يوجد مرضى', style: GoogleFonts.poppins()),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(top: 10),
                itemCount: c.filteredPatients.length,
                itemBuilder: (_, i) {
                  final p = c.filteredPatients[i];
                  final name = '${p['first_name']} ${p['last_name']}';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                      border: Border.all(
                        color: AppColors.mainColor.withOpacity(.4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.mainColor.withOpacity(.15),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        /// Patient
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: AppColors.mainColor,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              const SizedBox(width: 10),
                              Text(name, style: GoogleFonts.poppins()),
                            ],
                          ),
                        ),

                        /// Phone
                        Expanded(child: Text(p['phone'] ?? '-')),

                        /// Email
                        Expanded(child: Text(p['email'] ?? '-')),

                        /// Address
                        Expanded(
                          child: Text(
                            p['address'] ?? '-',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        /// Actions
                        Expanded(
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.visibility,
                                  color: AppColors.mainColor,
                                ),
                                onPressed: () => openPatientProfile(context, p),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: AppColors.mainColor,
                                ),
                                onPressed: () =>
                                    openPatientDialog(context, c, existing: p),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () => c.remove(p['id']),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

void openPatientProfile(BuildContext context, Map<String, dynamic> patient) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => PatientProfilePage(patient: patient)),
  );
}

class PatientProfilePage extends StatefulWidget {
  final Map<String, dynamic> patient;
  const PatientProfilePage({super.key, required this.patient});

  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
  late List<Map<String, dynamic>> files;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    final loadedFiles = await DatabaseService.instance.getPatientFiles(
      widget.patient['id'],
    );
    setState(() {
      files = loadedFiles;
    });
  }

  Future<void> _uploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        await DatabaseService.instance.addPatientFile({
          'patient_id': widget.patient['id'],
          'file_name': file.name,
          'file_path': file.path ?? '',
        });
        await _loadFiles();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File uploaded successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading file: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),
      appBar: AppBar(
        title: Text(
          '${widget.patient['last_name']} ${widget.patient['first_name']}',

          style: GoogleFonts.poppins(),
        ),
        automaticallyImplyLeading: false,
        leading: GestureDetector(
          onTap: () {
            Get.back();
          },
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: CircleAvatar(
              backgroundColor: AppColors.mainColor,
              child: Icon(Icons.arrow_back_ios_new, color: Colors.white),
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.mainColor.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: AppColors.mainColor,
                    child: Icon(Icons.person, color: Colors.white, size: 40),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.patient['last_name']} ${widget.patient['first_name']}',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.patient['email'] ?? 'لا يوجد ايميل',
                          style: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      FilledButton.icon(
                        onPressed: () =>
                            openInvoiceDialog(patient: widget.patient),
                        icon: const Icon(Icons.receipt_long, size: 18),
                        label: Text('الفاتورة', style: GoogleFonts.poppins()),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.approvedColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            /// Contact Info
            _sectionTitle('معلومات التواصل'),
            const SizedBox(height: 12),
            _infoCard('رقم الهاتف', widget.patient['phone'] ?? '-'),
            const SizedBox(height: 12),
            _infoCard('العنوان', widget.patient['address'] ?? '-'),
            const SizedBox(height: 24),

            /// Diseases/Conditions
            _sectionTitle('الأمراض/الحالات الخاصة'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.mainColor.withOpacity(0.2)),
              ),
              child: Text(
                widget.patient['diseases']?.isNotEmpty == true
                    ? widget.patient['diseases']
                    : 'لايوجد أمراض/حالات مسجلة',
                style: GoogleFonts.poppins(
                  color: widget.patient['diseases']?.isNotEmpty == true
                      ? Colors.black
                      : Colors.black,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),

            /// Files Section
            Row(
              children: [
                _sectionTitle('الملفات الطبية'),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _uploadFile,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.mainColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(
                    'اضافة ملف',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            files.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        'لا يوجد ملفات مضافة ',
                        style: GoogleFonts.poppins(color: Colors.black),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: files.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final file = files[i];
                      return _fileCard(file);
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.mainColor,
      ),
    );
  }

  Widget _infoCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.mainColor.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(color: Colors.black, fontSize: 13),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fileCard(Map<String, dynamic> file) {
    final fileName = file['file_name'] ?? 'غير معروف';
    final filePath = file['file_path'] ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.mainColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.file_present, color: AppColors.mainColor, size: 28),
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
                const SizedBox(height: 4),
                Text(
                  filePath.length > 50
                      ? '...${filePath.substring(filePath.length - 47)}'
                      : filePath,
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.open_in_new, size: 18),
            tooltip: 'Open file',
            onPressed: () {
              if (filePath.isNotEmpty && File(filePath).existsSync()) {
                try {
                  // Use proper Windows command to open file
                  Process.run('cmd', [
                    '/c',
                    'start',
                    '',
                    filePath,
                  ], runInShell: true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'جار فتح الملف ...',
                        style: GoogleFonts.poppins(),
                      ),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'لا يمكن فتح الملف  : $e',
                        style: GoogleFonts.poppins(),
                      ),
                    ),
                  );
                }
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
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
            tooltip: 'Delete file',
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
                      child: Text('الغاء', style: GoogleFonts.poppins()),
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
                await _loadFiles();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم حذف الملف', style: GoogleFonts.poppins()),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

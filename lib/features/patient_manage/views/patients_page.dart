import 'package:dental_managment_system/core/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controller/patients_controller.dart';
import 'patient_profile_page.dart';
import 'widgets/patient_dialog.dart';

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


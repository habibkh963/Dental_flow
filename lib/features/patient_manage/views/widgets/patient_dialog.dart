import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controller/patients_controller.dart';

// Common diseases list (mutable so users can add custom items)
List<String> diseasesList = [
  'Diabetes',
  'Hypertension',
  'Asthma',
  'Heart Disease',
  'Dental Anxiety',
  'Bruxism',
  'Xerostomia',
  'Periodontitis',
  'Gingivitis',
  'Cavities',
];

Future<void> openPatientDialog(
  BuildContext context,
  PatientsController controller, {
  Map<String, dynamic>? existing,
}) async {
  final isEdit = existing != null;

  final first = TextEditingController(text: existing?['first_name'] ?? '');
  final last = TextEditingController(text: existing?['last_name'] ?? '');
  final phone = TextEditingController(text: existing?['phone'] ?? '');
  final email = TextEditingController(text: existing?['email'] ?? '');
  final address = TextEditingController(text: existing?['address'] ?? '');

  // Parse diseases from existing
  final existingDiseases = existing?['diseases'] ?? '';
  final selectedDiseases = existingDiseases.isNotEmpty
      ? existingDiseases.split(',').map((s) => s.trim()).toList()
      : <String>[];
  final customDiseaseController = TextEditingController();

  await showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (ctx, setState) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              width: 550,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.95),
                borderRadius: BorderRadius.circular(24),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isEdit ? "Edit Patient" : "Add New Patient",
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2A9D8F),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _field(first, "First name"),
                    const SizedBox(height: 12),
                    _field(last, "Last name"),
                    const SizedBox(height: 12),
                    _field(phone, "Phone"),
                    const SizedBox(height: 12),
                    _field(email, "Email"),
                    const SizedBox(height: 12),
                    _field(address, "Address", maxLines: 2),
                    const SizedBox(height: 18),

                    /// Diseases Section
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Medical Conditions',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2A9D8F),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Input to add custom disease
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: customDiseaseController,
                            decoration: _dec('Add disease (type and press +)'),
                            onSubmitted: (val) {
                              final v = val.trim();
                              if (v.isEmpty) return;
                              if (!selectedDiseases.contains(v))
                                selectedDiseases.add(v);
                              if (!diseasesList.contains(v))
                                diseasesList.add(v);
                              customDiseaseController.clear();
                              // rebuild
                              (ctx as Element).markNeedsBuild();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A9D8F),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.add, color: Colors.white),
                            onPressed: () {
                              final v = customDiseaseController.text.trim();
                              if (v.isEmpty) return;
                              if (!selectedDiseases.contains(v))
                                selectedDiseases.add(v);
                              if (!diseasesList.contains(v))
                                diseasesList.add(v);
                              customDiseaseController.clear();
                              // rebuild
                              (ctx as Element).markNeedsBuild();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: diseasesList.map((disease) {
                        final isSelected = selectedDiseases.contains(disease);
                        return FilterChip(
                          label: Text(
                            disease,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF2A9D8F),
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                selectedDiseases.add(disease);
                              } else {
                                selectedDiseases.remove(disease);
                              }
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor: const Color(0xFF2A9D8F),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFF2A9D8F)
                                : const Color(0xFF2A9D8F).withOpacity(0.3),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 26),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Get.back(),
                          child: const Text("Cancel"),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2A9D8F),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                          ),
                          onPressed: () async {
                            final data = {
                              'first_name': first.text.trim(),
                              'last_name': last.text.trim(),
                              'phone': phone.text.trim(),
                              'email': email.text.trim(),
                              'address': address.text.trim(),
                              'diseases': selectedDiseases.join(', '),
                            };

                            if (isEdit) {
                              await controller.updatePatient(
                                existing['id'],
                                data,
                              );
                            } else {
                              await controller.add(data);
                            }

                            Get.back();
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

InputDecoration _dec(String hint) => InputDecoration(
  hintText: hint,
  filled: true,
  fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide.none,
  ),
);

Widget _field(TextEditingController c, String hint, {int maxLines = 1}) {
  return TextField(controller: c, maxLines: maxLines, decoration: _dec(hint));
}

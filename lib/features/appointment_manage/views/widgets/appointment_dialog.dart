import 'dart:developer';
import 'dart:ui';
import 'package:dental_managment_system/core/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../controllers/appointments_controller.dart';

class AppointmentDialog {
  static Future<void> show({
    required BuildContext context,
    required AppointmentsController controller,
    Map<String, dynamic>? existing,
  }) async {
    String? selectedPatientId = existing?['patient_id'];
    controller.fetchPatients();
    controller.fetchInventory();

    DateTime? selectedDate = existing?['date'] != null
        ? DateTime.tryParse(existing!['date'])
        : null;

    TimeOfDay? selectedTime = (() {
      final t = existing?['time'];
      if (t != null && t.toString().contains(':')) {
        final p = t.split(':');
        return _parseTime(existing?['time']);
      }
      return null;
    })();

    String status = (existing?['status'] ?? 'scheduled').toLowerCase();
    // normalize DB value 'done' to UI-friendly 'completed'
    if (status == 'done') status = 'completed';
    final notesController = TextEditingController(
      text: existing?['notes'] ?? '',
    );

    // Materials list: List of {material_id, quantity}
    final selectedMaterials = <Map<String, dynamic>>[].obs;
    String? selectedMaterialId;
    int selectedQuantity = 1;

    final notesInput = ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(child: Container()),
    );

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    width: 540,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildHeader(existing),
                          const SizedBox(height: 24),
                          _PatientDropdown(
                            patients: controller.patients.value,
                            selectedPatientId: selectedPatientId,
                            onChanged: (v) =>
                                setState(() => selectedPatientId = v),
                          ),
                          const SizedBox(height: 20),
                          _DateTimePickerRow(
                            selectedDate: selectedDate,
                            selectedTime: selectedTime,
                            onDateChanged: (d) =>
                                setState(() => selectedDate = d),
                            onTimeChanged: (t) =>
                                setState(() => selectedTime = t),
                          ),
                          const SizedBox(height: 20),
                          _StatusDropdown(
                            status: status,
                            onChanged: (v) => setState(() => status = v!),
                          ),
                          const SizedBox(height: 20),
                          if (status == 'completed') ...[
                            _MaterialsDropdown(
                              inventory: controller.inventory.value,
                              selectedMaterialId: selectedMaterialId,
                              selectedQuantity: selectedQuantity,
                              onMaterialChanged: (v) {
                                setState(() => selectedMaterialId = v);
                              },
                              onQuantityChanged: (v) {
                                setState(() => selectedQuantity = v);
                              },
                              onAdd: () {
                                if (selectedMaterialId == null ||
                                    selectedQuantity <= 0)
                                  return;

                                // Find inventory item and validate stock
                                final inv = controller.inventory.value;
                                final found = inv.firstWhere(
                                  (i) => i['id'] == selectedMaterialId,
                                  orElse: () => <String, dynamic>{},
                                );

                                final available =
                                    (found.isNotEmpty && found['qty'] != null)
                                    ? (found['qty'] is int
                                          ? found['qty'] as int
                                          : int.tryParse(
                                                  found['qty'].toString(),
                                                ) ??
                                                0)
                                    : 0;

                                if (selectedQuantity > available) {
                                  showDialog(
                                    context: ctx,
                                    builder: (dCtx) => AlertDialog(
                                      title: const Text('Insufficient stock'),
                                      content: Text(
                                        'Requested quantity ($selectedQuantity) is greater than available stock ($available).',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(dCtx).pop(),
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    ),
                                  );
                                  return;
                                }

                                // add to list
                                setState(() {
                                  selectedMaterials.add({
                                    'material_id': selectedMaterialId,
                                    'quantity': selectedQuantity,
                                  });
                                  selectedMaterialId = null;
                                  selectedQuantity = 1;
                                });
                              },
                            ),
                            const SizedBox(height: 20),
                            if (selectedMaterials.isNotEmpty) ...[
                              _MaterialsList(
                                materials: selectedMaterials,
                                inventory: controller.inventory.value,
                                onRemove: (index) {
                                  setState(() {
                                    selectedMaterials.removeAt(index);
                                  });
                                },
                              ),
                              const SizedBox(height: 20),
                            ],
                          ],
                          _NotesInput(controller: notesController),
                          const SizedBox(height: 28),
                          _ActionsRow(
                            onCancel: () => Get.back(),
                            onSave: () async {
                              if (selectedPatientId == null) return;

                              final data = <String, dynamic>{
                                'patient_id': selectedPatientId,
                                'date': selectedDate != null
                                    ? selectedDate!
                                          .toIso8601String()
                                          .split("T")
                                          .first
                                    : existing?['date'],
                                'time': selectedTime != null
                                    ? selectedTime!.format(ctx)
                                    : existing?['time'],
                                'status': status == 'completed'
                                    ? 'done'
                                    : status,
                                'notes': notesController.text,
                                'materials': selectedMaterials.toList(),
                              };

                              if (existing == null) {
                                await controller.add(data);
                              } else {
                                await controller.updateAppt(
                                  existing['id'],
                                  data,
                                );
                              }
                              Get.back();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildHeader(Map<String, dynamic>? existing) {
    return Text(
      existing == null ? 'New Appointment' : 'Edit Appointment',
      style: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF2A9D8F),
      ),
    );
  }
}

class _PatientDropdown extends StatelessWidget {
  final List patients;
  final String? selectedPatientId;
  final ValueChanged<String?> onChanged;

  const _PatientDropdown({
    required this.patients,
    required this.selectedPatientId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    log('==> ${patients.toString()}');
    return DropdownButtonFormField<String>(
      value: selectedPatientId,
      hint: const Text("Select patient"),
      decoration: _inputDecoration(),
      items: patients
          .map(
            (p) => DropdownMenuItem<String>(
              value: p['id'],
              child: Text(
                '${(p['first_name'] ?? '')}'
                '${(p['last_name'] ?? '')}',
                style: GoogleFonts.poppins(color: AppColors.approvedColor),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _DateTimePickerRow extends StatelessWidget {
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<TimeOfDay> onTimeChanged;

  const _DateTimePickerRow({
    required this.selectedDate,
    required this.selectedTime,
    required this.onDateChanged,
    required this.onTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PickerButton(
            icon: Icons.calendar_today,
            label: selectedDate == null
                ? "Pick date"
                : selectedDate.toString().split(" ").first,
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? DateTime.now(),
                firstDate: DateTime(2022),
                lastDate: DateTime(2030),
              );
              if (picked != null) onDateChanged(picked);
            },
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _PickerButton(
            icon: Icons.access_time,
            label: selectedTime == null
                ? "Pick time"
                : selectedTime!.format(context),
            onPressed: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime:
                    selectedTime ?? const TimeOfDay(hour: 10, minute: 0),
              );
              if (picked != null) onTimeChanged(picked);
            },
          ),
        ),
      ],
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  final String status;
  final ValueChanged<String?> onChanged;

  const _StatusDropdown({required this.status, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: status,
      decoration: _inputDecoration(),
      items: const [
        DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
        DropdownMenuItem(value: 'completed', child: Text('Completed')),
        DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
      ],
      onChanged: onChanged,
    );
  }
}

class _NotesInput extends StatelessWidget {
  final TextEditingController controller;

  const _NotesInput({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 3,
      decoration: _inputDecoration(hint: "Notes..."),
    );
  }
}

class _MaterialsDropdown extends StatelessWidget {
  final List inventory;
  final String? selectedMaterialId;
  final int selectedQuantity;
  final ValueChanged<String?> onMaterialChanged;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onAdd;

  const _MaterialsDropdown({
    required this.inventory,
    required this.selectedMaterialId,
    required this.selectedQuantity,
    required this.onMaterialChanged,
    required this.onQuantityChanged,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: selectedMaterialId,
          hint: const Text("Select material"),
          decoration: _inputDecoration(),
          items: inventory
              .map(
                (m) => DropdownMenuItem<String>(
                  value: m['id'],
                  child: Text('${m['name']} (Stock: ${m['qty']})'),
                ),
              )
              .toList(),
          onChanged: onMaterialChanged,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(hint: "Quantity"),
                onChanged: (v) {
                  final qty = int.tryParse(v) ?? 1;
                  onQuantityChanged(qty > 0 ? qty : 1);
                },
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2A9D8F),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              onPressed: onAdd,
              child: const Text('Add'),
            ),
          ],
        ),
      ],
    );
  }
}

class _MaterialsList extends StatelessWidget {
  final List<Map<String, dynamic>> materials;
  final List inventory;
  final Function(int) onRemove;

  const _MaterialsList({
    required this.materials,
    required this.inventory,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selected Materials:',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2A9D8F),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: materials.length,
            itemBuilder: (context, index) {
              final material = materials[index];
              final inventoryItem = inventory.firstWhere(
                (i) => i['id'] == material['material_id'],
                orElse: () => <String, dynamic>{},
              );
              final materialName = inventoryItem['name'] ?? 'Unknown';

              return ListTile(
                title: Text('$materialName x${material['quantity']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => onRemove(index),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ActionsRow extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _ActionsRow({required this.onCancel, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(onPressed: onCancel, child: const Text("Cancel")),
        const SizedBox(width: 16),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2A9D8F),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shadowColor: Colors.black26,
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: onSave,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// Reusable input decoration
InputDecoration _inputDecoration({String? hint}) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
    ),
  );
}

// Reusable button for Date & Time pickers
class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: Colors.white,
        shadowColor: Colors.black12,
        elevation: 3,
      ),
      onPressed: onPressed,
      icon: Icon(icon, color: const Color(0xFF2A9D8F)),
      label: Text(label, style: const TextStyle(color: Colors.black87)),
    );
  }
}

TimeOfDay? _parseTime(String? t) {
  if (t == null || t.isEmpty) return null;

  try {
    // استخدم DateFormat من intl package
    final dt = DateFormat.jm().parse(t); // "10:00 AM" أو "5:30 PM"
    return TimeOfDay(hour: dt.hour, minute: dt.minute);
  } catch (_) {
    // fallback
    final parts = t.split(':');
    if (parts.length == 2) {
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour != null && minute != null)
        return TimeOfDay(hour: hour, minute: minute);
    }
  }
  return null;
}

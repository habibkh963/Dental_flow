import 'dart:developer';

import 'package:get/get.dart';

import '../../../services/database_service.dart';

class AppointmentsController extends GetxController {
  final appts = <Map<String, dynamic>>[].obs;
  final patients = <Map<String, dynamic>>[].obs;
  final inventory = <Map<String, dynamic>>[].obs;
  final loading = false.obs;
  @override
  void onInit() {
    super.onInit();
    fetch();
    fetchPatients();
    fetchInventory();
  }

  Future<void> fetch({String? patientId}) async {
    loading.value = true;
    appts.value = await DatabaseService.instance.getAppointments(
      patientId: patientId,
    );
    log(appts.value.toString());
    loading.value = false;
  }

  Future<void> fetchPatients() async {
    patients.value = await DatabaseService.instance.getPatients();
    log(patients.value.toString());
  }

  Future<void> fetchInventory() async {
    inventory.value = await DatabaseService.instance.getInventory();
    log(inventory.value.toString());
  }

  Future<void> add(Map<String, dynamic> data) async {
    // Extract materials before saving appointment
    final materials = data['materials'] as List? ?? [];
    data.remove('materials');

    final appointmentId = await DatabaseService.instance.addAppointment(data);

    // Save materials if any and adjust inventory (decrement stock)
    if (materials.isNotEmpty) {
      for (final material in materials) {
        final materialId = material['material_id'];
        final usedQty = material['quantity'] is int
            ? material['quantity'] as int
            : int.tryParse(material['quantity'].toString()) ?? 0;

        await DatabaseService.instance.addAppointmentMaterial(
          appointmentId,
          materialId,
          usedQty,
        );

        // Try to find inventory item in-memory first
        Map<String, dynamic> invItem = {};
        try {
          invItem = inventory.firstWhere(
            (i) => i['id'] == materialId,
            orElse: () => <String, dynamic>{},
          );
        } catch (_) {
          invItem = <String, dynamic>{};
        }

        if (invItem.isNotEmpty) {
          final currentQty = invItem['qty'] is int
              ? invItem['qty'] as int
              : int.tryParse(invItem['qty'].toString()) ?? 0;
          final newQty = currentQty - usedQty;
          await DatabaseService.instance.updateInventoryItem(invItem['id'], {
            'qty': newQty < 0 ? 0 : newQty,
          });
        } else {
          // Fallback: query DB for the inventory item then update
          final dbInv = await DatabaseService.instance.getInventory();
          final found = dbInv.firstWhere(
            (i) => i['id'] == materialId,
            orElse: () => <String, dynamic>{},
          );
          if (found.isNotEmpty) {
            final currentQty = found['qty'] is int
                ? found['qty'] as int
                : int.tryParse(found['qty'].toString()) ?? 0;
            final newQty = currentQty - usedQty;
            await DatabaseService.instance.updateInventoryItem(found['id'], {
              'qty': newQty < 0 ? 0 : newQty,
            });
          }
        }
      }

      // Refresh in-memory inventory after adjustments
      await fetchInventory();
    }

    await fetch();
  }

  Future<void> updateAppt(String id, Map<String, dynamic> data) async {
    // Extract materials before updating appointment
    final materials = data['materials'] as List? ?? [];
    data.remove('materials');

    // Restore stock for previously used materials
    final oldMaterials = await DatabaseService.instance.getAppointmentMaterials(
      id,
    );
    if (oldMaterials.isNotEmpty) {
      for (final old in oldMaterials) {
        final oldMaterialId = old['material_id'];
        final oldQty = old['quantity'] is int
            ? old['quantity'] as int
            : int.tryParse(old['quantity'].toString()) ?? 0;

        // Find current inventory item
        Map<String, dynamic> invItem = {};
        try {
          invItem = inventory.firstWhere(
            (i) => i['id'] == oldMaterialId,
            orElse: () => <String, dynamic>{},
          );
        } catch (_) {
          invItem = <String, dynamic>{};
        }

        if (invItem.isNotEmpty) {
          final currentQty = invItem['qty'] is int
              ? invItem['qty'] as int
              : int.tryParse(invItem['qty'].toString()) ?? 0;
          final newQty = currentQty + oldQty;
          await DatabaseService.instance.updateInventoryItem(invItem['id'], {
            'qty': newQty,
          });
        } else {
          final dbInv = await DatabaseService.instance.getInventory();
          final found = dbInv.firstWhere(
            (i) => i['id'] == oldMaterialId,
            orElse: () => <String, dynamic>{},
          );
          if (found.isNotEmpty) {
            final currentQty = found['qty'] is int
                ? found['qty'] as int
                : int.tryParse(found['qty'].toString()) ?? 0;
            final newQty = currentQty + oldQty;
            await DatabaseService.instance.updateInventoryItem(found['id'], {
              'qty': newQty,
            });
          }
        }
      }

      // After restoring, delete old appointment materials
      await DatabaseService.instance.deleteAppointmentMaterials(id);
      // Refresh inventory before applying new materials
      await fetchInventory();
    }

    // Update appointment basic fields
    await DatabaseService.instance.updateAppointment(id, data);

    // Save new materials and decrement inventory
    if (materials.isNotEmpty) {
      for (final material in materials) {
        final materialId = material['material_id'];
        final usedQty = material['quantity'] is int
            ? material['quantity'] as int
            : int.tryParse(material['quantity'].toString()) ?? 0;

        await DatabaseService.instance.addAppointmentMaterial(
          id,
          materialId,
          usedQty,
        );

        // adjust inventory
        Map<String, dynamic> invItem = {};
        try {
          invItem = inventory.firstWhere(
            (i) => i['id'] == materialId,
            orElse: () => <String, dynamic>{},
          );
        } catch (_) {
          invItem = <String, dynamic>{};
        }

        if (invItem.isNotEmpty) {
          final currentQty = invItem['qty'] is int
              ? invItem['qty'] as int
              : int.tryParse(invItem['qty'].toString()) ?? 0;
          final newQty = currentQty - usedQty;
          await DatabaseService.instance.updateInventoryItem(invItem['id'], {
            'qty': newQty < 0 ? 0 : newQty,
          });
        } else {
          final dbInv = await DatabaseService.instance.getInventory();
          final found = dbInv.firstWhere(
            (i) => i['id'] == materialId,
            orElse: () => <String, dynamic>{},
          );
          if (found.isNotEmpty) {
            final currentQty = found['qty'] is int
                ? found['qty'] as int
                : int.tryParse(found['qty'].toString()) ?? 0;
            final newQty = currentQty - usedQty;
            await DatabaseService.instance.updateInventoryItem(found['id'], {
              'qty': newQty < 0 ? 0 : newQty,
            });
          }
        }
      }

      await fetchInventory();
    }

    await fetch();
  }

  Future<void> remove(String id) async {
    await DatabaseService.instance.deleteAppointment(id);
    await fetch();
  }
}

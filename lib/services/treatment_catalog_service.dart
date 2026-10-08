import 'dart:convert';

import '../core/dental_treatment_presentations.dart';
import '../core/models/treatment_catalog_item.dart';
import 'database_service.dart';

class TreatmentCatalogService {
  TreatmentCatalogService._();
  static final instance = TreatmentCatalogService._();

  static const _storageKey = 'treatment_catalog_v1';

  Future<List<TreatmentCatalogItem>> load() async {
    final raw = await DatabaseService.instance.getSetting(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      final seeded = _seedDefaults();
      await save(seeded);
      return seeded;
    }

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => TreatmentCatalogItem.fromJson(e as Map<String, dynamic>))
          .where((item) => item.name.trim().isNotEmpty)
          .toList();
    } catch (_) {
      final seeded = _seedDefaults();
      await save(seeded);
      return seeded;
    }
  }

  Future<void> save(List<TreatmentCatalogItem> items) async {
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await DatabaseService.instance.setSetting(_storageKey, encoded);
  }

  List<TreatmentCatalogItem> _seedDefaults() {
    return kDefaultTreatmentPlanNames
        .map(
          (name) => TreatmentCatalogItem(
            id: _slugId(name),
            name: name,
            price: 0,
          ),
        )
        .toList();
  }

  static String _slugId(String name) {
    final normalized = name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    return 't_$normalized';
  }

  static String newItemId() =>
      't_${DateTime.now().microsecondsSinceEpoch}';

  static double sumPrices(
    List<String> treatmentNames,
    List<TreatmentCatalogItem> catalog,
  ) {
    var sum = 0.0;
    for (final name in treatmentNames) {
      final price = priceForName(name, catalog);
      if (price != null) sum += price;
    }
    return sum;
  }

  static double? priceForName(String name, List<TreatmentCatalogItem> catalog) {
    for (final item in catalog) {
      if (item.name.trim().toLowerCase() == name.trim().toLowerCase()) {
        return item.price;
      }
    }
    return null;
  }
}

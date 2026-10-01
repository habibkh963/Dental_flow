import 'inventory_stock_status.dart';

const kDefaultInventoryUnit = 'وحدة';

const kInventoryUnits = [
  'وحدة',
  'علبة',
  'كيس',
  'زجاجة',
  'لفة',
  'قطعة',
  'عبوة',
  'مل',
];

class InventoryItem {
  final String id;
  final String name;
  final int quantity;
  final int lowStockThreshold;
  final String unit;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.lowStockThreshold,
    required this.unit,
  });

  InventoryStockStatus get stockStatus => resolveStockStatus(
        quantity: quantity,
        lowStockThreshold: lowStockThreshold,
      );

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString().trim() ?? '',
      quantity: _parseInt(map['qty']),
      lowStockThreshold: _parseInt(map['threshold']),
      unit: _parseUnit(map['unit']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _parseUnit(dynamic value) {
    final unit = value?.toString().trim();
    if (unit == null || unit.isEmpty) return kDefaultInventoryUnit;
    return unit;
  }
}

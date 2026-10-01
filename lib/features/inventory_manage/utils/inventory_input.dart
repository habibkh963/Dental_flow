class InventoryFormValues {
  final String name;
  final int quantity;
  final int lowStockThreshold;
  final String unit;

  const InventoryFormValues({
    required this.name,
    required this.quantity,
    required this.lowStockThreshold,
    required this.unit,
  });
}

/// Returns parsed values, or null with an Arabic [error] message.
({InventoryFormValues? values, String? error}) tryParseInventoryForm({
  required String name,
  required String quantityText,
  required String thresholdText,
  required String unit,
}) {
  final trimmedName = name.trim();
  if (trimmedName.isEmpty) {
    return (values: null, error: 'اسم المنتج مطلوب');
  }

  final quantity = int.tryParse(quantityText.trim());
  if (quantity == null) {
    return (values: null, error: 'الكمية يجب أن تكون رقماً صحيحاً');
  }
  if (quantity < 0) {
    return (values: null, error: 'الكمية لا يمكن أن تكون سالبة');
  }

  final threshold = int.tryParse(thresholdText.trim());
  if (threshold == null) {
    return (values: null, error: 'الحد الأدنى يجب أن يكون رقماً صحيحاً');
  }
  if (threshold < 0) {
    return (values: null, error: 'الحد الأدنى لا يمكن أن يكون سالباً');
  }

  final trimmedUnit = unit.trim();
  if (trimmedUnit.isEmpty) {
    return (values: null, error: 'الوحدة مطلوبة');
  }

  return (
    values: InventoryFormValues(
      name: trimmedName,
      quantity: quantity,
      lowStockThreshold: threshold,
      unit: trimmedUnit,
    ),
    error: null,
  );
}

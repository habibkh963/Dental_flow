class ClinicExpenseCategory {
  const ClinicExpenseCategory({required this.id, required this.label});

  final String id;
  final String label;

  static const laboratories = ClinicExpenseCategory(
    id: 'laboratories',
    label: 'مخابر',
  );
  static const dentalMaterials = ClinicExpenseCategory(
    id: 'dental_materials',
    label: 'مواد سنية',
  );
  static const consumables = ClinicExpenseCategory(
    id: 'consumables',
    label: 'مواد استهلاكية',
  );
  static const workerSalaries = ClinicExpenseCategory(
    id: 'worker_salaries',
    label: 'رواتب عمال',
  );
  static const cleaning = ClinicExpenseCategory(
    id: 'cleaning',
    label: 'تنظيف العيادة',
  );
  static const other = ClinicExpenseCategory(
    id: 'other',
    label: 'أخرى',
  );

  static const all = [
    laboratories,
    dentalMaterials,
    consumables,
    workerSalaries,
    cleaning,
    other,
  ];

  static ClinicExpenseCategory byId(String? id) {
    if (id == null || id.isEmpty) return other;
    switch (id) {
      case 'laboratories':
      case 'lab':
        return laboratories;
      case 'dental_materials':
        return dentalMaterials;
      case 'consumables':
      case 'supplies':
        return consumables;
      case 'worker_salaries':
      case 'salary':
        return workerSalaries;
      case 'cleaning':
        return cleaning;
      case 'other':
        return other;
      default:
        return other;
    }
  }
}

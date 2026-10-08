class PatientCondition {
  final String id;
  final String patientId;
  final String conditionName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PatientCondition({
    required this.id,
    required this.patientId,
    required this.conditionName,
    this.createdAt,
    this.updatedAt,
  });

  factory PatientCondition.fromMap(Map<String, dynamic> map) {
    return PatientCondition(
      id: map['id']?.toString() ?? '',
      patientId: map['patient_id']?.toString() ?? '',
      conditionName: map['condition_name']?.toString() ?? '',
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null || value.toString().isEmpty) return null;
    return DateTime.tryParse(value.toString());
  }
}

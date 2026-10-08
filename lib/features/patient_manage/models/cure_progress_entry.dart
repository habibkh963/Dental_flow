class CureProgressEntry {
  final String id;
  final String conditionId;
  final DateTime recordedAt;
  final int cureLevel;
  final String notes;
  final String audioPath;

  const CureProgressEntry({
    required this.id,
    required this.conditionId,
    required this.recordedAt,
    required this.cureLevel,
    this.notes = '',
    this.audioPath = '',
  });

  bool get hasAudio => audioPath.isNotEmpty;

  factory CureProgressEntry.fromMap(Map<String, dynamic> map) {
    final recordedRaw = map['recorded_at']?.toString() ?? '';
    return CureProgressEntry(
      id: map['id']?.toString() ?? '',
      conditionId: map['condition_id']?.toString() ?? '',
      recordedAt: DateTime.tryParse(recordedRaw) ?? DateTime.now(),
      cureLevel: (map['cure_level'] as num?)?.toInt() ?? 0,
      notes: map['notes']?.toString() ?? '',
      audioPath: map['audio_path']?.toString() ?? '',
    );
  }
}

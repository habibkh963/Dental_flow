List<String> parseCommaSeparatedItems(String? raw) {
  if (raw == null || raw.trim().isEmpty) return [];
  return raw
      .split(RegExp(r'[,،]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}

List<String> parseTreatmentPlanItems(
  String? raw, {
  Iterable<String> excludeLabels = const [],
}) {
  final exclude = excludeLabels
      .map((e) => e.trim().toLowerCase())
      .where((e) => e.isNotEmpty)
      .toSet();
  return parseCommaSeparatedItems(raw)
      .where((item) => !exclude.contains(item.toLowerCase()))
      .toList();
}

List<String> parseMedicalConditions(String? raw) =>
    parseCommaSeparatedItems(raw);

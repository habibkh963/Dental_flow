import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/colors.dart';

/// اختيار نوع التمثيل/العلاج: شرائح + نص مخصص (بدون قائمة منسدلة).
class TreatmentPresentationPicker extends StatelessWidget {
  const TreatmentPresentationPicker({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.customController,
    this.customHint = 'أو اكتب وصفاً مخصصاً...',
    this.allowMultiple = true,
    this.emptyHint,
  });

  final String title;
  final List<String> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  final TextEditingController? customController;
  final String customHint;
  final bool allowMultiple;
  final String? emptyHint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.mainColor,
          ),
        ),
        const SizedBox(height: 10),
        if (options.isEmpty && (emptyHint?.isNotEmpty ?? false))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              emptyHint!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((label) {
            final isSelected = selected.contains(label);
            return FilterChip(
              label: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: isSelected ? Colors.white : AppColors.mainColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              selected: isSelected,
              onSelected: (value) {
                final next = List<String>.from(selected);
                if (value) {
                  if (allowMultiple) {
                    if (!next.contains(label)) next.add(label);
                  } else {
                    next
                      ..clear()
                      ..add(label);
                  }
                } else {
                  next.remove(label);
                }
                onChanged(next);
              },
              backgroundColor: Colors.white,
              selectedColor: AppColors.mainColor,
              side: BorderSide(
                color: isSelected
                    ? AppColors.mainColor
                    : AppColors.mainColor.withValues(alpha: 0.3),
              ),
            );
          }).toList(),
        ),
        if (customController != null) ...[
          const SizedBox(height: 12),
          TextField(
            controller: customController,
            decoration: InputDecoration(
              hintText: customHint,
              hintStyle: GoogleFonts.poppins(fontSize: 12),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (text) => _addCustom(text),
          ),
        ],
      ],
    );
  }

  void _addCustom(String text) {
    final v = text.trim();
    if (v.isEmpty) return;
    final next = List<String>.from(selected);
    if (!next.contains(v)) {
      if (allowMultiple) {
        next.add(v);
      } else {
        next
          ..clear()
          ..add(v);
      }
      onChanged(next);
    }
    customController?.clear();
  }
}

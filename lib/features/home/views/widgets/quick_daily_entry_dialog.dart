import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors.dart';
import '../../../../core/currency_utils.dart';
import '../../../../services/database_service.dart';
import '../../../shared/widgets/amount_with_currency_field.dart';
import '../../../shared/widgets/app_dialog_shell.dart';
import '../../../inventory_manage/views/widgets/inventory_form_field.dart';
import '../../../settings_manage/controllers/app_currency_controller.dart';
import '../../controllers/dash_board_controller.dart';

Future<void> showQuickDailyEntryDialog(BuildContext context) async {
  await showAppStyledDialog<void>(
    context: context,
    title: 'إيراد أو مصروف يومي',
    subtitle: 'يُدرج في حركة اليوم المختارة في الرئيسية',
    width: 440,
    actions: const [],
    body: const _QuickDailyEntryForm(),
  );
}

class _QuickDailyEntryForm extends StatefulWidget {
  const _QuickDailyEntryForm();

  @override
  State<_QuickDailyEntryForm> createState() => _QuickDailyEntryFormState();
}

class _QuickDailyEntryFormState extends State<_QuickDailyEntryForm> {
  final amountController = TextEditingController();
  final noteController = TextEditingController();
  var isIncome = true;
  late String currencyCode;
  String? attachmentPath;
  var saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    currencyCode = Get.isRegistered<AppCurrencyController>()
        ? Get.find<AppCurrencyController>().code.value
        : 'SYP';
    if (!kInputCurrencyCodes.contains(currencyCode)) {
      currencyCode = 'SYP';
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      setState(() => error = 'أدخل مبلغاً صحيحاً');
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });

    final day = Get.isRegistered<DashBoardController>()
        ? Get.find<DashBoardController>().selectedLedgerDay.value
        : DateTime.now();

    try {
      await DatabaseService.instance.addDailyLedgerEntry({
        'entry_type': isIncome ? 'income' : 'expense',
        'amount': amount,
        'currency': currencyCode,
        'note': noteController.text.trim(),
        'attachment_path': attachmentPath ?? '',
        'entry_date': DateTime(day.year, day.month, day.day, 12)
            .toIso8601String(),
      });
      if (Get.isRegistered<DashBoardController>()) {
        await Get.find<DashBoardController>().loadDayLedger(day);
        await Get.find<DashBoardController>().refresh();
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      setState(() {
        saving = false;
        error = 'تعذر الحفظ';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: Text('إيراد', style: GoogleFonts.poppins(fontSize: 12)),
              selected: isIncome,
              selectedColor: Colors.green.shade100,
              onSelected: (_) => setState(() => isIncome = true),
            ),
            ChoiceChip(
              label: Text('مصروف', style: GoogleFonts.poppins(fontSize: 12)),
              selected: !isIncome,
              selectedColor: Colors.red.shade100,
              onSelected: (_) => setState(() => isIncome = false),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AmountWithCurrencyField(
          amountController: amountController,
          selectedCurrencyCode: currencyCode,
          onCurrencyChanged: (c) => setState(() => currencyCode = c),
          onAmountChanged: (_) => setState(() => error = null),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: noteController,
          maxLines: 3,
          decoration: inventoryFieldDecoration('ملاحظة (لماذا تم الدفع؟)'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: saving
              ? null
              : () async {
                  final result =
                      await FilePicker.platform.pickFiles(type: FileType.image);
                  if (result != null && result.files.isNotEmpty) {
                    setState(() {
                      attachmentPath = result.files.first.path ?? '';
                    });
                  }
                },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.mainColor,
            side: BorderSide(color: AppColors.mainColor.withValues(alpha: 0.35)),
          ),
          icon: const Icon(Icons.photo_outlined, size: 20),
          label: Text(
            attachmentPath?.isNotEmpty == true
                ? 'تم اختيار صورة'
                : 'إرفاق صورة (اختياري)',
            style: GoogleFonts.poppins(fontSize: 12),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(
            error!,
            style: GoogleFonts.poppins(
              color: AppColors.cancelledColor,
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: saving ? null : () => Navigator.of(context).pop(),
              child: Text('إلغاء', style: GoogleFonts.poppins()),
            ),
            const SizedBox(width: 8),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.mainColor),
              onPressed: saving ? null : _save,
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('حفظ', style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        ),
      ],
    );
  }
}
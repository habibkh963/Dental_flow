
class InvoiceFormValues {
  final String patientId;
  final String typeOfTreatment;
  final double total;
  final String status;

  const InvoiceFormValues({
    required this.patientId,
    required this.typeOfTreatment,
    required this.total,
    required this.status,
  });
}

class PaymentFormValues {
  final double amount;
  final String method;
  final String note;

  const PaymentFormValues({
    required this.amount,
    required this.method,
    required this.note,
  });
}

const kPaymentMethods = ['نقدي', 'بطاقة', 'تحويل'];

({InvoiceFormValues? values, String? error}) tryParseInvoiceForm({
  required String? patientId,
  required List<String> selectedTreatments,
  required String priceText,
  required bool isEstimated,
}) {
  if (patientId == null || patientId.trim().isEmpty) {
    return (values: null, error: 'يجب اختيار أو إدخال اسم المريض');
  }

  if (selectedTreatments.isEmpty) {
    return (values: null, error: 'يجب اختيار نوع علاج واحد على الأقل');
  }

  final total = double.tryParse(priceText.trim());
  if (total == null) {
    return (values: null, error: 'السعر يجب أن يكون رقماً');
  }
  if (total <= 0) {
    return (values: null, error: 'السعر يجب أن يكون أكبر من صفر');
  }

  return (
    values: InvoiceFormValues(
      patientId: patientId.trim(),
      typeOfTreatment: selectedTreatments.join(' , '),
      total: total,
      status: isEstimated ? 'estimated' : 'pending',
    ),
    error: null,
  );
}

({PaymentFormValues? values, String? error}) tryParsePaymentForm({
  required String amountText,
  required double remainingBalance,
  required String method,
  required String note,
}) {
  if (remainingBalance <= 0) {
    return (values: null, error: 'الفاتورة مدفوعة بالكامل');
  }

  final amount = double.tryParse(amountText.trim());
  if (amount == null) {
    return (values: null, error: 'المبلغ يجب أن يكون رقماً');
  }
  if (amount <= 0) {
    return (values: null, error: 'المبلغ يجب أن يكون أكبر من صفر');
  }
  if (amount > remainingBalance + 0.001) {
    return (
      values: null,
      error:
          'المبلغ يتجاوز المتبقي (${remainingBalance.toStringAsFixed(2)} ل.س)',
    );
  }

  final trimmedMethod = method.trim();
  if (trimmedMethod.isEmpty) {
    return (values: null, error: 'طريقة الدفع مطلوبة');
  }

  return (
    values: PaymentFormValues(
      amount: amount,
      method: trimmedMethod,
      note: note.trim(),
    ),
    error: null,
  );
}

double sumTreatmentPrices(
  List<String> treatmentNames,
  List<Map<String, dynamic>> catalog,
) {
  var sum = 0.0;
  for (final name in treatmentNames) {
    for (final treatment in catalog) {
      if (treatment['name']?.toString().trim().toLowerCase() ==
          name.trim().toLowerCase()) {
        sum += (treatment['price'] as num?)?.toDouble() ?? 0;
        break;
      }
    }
  }
  return sum;
}

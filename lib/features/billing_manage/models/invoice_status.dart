import 'package:flutter/material.dart';

import '../../../core/colors.dart';

enum InvoiceStatus {
  pending,
  estimated,
  paid,
  cancelled,
}

extension InvoiceStatusParsing on InvoiceStatus {
  static InvoiceStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'paid':
        return InvoiceStatus.paid;
      case 'cancelled':
        return InvoiceStatus.cancelled;
      case 'estimated':
        return InvoiceStatus.estimated;
      default:
        return InvoiceStatus.pending;
    }
  }

  String get storageValue {
    switch (this) {
      case InvoiceStatus.paid:
        return 'paid';
      case InvoiceStatus.cancelled:
        return 'cancelled';
      case InvoiceStatus.estimated:
        return 'estimated';
      case InvoiceStatus.pending:
        return 'pending';
    }
  }

  String get label {
    switch (this) {
      case InvoiceStatus.paid:
        return 'مدفوع';
      case InvoiceStatus.cancelled:
        return 'ملغي';
      case InvoiceStatus.estimated:
        return 'تقديري';
      case InvoiceStatus.pending:
        return 'قيد الانتظار';
    }
  }

  Color get color {
    switch (this) {
      case InvoiceStatus.paid:
        return const Color(0xFF264653);
      case InvoiceStatus.cancelled:
        return const Color(0xFFE76F51);
      case InvoiceStatus.estimated:
        return const Color(0xFFE9C46A);
      case InvoiceStatus.pending:
        return AppColors.mainColor;
    }
  }
}

InvoiceStatus resolveInvoiceStatus({
  required String? storedStatus,
  required double remainingBalance,
}) {
  if (remainingBalance <= 0) return InvoiceStatus.paid;
  return InvoiceStatusParsing.fromString(storedStatus);
}

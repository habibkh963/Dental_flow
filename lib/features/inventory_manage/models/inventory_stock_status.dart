import '../../../core/colors.dart';
import 'package:flutter/material.dart';

/// Stock level derived from quantity vs per-item low-stock threshold.
enum InventoryStockStatus {
  /// qty == 0
  outOfStock,

  /// 0 < qty <= threshold
  low,

  /// qty > threshold
  good,
}

extension InventoryStockStatusX on InventoryStockStatus {
  String get labelAr {
    switch (this) {
      case InventoryStockStatus.outOfStock:
        return 'نفذ';
      case InventoryStockStatus.low:
        return 'منخفض';
      case InventoryStockStatus.good:
        return 'جيد';
    }
  }

  Color get color {
    switch (this) {
      case InventoryStockStatus.outOfStock:
        return AppColors.cancelledColor;
      case InventoryStockStatus.low:
        return AppColors.pendingColor;
      case InventoryStockStatus.good:
        return AppColors.approvedColor;
    }
  }
}

/// Resolves stock status from quantity and threshold boundaries.
InventoryStockStatus resolveStockStatus({
  required int quantity,
  required int lowStockThreshold,
}) {
  if (quantity <= 0) return InventoryStockStatus.outOfStock;
  if (quantity <= lowStockThreshold) return InventoryStockStatus.low;
  return InventoryStockStatus.good;
}

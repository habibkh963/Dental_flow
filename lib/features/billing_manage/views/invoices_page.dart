import 'package:dental_managment_system/core/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

import '../../patient_manage/views/widgets/invoice_dialog.dart';
import '../controllers/invoices_controller.dart';
import 'widgets/payment_dialog.dart';

class InvoicesPage extends StatelessWidget {
  const InvoicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _InvoicesPageBody();
  }
}

class _InvoicesPageBody extends StatefulWidget {
  const _InvoicesPageBody();

  @override
  State<_InvoicesPageBody> createState() => _InvoicesPageBodyState();
}

class _InvoicesPageBodyState extends State<_InvoicesPageBody> {
  final ctrl = Get.put(
    InvoicesController(),
    permanent: false,
    tag: UniqueKey().toString(),
  );

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'paid':
        return const Color(0xFF264653);
      case 'cancelled':
        return const Color(0xFFE76F51);
      case 'pending':
        return AppColors.mainColor;
      default:
        return const Color(0xFFE9C46A);
    }
  }

  String _statusText(String s) {
    switch (s.toLowerCase()) {
      case 'paid':
        return 'مدفوع';
      case 'cancelled':
        return 'ملغي';
      case 'pending':
        return 'قيد الانتظار';
      default:
        return s;
    }
  }

  @override
  void initState() {
    super.initState();
    ctrl.loadAll();
  }

  Future<double> _getBalance(String invoiceId) async {
    return await ctrl.getRemaining(invoiceId);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 العنوان
            Row(
              children: [
                Text(
                  "الفواتير",
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 20.w),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintStyle: GoogleFonts.poppins(
                        color: AppColors.mainColor,
                      ),

                      hintText: 'ابحث عن اسم المريض...',
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.mainColor,
                      ),
                    ),
                    onChanged: (value) {
                      ctrl.filterInvoices(value); // تابع الفلترة
                    },
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () async {
                    openInvoiceDialog(context, null).then((value) {
                      ctrl.reload();
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: Text("فاتورة جديدة", style: GoogleFonts.poppins()),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.mainColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 26),

            /// 🔹 رأس الجدول
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.white.withOpacity(0.9),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.mainColor.withOpacity(0.1),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      "المريض",
                      style: GoogleFonts.poppins(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "المبلغ",
                      style: GoogleFonts.poppins(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "الحالة",
                      style: GoogleFonts.poppins(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "تاريخ الإصدار",
                      style: GoogleFonts.poppins(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "الإجراءات",
                      style: GoogleFonts.poppins(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: Obx(() {
                if (ctrl.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (ctrl.filteredInvoices.isEmpty) {
                  return Center(
                    child: Text(
                      'لا يوجد فواتير بعد',
                      style: GoogleFonts.poppins(),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 10),
                  itemCount: ctrl.filteredInvoices.length,
                  itemBuilder: (_, i) {
                    final inv = ctrl.filteredInvoices[i];
                    final status = inv['status'] ?? 'pending';
                    final color = _statusColor(status);
                    final patientName = ctrl.getPatientName(
                      inv['patient_id'] ?? '',
                      ctrl.patients,
                    );

                    return GestureDetector(
                      onTap: () async {
                        await _showInvoiceDetailsDialog(
                          context,
                          inv,
                          patientName,
                        );
                        await ctrl.reload();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white,
                          border: Border.all(color: color.withOpacity(.4)),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(.15),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            /// المريض
                            Expanded(
                              flex: 2,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: color,
                                    child: const Icon(
                                      Icons.receipt_long,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      patientName,
                                      style: GoogleFonts.poppins(),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Expanded(
                              child: FutureBuilder<double>(
                                future: _getBalance(inv['id'].toString()),
                                builder: (_, snap) {
                                  if (!snap.hasData) {
                                    return Text(
                                      '-',
                                      style: GoogleFonts.poppins(),
                                      textAlign: TextAlign.center,
                                    );
                                  }
                                  return Text(
                                    '${snap.data!.toStringAsFixed(2)} ل.س',
                                    style: GoogleFonts.poppins(),
                                    textAlign: TextAlign.center,
                                  );
                                },
                              ),
                            ),

                            /// الحالة
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 6,
                                ),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _statusText(status),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 15.h),

                            /// التاريخ
                            Expanded(
                              child: Text(
                                intl.DateFormat(
                                      'yyyy - MM - d  \n hh:mm a',
                                      'ar',
                                    )
                                    .format(
                                      DateTime.tryParse(
                                            inv['issued_at'] ?? '',
                                          ) ??
                                          DateTime.now(),
                                    )
                                    .toString(),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(),
                              ),
                            ),

                            /// أزرار
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: color),
                                    onPressed: () async {
                                      await _showInvoiceDetailsDialog(
                                        context,
                                        inv,
                                        patientName,
                                      );
                                      await ctrl.reload();
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: Text(
                                            'حذف الفاتورة؟',
                                            style: GoogleFonts.poppins(),
                                          ),
                                          content: Text(
                                            'هل أنت متأكد من الحذف؟',
                                            style: GoogleFonts.poppins(),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: Text(
                                                'إلغاء',
                                                style: GoogleFonts.poppins(),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: Text(
                                                'حذف',
                                                style: GoogleFonts.poppins(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        await ctrl.deleteInvoice(inv['id']);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showNoPatientDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('إنشاء فاتورة', style: GoogleFonts.poppins()),
        content: Text(
          'يرجى الدخول إلى ملف المريض وإنشاء الفاتورة من هناك.',
          style: GoogleFonts.poppins(),
        ),
      ),
    );
  }

  Future<void> _showInvoiceDetailsDialog(
    BuildContext context,
    Map<String, dynamic> invoice,
    String patientName,
  ) async {
    await openPaymentDialog(context, invoice, patientName);
  }
}

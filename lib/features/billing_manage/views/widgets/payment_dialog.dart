import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

import '../../../../core/colors.dart';
import '../../../../services/database_service.dart';

Future<void> openPaymentDialog(
  BuildContext context,
  Map<String, dynamic> invoice,
  String patientName,
) async {
  await showDialog(
    context: context,

    builder: (_) => _PaymentDialog(invoice: invoice, patientName: patientName),
  );
}

class _PaymentDialog extends StatefulWidget {
  final Map<String, dynamic> invoice;
  final String patientName;

  const _PaymentDialog({required this.invoice, required this.patientName});

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  late Future<List<Map<String, dynamic>>> _linesFuture;
  late Future<List<Map<String, dynamic>>> _paymentsFuture;
  late Future<double> _balanceFuture;
  late Future<List<Map<String, dynamic>>> _inventoryFuture;

  final noteController = TextEditingController();

  final priceC = TextEditingController();

  String payMethod = 'نقدي';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _linesFuture = DatabaseService.instance.getInvoiceLines(
      widget.invoice['id'],
    );
    _paymentsFuture = DatabaseService.instance.getPayments(
      widget.invoice['id'],
    );
    _balanceFuture = DatabaseService.instance.getInvoiceBalance(
      widget.invoice['id'],
    );
    _inventoryFuture = DatabaseService.instance.getInventory();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          width: MediaQuery.widthOf(context) * 0.7,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// العنوان
                Text(
                  'فاتورة المريض: ${widget.patientName}',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.mainColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'رقم الفاتورة: ${widget.invoice['id']}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),

                const SizedBox(height: 20),

                /// الإجمالي
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.mainColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: FutureBuilder<double>(
                    future: _balanceFuture,
                    builder: (_, snap) {
                      if (!snap.hasData)
                        return Text('-', style: GoogleFonts.poppins());
                      final bal = snap.data!;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'المبلغ المتبقي',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${bal.toStringAsFixed(2)} ل.س',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            bal <= 0 ? Icons.check_circle : Icons.warning_amber,
                            color: bal <= 0 ? Colors.green : Colors.orange,
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // /// المواد
                // _sectionTitle('المواد المستخدمة'),
                // _buildLines(),
                const SizedBox(height: 24),
                // _buildAddMaterial(),
                _sectionTitle('إضافة دفعة'),
                const SizedBox(height: 10),
                _buildAddPayment(),
                const SizedBox(height: 24),

                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,

                  child: TextFormField(
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    maxLines: null,
                    minLines: 20,
                    controller: noteController,

                    decoration: _dec('ملاحظة', isMulti: true),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.mainColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () async {
                        final amt = double.tryParse(priceC.text.trim()) ?? 0.0;
                        if (amt <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'أدخل مبلغ حقيقي',
                                style: GoogleFonts.poppins(),
                              ),
                            ),
                          );
                          return;
                        }
                        await DatabaseService.instance.addPayment({
                          'invoice_id': widget.invoice['id'],
                          'amount': amt,
                          'method': payMethod,
                          'note': noteController.text,
                        });
                        priceC.clear();
                        _reload();
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'تم تسجيل عملية الدفع',
                              style: GoogleFonts.poppins(),
                            ),
                          ),
                        );
                      },
                      child: Text('دفع ', style: GoogleFonts.poppins()),
                    ),
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text('إغلاق', style: GoogleFonts.poppins()),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                _sectionTitle('الدفعات'),

                _buildPayments(),

                const SizedBox(height: 24),

                /// إضافة دفعة
                /// الدفعات
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================== Widgets ==================

  Widget _sectionTitle(String text) => Text(
    text,
    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
  );

  Widget _buildLines() {
    return FutureBuilder(
      future: _linesFuture,
      builder: (_, snap) {
        if (!snap.hasData) return const CircularProgressIndicator();

        final lines = snap.data as List;

        if (lines.isEmpty) {
          return Padding(
            padding: EdgeInsets.all(12),
            child: Text('لا توجد مواد مضافة', style: GoogleFonts.poppins()),
          );
        }

        return Column(
          children: lines.map((l) {
            return ListTile(
              title: Text(l['material_name'], style: GoogleFonts.poppins()),
              subtitle: Text(
                '${l['quantity']} × ${l['unit_price']} = ${l['line_total']}',
                style: GoogleFonts.poppins(),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  await DatabaseService.instance.deleteInvoiceLine(l['id']);
                  _reload();
                  setState(() {});
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPayments() {
    return FutureBuilder(
      future: _paymentsFuture,
      builder: (_, snap) {
        if (!snap.hasData) return const CircularProgressIndicator();
        final list = snap.data as List;

        if (list.isEmpty) {
          return Text('لا يوجد دفعات بعد', style: GoogleFonts.poppins());
        }

        return Column(
          children: list.map((p) {
            return ListTile(
              title: Text('${p['amount']} ل.س', style: GoogleFonts.poppins()),
              subtitle: Text(p['method'], style: GoogleFonts.poppins()),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  await DatabaseService.instance.deletePayment(p['id']);
                  _reload();
                  setState(() {});
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildAddPayment() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: priceC,
            decoration: _dec('المبلغ'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: payMethod,
            decoration: _dec('طريقة الدفع'),
            items: [
              DropdownMenuItem(
                value: 'نقدي',
                child: Text('نقدي', style: GoogleFonts.poppins()),
              ),
            ],
            onChanged: (v) => setState(() => payMethod = v!),
          ),
        ),
      ],
    );
  }

  InputDecoration _dec(String hint, {bool isMulti = false}) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    constraints: isMulti ? BoxConstraints(maxHeight: 150.w) : null,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
  );
}

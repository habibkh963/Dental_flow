import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

import 'package:dental_managment_system/services/database_service.dart';

Future<void> openInvoiceDialog(
  BuildContext context,
  Map<String, dynamic> patient, {
  String? invoiceId,
}) async {
  final descriptionC = TextEditingController();
  final qtyC = TextEditingController(text: '1');
  final priceC = TextEditingController(text: '0');
  final payAmountC = TextEditingController(text: '0');
  String payMethod = 'cash';

  List<Map<String, dynamic>> lines = [];

  double computeTotal() {
    return lines.fold(0.0, (p, e) => p + (e['line_total'] as double));
  }

  // If editing existing invoice, load lines
  if (invoiceId != null) {
    final existingLines = await DatabaseService.instance.getInvoiceLines(
      invoiceId,
    );
    lines = existingLines
        .map(
          (l) => {
            'id': l['id'],
            'description': l['description'],
            'quantity': l['quantity'],
            'unit_price': (l['unit_price'] as num).toDouble(),
            'line_total': (l['line_total'] as num).toDouble(),
          },
        )
        .toList();
  }

  await showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (ctx, setState) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 700,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Invoice for ${patient['first_name'] ?? ''} ${patient['last_name'] ?? ''}',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // Add line inputs
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: TextField(
                      controller: descriptionC,
                      decoration: _dec('Description'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: qtyC,
                      decoration: _dec('Qty'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: priceC,
                      decoration: _dec('Unit price'),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A9D8F),
                    ),
                    onPressed: () {
                      final desc = descriptionC.text.trim();
                      final qty = int.tryParse(qtyC.text.trim()) ?? 1;
                      final price = double.tryParse(priceC.text.trim()) ?? 0.0;
                      if (desc.isEmpty) return;
                      final lt = qty * price;
                      lines.add({
                        'description': desc,
                        'quantity': qty,
                        'unit_price': price,
                        'line_total': lt,
                      });
                      descriptionC.clear();
                      qtyC.text = '1';
                      priceC.text = '0';
                      setState(() {});
                    },
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Lines list
              if (lines.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: lines.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final l = lines[i];
                      return ListTile(
                        title: Text(l['description']),
                        subtitle: Text('${l['quantity']} x ${l['unit_price']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              (l['line_total'] as double).toStringAsFixed(2),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                lines.removeAt(i);
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 12),
              // Totals & payment
              Row(
                children: [
                  Expanded(child: Container()),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Subtotal: ${computeTotal().toStringAsFixed(2)}'),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 120,
                            child: TextField(
                              controller: payAmountC,
                              decoration: _dec('Payment amount'),
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: payMethod,
                            items: ['cash', 'card', 'transfer']
                                .map(
                                  (m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(m),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              payMethod = v;
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A9D8F),
                    ),
                    onPressed: () async {
                      final total = computeTotal();
                      // create invoice
                      final invId =
                          invoiceId ??
                          await DatabaseService.instance.addInvoice({
                            'patient_id': patient['id'],
                            'total': total,
                            'status': 'pending',
                          });
                      // add lines
                      for (final l in lines) {
                        await DatabaseService.instance.addInvoiceLine({
                          'invoice_id': invId,
                          'description': l['description'],
                          'quantity': l['quantity'],
                          'unit_price': l['unit_price'],
                        });
                      }
                      // payment
                      final payAmt =
                          double.tryParse(payAmountC.text.trim()) ?? 0.0;
                      if (payAmt > 0) {
                        await DatabaseService.instance.addPayment({
                          'invoice_id': invId,
                          'amount': payAmt,
                          'method': payMethod,
                          'note': 'Payment from invoice dialog',
                        });
                      }
                      // set status paid if balance <= 0
                      final balance = await DatabaseService.instance
                          .getInvoiceBalance(invId);
                      if (balance <= 0) {
                        await DatabaseService.instance.updateInvoice(invId, {
                          'status': 'paid',
                        });
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invoice saved')),
                      );
                      Get.back();
                    },
                    child: const Text('Save Invoice'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

InputDecoration _dec(String hint) => InputDecoration(
  hintText: hint,
  filled: true,
  fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide.none,
  ),
);

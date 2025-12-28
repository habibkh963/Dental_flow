import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

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

  final amountC = TextEditingController();
  final qtyC = TextEditingController(text: '1');
  final priceC = TextEditingController();
  String payMethod = 'cash';
  String? _selectedMaterialId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
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
  void dispose() {
    amountC.dispose();
    qtyC.dispose();
    priceC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 800),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header
              Text(
                'Invoice for ${widget.patientName}',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2A9D8F),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Invoice: ${widget.invoice['id']}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              /// Total and Balance
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A9D8F).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF2A9D8F).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Invoice:',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FutureBuilder<double>(
                          future: _balanceFuture,
                          builder: (_, snap) {
                            if (!snap.hasData) {
                              return Text(
                                '-',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              );
                            }
                            final remaining = snap.data!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '\$${remaining.toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Remaining',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey.withOpacity(0.3),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Balance:',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FutureBuilder<double>(
                          future: _balanceFuture,
                          builder: (_, snap) {
                            if (!snap.hasData) return const Text('-');
                            final bal = snap.data!;
                            return Text(
                              '\$${bal.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: bal <= 0 ? Colors.green : Colors.orange,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// Materials Section
              Text(
                'Materials Used',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              /// Materials List
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _linesFuture,
                  builder: (_, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final lines = snap.data!;

                    if (lines.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No materials yet',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: lines.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: Colors.grey.withOpacity(0.2),
                      ),
                      itemBuilder: (_, i) {
                        final line = lines[i];
                        final materialName = line['material_name'] ?? 'Item';
                        final qty = line['quantity'] ?? 0;
                        final price =
                            (line['unit_price'] as num?)?.toStringAsFixed(2) ??
                            '0.00';
                        final total =
                            (line['line_total'] as num?)?.toStringAsFixed(2) ??
                            '0.00';

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      materialName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$qty x \$$price = \$$total',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  await DatabaseService.instance
                                      .deleteInvoiceLine(line['id']);
                                  _loadData();
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              /// Add Material Section
              Text(
                'Add Material',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              FutureBuilder<List<Map<String, dynamic>>>(
                future: _inventoryFuture,
                builder: (_, snap) {
                  if (!snap.hasData) return const Text('Loading...');
                  final materials = snap.data!;

                  return Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedMaterialId,
                        items: materials
                            .map(
                              (m) => DropdownMenuItem<String>(
                                value: m['id'].toString(),
                                child: Text(
                                  '${m['name']} (Stock: ${m['qty']})',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _selectedMaterialId = v);
                            final mat = materials.firstWhere(
                              (m) => m['id'].toString() == v,
                              orElse: () => {},
                            );
                            priceC.text =
                                (mat['unit_price']?.toString() ?? '').isEmpty
                                ? ''
                                : mat['unit_price'].toString();
                          }
                        },
                        decoration: _dec('Select material'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: qtyC,
                              decoration: _dec('Qty'),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: priceC,
                              decoration: _dec('Price'),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF2A9D8F),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onPressed: () async {
                              if (_selectedMaterialId == null ||
                                  qtyC.text.isEmpty ||
                                  priceC.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Fill all fields'),
                                  ),
                                );
                                return;
                              }

                              // Validate stock (do not decrement inventory here)
                              final requested = int.tryParse(qtyC.text) ?? 0;
                              final mat = materials.firstWhere(
                                (m) =>
                                    m['id'].toString() == _selectedMaterialId,
                                orElse: () => <String, dynamic>{},
                              );
                              final stock = (mat['qty'] ?? 0) as int;
                              if (requested > stock) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Requested quantity exceeds stock',
                                    ),
                                  ),
                                );
                                return;
                              }

                              await DatabaseService.instance.addInvoiceLine({
                                'invoice_id': widget.invoice['id'],
                                'material_id': _selectedMaterialId,
                                'description': 'Material',
                                'quantity': requested,
                                'unit_price': double.parse(priceC.text),
                              });

                              // decrement inventory
                              try {
                                final inv = await DatabaseService.instance
                                    .getInventory();
                                final mat = inv.firstWhere(
                                  (m) =>
                                      m['id'].toString() ==
                                      _selectedMaterialId.toString(),
                                  orElse: () => <String, dynamic>{},
                                );
                                final stock = (mat['qty'] ?? 0) as int;
                                final newStock = stock - requested;
                                await DatabaseService.instance
                                    .updateInventoryItem(_selectedMaterialId!, {
                                      'qty': newStock,
                                    });
                              } catch (_) {
                                // ignore
                              }

                              _selectedMaterialId = null;
                              qtyC.text = '1';
                              priceC.clear();
                              _loadData();
                              setState(() {});

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Material added')),
                              );
                            },
                            child: const Icon(Icons.add, size: 20),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              /// Payments Section
              Text(
                'Payments',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              /// Payments List
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _paymentsFuture,
                  builder: (_, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final payments = snap.data!;

                    if (payments.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No payments yet',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: payments.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: Colors.grey.withOpacity(0.2),
                      ),
                      itemBuilder: (_, i) {
                        final p = payments[i];
                        final amount =
                            (p['amount'] as num?)?.toStringAsFixed(2) ?? '0.00';
                        final method = p['method'] ?? 'cash';
                        final paidAt = p['paid_at'] ?? '-';
                        final dateStr = paidAt != '-' && paidAt.length > 10
                            ? paidAt.substring(0, 10)
                            : paidAt;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '\$$amount',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    method.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                dateStr,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  await DatabaseService.instance.deletePayment(
                                    p['id'],
                                  );
                                  _loadData();
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              /// Add Payment Section
              Text(
                'Add Payment',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: amountC,
                      decoration: _dec('Amount'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: payMethod,
                      items: ['cash', 'card', 'transfer']
                          .map(
                            (m) => DropdownMenuItem(value: m, child: Text(m)),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => payMethod = v);
                        }
                      },
                      decoration: _dec('Method'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              /// Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2A9D8F),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () async {
                      final amt = double.tryParse(amountC.text.trim()) ?? 0.0;
                      if (amt <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Enter valid amount')),
                        );
                        return;
                      }

                      await DatabaseService.instance.addPayment({
                        'invoice_id': widget.invoice['id'],
                        'amount': amt,
                        'method': payMethod,
                        'note': 'Added via payment dialog',
                      });

                      // No DB change to invoice.total: keep original total and
                      // rely on getInvoiceBalance() to compute remaining amount.

                      amountC.clear();
                      _loadData();
                      setState(() {});

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Payment recorded')),
                      );
                    },
                    child: const Text('Add Payment'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

import '../../../../services/database_service.dart';

Future<void> openInvoiceDialog(
  BuildContext context,
  String patientId,
  String patientName,
) async {
  await showDialog(
    context: context,
    builder: (_) =>
        _InvoiceDialog(patientId: patientId, patientName: patientName),
  );
}

class _InvoiceDialog extends StatefulWidget {
  final String patientId;
  final String patientName;

  const _InvoiceDialog({required this.patientId, required this.patientName});

  @override
  State<_InvoiceDialog> createState() => _InvoiceDialogState();
}

class _InvoiceDialogState extends State<_InvoiceDialog> {
  late Future<List<Map<String, dynamic>>> _inventoryFuture;

  final List<Map<String, dynamic>> _lines = [];
  String? _selectedMaterialId;
  final qtyC = TextEditingController(text: '1');
  final priceC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _inventoryFuture = DatabaseService.instance.getInventory();
  }

  @override
  void dispose() {
    qtyC.dispose();
    priceC.dispose();
    super.dispose();
  }

  double _getTotal() {
    double total = 0;
    for (final line in _lines) {
      total += (line['line_total'] ?? 0) as num;
    }
    return total;
  }

  Future<void> _addLine() async {
    final materialId = _selectedMaterialId;
    final qty = int.tryParse(qtyC.text) ?? 0;
    final price = double.tryParse(priceC.text) ?? 0;

    if (materialId == null || qty <= 0 || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields correctly')),
      );
      return;
    }

    // Validate stock without modifying inventory
    try {
      final materials = await DatabaseService.instance.getInventory();
      final mat = materials.firstWhere(
        (m) => m['id'].toString() == materialId.toString(),
        orElse: () => <String, dynamic>{},
      );
      final stock = (mat['qty'] ?? 0) as int;
      if (qty > stock) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Requested quantity exceeds stock')),
        );
        return;
      }
    } catch (_) {
      // ignore and allow; defensive
    }

    setState(() {
      _lines.add({
        'material_id': materialId,
        'quantity': qty,
        'unit_price': price,
        'line_total': qty * price,
      });
      _selectedMaterialId = null;
      qtyC.text = '1';
      priceC.clear();
    });
  }

  void _removeLine(int index) {
    setState(() => _lines.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header
            Text(
              'New Invoice for ${widget.patientName}',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2A9D8F),
              ),
            ),
            const SizedBox(height: 20),

            /// Materials Selection
            Text(
              'Select Materials',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            /// Material Dropdown
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _inventoryFuture,
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Text('Loading materials...');
                }

                final materials = snap.data!;
                if (materials.isEmpty) {
                  return const Text('No materials available');
                }

                return DropdownButtonFormField<String>(
                  value: _selectedMaterialId,
                  items: materials
                      .map(
                        (m) => DropdownMenuItem<String>(
                          value: m['id'].toString(),
                          child: Text('${m['name']} (Stock: ${m['qty']})'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _selectedMaterialId = v);
                      // Auto-fill price from material
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
                  decoration: _dec('Select a material'),
                );
              },
            ),

            const SizedBox(height: 12),

            /// Quantity and Price
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
                    keyboardType: const TextInputType.numberWithOptions(
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
                  onPressed: _addLine,
                  child: const Icon(Icons.add, size: 20),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// Materials List
            if (_lines.isNotEmpty) ...[
              Text(
                'Materials in Invoice (${_lines.length})',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 250),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _lines.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                  itemBuilder: (_, i) {
                    final line = _lines[i];
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
                                  '${line['quantity']}x @ \$${(line['unit_price'] as num).toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Total: \$${(line['line_total'] as num).toStringAsFixed(2)}',
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
                            onPressed: () => _removeLine(i),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              /// Total
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
                    Text(
                      'Total Invoice:',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '\$${_getTotal().toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2A9D8F),
                      ),
                    ),
                  ],
                ),
              ),
            ] else
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    'No materials added yet',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            /// Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Cancel'),
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
                  onPressed: _lines.isEmpty
                      ? null
                      : () async {
                          // Validate stock for all lines before creating invoice
                          try {
                            final inventory = await DatabaseService.instance
                                .getInventory();
                            for (final line in _lines) {
                              final mat = inventory.firstWhere(
                                (m) =>
                                    m['id'].toString() ==
                                    line['material_id'].toString(),
                                orElse: () => <String, dynamic>{},
                              );
                              final stock = (mat['qty'] ?? 0) as int;
                              if ((line['quantity'] as int) > stock) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Requested quantity exceeds stock',
                                    ),
                                  ),
                                );
                                return;
                              }
                            }
                          } catch (_) {
                            // if inventory check fails, abort to be safe
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Inventory check failed'),
                              ),
                            );
                            return;
                          }

                          // Create invoice
                          final invoiceId = await DatabaseService.instance
                              .addInvoice({
                                'patient_id': widget.patientId,
                                'total': _getTotal(),
                                'status': 'pending',
                              });

                          // Add lines with materials and decrement inventory
                          for (final line in _lines) {
                            await DatabaseService.instance.addInvoiceLine({
                              'invoice_id': invoiceId,
                              'material_id': line['material_id'],
                              'description': 'Material',
                              'quantity': line['quantity'],
                              'unit_price': line['unit_price'],
                            });

                            // decrement inventory
                            try {
                              final inv = await DatabaseService.instance
                                  .getInventory();
                              final mat = inv.firstWhere(
                                (m) =>
                                    m['id'].toString() ==
                                    line['material_id'].toString(),
                                orElse: () => <String, dynamic>{},
                              );
                              final stock = (mat['qty'] ?? 0) as int;
                              final newStock =
                                  stock - (line['quantity'] as int);
                              await DatabaseService.instance
                                  .updateInventoryItem(
                                    line['material_id'].toString(),
                                    {'qty': newStock},
                                  );
                            } catch (_) {
                              // ignore inventory update errors
                            }
                          }

                          Get.back();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Invoice created successfully'),
                            ),
                          );
                        },
                  child: const Text('Create Invoice'),
                ),
              ],
            ),
          ],
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

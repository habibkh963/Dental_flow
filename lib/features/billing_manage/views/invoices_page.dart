import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

import '../../../services/database_service.dart';
import '../controllers/invoices_controller.dart';
import 'widgets/payment_dialog.dart';

class InvoicesPage extends StatelessWidget {
  const InvoicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _InvoicesPageBody();
  }
}

class _InvoicesPageBody extends StatefulWidget {
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
        return const Color(0xFF2A9D8F);
      default:
        return const Color(0xFFE9C46A);
    }
  }

  @override
  void initState() {
    super.initState();
    ctrl.loadAll();
  }

  String _getPatientName(
    String patientId,
    List<Map<String, dynamic>> patients,
  ) {
    try {
      final p = patients.firstWhere((x) => x['id'] == patientId);
      return '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.trim();
    } catch (_) {
      return '-';
    }
  }

  Future<double> _getBalance(String invoiceId) async {
    return await ctrl.getRemaining(invoiceId);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔹 Header
          Row(
            children: [
              Text(
                "Invoices",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _showNoPatientDialog(context),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  backgroundColor: const Color(0xFF2A9D8F),
                ),
                icon: const Icon(Icons.add),
                label: const Text('New Invoice'),
              ),
            ],
          ),

          const SizedBox(height: 26),

          /// 🔹 Table Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white.withOpacity(0.9),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2A9D8F).withOpacity(0.1),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text("Patient")),
                Expanded(child: Text("Total")),
                Expanded(child: Text("Status")),
                Expanded(child: Text("Issued")),
                Expanded(child: Text("Actions")),
              ],
            ),
          ),

          const SizedBox(height: 10),

          /// 🔹 Invoices List
          Expanded(
            child: Obx(() {
              if (ctrl.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final patients = ctrl.patients;
              final invoices = ctrl.invoices;

              if (invoices.isEmpty) {
                return const Center(child: Text('No invoices yet'));
              }

              return ListView.builder(
                padding: const EdgeInsets.only(top: 10),
                itemCount: invoices.length,
                itemBuilder: (_, i) {
                  final inv = invoices[i];
                  final status = inv['status'] ?? 'pending';
                  final color = _statusColor(status);
                  final patientId = inv['patient_id'] ?? '';
                  final patientName = _getPatientName(patientId, patients);
                  final issuedAt = inv['issued_at'] ?? '-';

                  return Container(
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
                        /// Patient
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: color,
                                child: const Icon(
                                  Icons.receipt_long,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(patientName)),
                            ],
                          ),
                        ),

                        /// Balance
                        Expanded(
                          child: FutureBuilder<double>(
                            future: _getBalance(inv['id'].toString()),
                            builder: (_, balSnap) {
                              if (!balSnap.hasData) return const Text('-');
                              return Text(
                                '${balSnap.data!.toStringAsFixed(2)} SYP',
                              );
                            },
                          ),
                        ),

                        /// Status
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            alignment: Alignment.center,
                            margin: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: color.withOpacity(.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        /// Issued Date
                        Expanded(
                          child: Text(
                            issuedAt.length > 10
                                ? issuedAt.substring(0, 10)
                                : issuedAt,
                          ),
                        ),

                        /// Actions
                        Expanded(
                          child: Row(
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
                                  color: Colors.redAccent,
                                ),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete Invoice?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: const Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true)
                                    await ctrl.deleteInvoice(inv['id']);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showNoPatientDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Invoice from Patient Profile'),
        content: const Text(
          'Please go to a patient\'s profile and use the "Invoice" button to create a new invoice.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
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

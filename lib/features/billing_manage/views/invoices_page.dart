import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/colors.dart';
import '../controllers/invoices_controller.dart';
import 'widgets/invoice_list_header.dart';
import 'widgets/invoice_tile.dart';

class InvoicesPage extends GetView<InvoicesController> {
  InvoicesPage({super.key}) : _tag = UniqueKey().toString() {
    Get.put(InvoicesController(), permanent: false, tag: _tag);
  }

  final String _tag;

  @override
  String? get tag => _tag;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 26),
            const InvoiceListHeader(),
            const SizedBox(height: 10),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          'الفواتير',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintStyle: GoogleFonts.poppins(color: AppColors.mainColor),
              hintText: 'ابحث عن اسم المريض...',
              prefixIcon: const Icon(Icons.search, color: AppColors.mainColor),
            ),
            onChanged: controller.filterInvoices,
          ),
        ),
        const SizedBox(width: 16),
        FilledButton.icon(
          onPressed: () => controller.openCreateInvoiceDialog(),
          icon: const Icon(Icons.add),
          label: Text('فاتورة جديدة', style: GoogleFonts.poppins()),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.mainColor,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.filteredInvoices.isEmpty) {
        final hasSearch = controller.searchQuery.value.trim().isNotEmpty;
        return Center(
          child: Text(
            hasSearch ? 'لا توجد نتائج للبحث' : 'لا يوجد فواتير بعد',
            style: GoogleFonts.poppins(fontSize: 18),
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.only(top: 10),
        itemCount: controller.filteredInvoices.length,
        itemBuilder: (_, index) {
          final invoice = controller.filteredInvoices[index];
          final patientName = controller.getPatientName(invoice.patientId);

          return InvoiceTile(
            invoice: invoice,
            patientName: patientName,
            onTap: () => controller.openPaymentDialog(invoice, patientName),
            onDelete: () =>
                controller.confirmDeleteInvoice(invoice, patientName),
          );
        },
      );
    });
  }
}

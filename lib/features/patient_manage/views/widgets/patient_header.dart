import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PatientHeader extends StatelessWidget {
  final VoidCallback onAdd;

  const PatientHeader({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'المرضى',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: Text(
            'إضافة مريض ',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

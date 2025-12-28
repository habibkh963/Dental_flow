import 'package:flutter/material.dart';

class PatientHeader extends StatelessWidget {
  final VoidCallback onAdd;

  const PatientHeader({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Patients',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Add Patient'),
        ),
      ],
    );
  }
}

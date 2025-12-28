import 'package:flutter/material.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reports', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: Text(
                'Reports feature coming soon...',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

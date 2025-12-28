import 'package:flutter/material.dart';

class UrgentAppointmentAlert extends StatefulWidget {
  final List<Map<String, dynamic>> urgentAppointments;
  final VoidCallback? onDismiss;

  const UrgentAppointmentAlert({
    required this.urgentAppointments,
    this.onDismiss,
    super.key,
  }) : super();

  @override
  State<UrgentAppointmentAlert> createState() => _UrgentAppointmentAlertState();
}

class _UrgentAppointmentAlertState extends State<UrgentAppointmentAlert>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.urgentAppointments.isEmpty) {
      return const SizedBox.shrink();
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[300]!, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚠️ Urgent Appointments',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.red[900],
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        '${widget.urgentAppointments.length} appointment${widget.urgentAppointments.length > 1 ? 's' : ''} in the next 30 minutes',
                        style: TextStyle(fontSize: 12, color: Colors.red[700]),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: widget.onDismiss,
                  child: Icon(Icons.close, color: Colors.red[700], size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Appointments list
            ...widget.urgentAppointments.map(
              (apt) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${apt['first_name']} ${apt['last_name']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '${apt['time']} • ${apt['phone'] ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

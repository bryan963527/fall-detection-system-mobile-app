import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/event_model.dart';

class EventRow extends StatelessWidget {
  final Event event;
  final VoidCallback onDetailsPressed;

  const EventRow({
    super.key,
    required this.event,
    required this.onDetailsPressed,
  });

  Color _getSeverityColor() {
    switch (event.severity) {
      case Severity.high:
        return AppColors.dangerRed;
      case Severity.medium:
        return AppColors.warningOrange;
      case Severity.low:
        return Color(0xFF42A5F5);
    }
  }

  Color _getStatusBackgroundColor() {
    switch (event.status) {
      case EventStatus.resolved:
        return Color(0xFFE8F5E9);
      case EventStatus.falseAlarm:
        return Color(0xFFFFE0B2);
      case EventStatus.completed:
        return Color(0xFFE3F2FD);
      case EventStatus.charged:
        return Color(0xFFF3E5F5);
      case EventStatus.restored:
        return Color(0xFFE8F5E9);
      case EventStatus.pending:
        return Color(0xFFF5F5F5);
    }
  }

  Color _getStatusTextColor() {
    switch (event.status) {
      case EventStatus.resolved:
        return AppColors.safeGreen;
      case EventStatus.falseAlarm:
        return AppColors.warningOrange;
      case EventStatus.completed:
        return AppColors.primary;
      case EventStatus.charged:
        return Color(0xFF7B1FA2);
      case EventStatus.restored:
        return AppColors.safeGreen;
      case EventStatus.pending:
        return AppColors.textMedium;
    }
  }

  IconData _getEventIcon() {
    switch (event.type) {
      case EventType.fallDetected:
        return Icons.warning;
      case EventType.inactivityAlert:
        return Icons.info;
      case EventType.systemCheck:
        return Icons.check_circle;
      case EventType.lowBattery:
        return Icons.battery_alert;
      case EventType.connectivityLost:
        return Icons.cloud_off;
      case EventType.normalMovement:
        return Icons.directions_run;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: _getSeverityColor(), width: 4)),
      ),
      child: Row(
        children: [
          // Event Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getSeverityColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(_getEventIcon(), color: _getSeverityColor(), size: 20),
          ),
          const SizedBox(width: 12),
          // Event Type
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.typeLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.id,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          // Date & Time
          Expanded(
            flex: 2,
            child: Text(
              event.formattedDate,
              style: const TextStyle(fontSize: 13, color: AppColors.textMedium),
            ),
          ),
          // Severity
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getSeverityColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              event.severityLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _getSeverityColor(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusBackgroundColor(),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              event.statusLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _getStatusTextColor(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Details Button
          GestureDetector(
            onTap: onDetailsPressed,
            child: Text(
              'Details',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

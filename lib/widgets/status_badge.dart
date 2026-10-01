import 'package:flutter/material.dart';
import '../models/equipment.dart';
import '../models/complaint.dart';
import '../theme/app_theme.dart';

class AvailabilityBadge extends StatelessWidget {
  final EquipmentAvailability availability;
  final bool compact;

  const AvailabilityBadge({
    super.key,
    required this.availability,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getAvailabilityColor(availability);
    final bg = AppTheme.getAvailabilityBg(availability);
    final label = AppTheme.getAvailabilityLabel(availability);

    IconData iconData;
    switch (availability) {
      case EquipmentAvailability.available:
        iconData = Icons.check_circle_rounded;
        break;
      case EquipmentAvailability.inUse:
        iconData = Icons.play_circle_fill_rounded;
        break;
      case EquipmentAvailability.reserved:
        iconData = Icons.bookmark_rounded;
        break;
      case EquipmentAvailability.underMaintenance:
        iconData = Icons.build_circle_rounded;
        break;
      case EquipmentAvailability.missing:
        iconData = Icons.warning_amber_rounded;
        break;
      case EquipmentAvailability.outOfService:
        iconData = Icons.cancel_rounded;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: compact ? 12 : 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class ComplaintStatusBadge extends StatelessWidget {
  final ComplaintStatus status;
  final bool compact;

  const ComplaintStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getComplaintStatusColor(status);
    final label = AppTheme.getComplaintStatusLabel(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class SeverityBadge extends StatelessWidget {
  final ComplaintSeverity severity;

  const SeverityBadge({super.key, required this.severity});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getSeverityColor(severity);
    String label;
    switch (severity) {
      case ComplaintSeverity.low:
        label = 'Low Priority';
        break;
      case ComplaintSeverity.medium:
        label = 'Medium';
        break;
      case ComplaintSeverity.high:
        label = 'High Priority';
        break;
      case ComplaintSeverity.emergency:
        label = 'CRITICAL / EMERGENCY';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

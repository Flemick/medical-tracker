enum NotificationType {
  complaintUpdate,
  equipmentStatusChange,
  maintenanceAlert,
  systemBroadcast,
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final String? relatedEquipmentId;
  final String? relatedComplaintId;
  final String? targetNurseId; // null if broadcast to all

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.relatedEquipmentId,
    this.relatedComplaintId,
    this.targetNurseId,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    String? relatedEquipmentId,
    String? relatedComplaintId,
    String? targetNurseId,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      relatedEquipmentId: relatedEquipmentId ?? this.relatedEquipmentId,
      relatedComplaintId: relatedComplaintId ?? this.relatedComplaintId,
      targetNurseId: targetNurseId ?? this.targetNurseId,
    );
  }
}

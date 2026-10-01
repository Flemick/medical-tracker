enum ComplaintType {
  equipmentProblem,
  missingEquipment,
  unavailableEquipment,
  other,
}

enum ComplaintSeverity {
  low,
  medium,
  high,
  emergency,
}

enum ComplaintStatus {
  submitted,
  underReview,
  assignedToTech,
  inProgress,
  resolved,
  escalated,
  rejected,
}

class ComplaintTimelineEvent {
  final String title;
  final String description;
  final DateTime timestamp;
  final String actorName;
  final String actorRole;

  const ComplaintTimelineEvent({
    required this.title,
    required this.description,
    required this.timestamp,
    required this.actorName,
    required this.actorRole,
  });
}

class ComplaintModel {
  final String id;
  final String ticketNumber; // e.g. "CMP-8041"
  final String equipmentId;
  final String equipmentName;
  final String equipmentCode;
  final String equipmentCategory;
  final ComplaintType type;
  final ComplaintSeverity severity;
  final ComplaintStatus status;
  final String nurseId;
  final String nurseName;
  final String nurseDepartment;
  final String reportedLocation; // Room, floor, ward where problem is located
  final String description;
  final String? errorCode;
  final DateTime reportedAt;
  final DateTime lastUpdatedAt;
  final String? assignedTechName;
  final String? resolutionSummary;
  final List<ComplaintTimelineEvent> timeline;

  const ComplaintModel({
    required this.id,
    required this.ticketNumber,
    required this.equipmentId,
    required this.equipmentName,
    required this.equipmentCode,
    required this.equipmentCategory,
    required this.type,
    required this.severity,
    required this.status,
    required this.nurseId,
    required this.nurseName,
    required this.nurseDepartment,
    required this.reportedLocation,
    required this.description,
    this.errorCode,
    required this.reportedAt,
    required this.lastUpdatedAt,
    this.assignedTechName,
    this.resolutionSummary,
    this.timeline = const [],
  });

  ComplaintModel copyWith({
    String? id,
    String? ticketNumber,
    String? equipmentId,
    String? equipmentName,
    String? equipmentCode,
    String? equipmentCategory,
    ComplaintType? type,
    ComplaintSeverity? severity,
    ComplaintStatus? status,
    String? nurseId,
    String? nurseName,
    String? nurseDepartment,
    String? reportedLocation,
    String? description,
    String? errorCode,
    DateTime? reportedAt,
    DateTime? lastUpdatedAt,
    String? assignedTechName,
    String? resolutionSummary,
    List<ComplaintTimelineEvent>? timeline,
  }) {
    return ComplaintModel(
      id: id ?? this.id,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      equipmentId: equipmentId ?? this.equipmentId,
      equipmentName: equipmentName ?? this.equipmentName,
      equipmentCode: equipmentCode ?? this.equipmentCode,
      equipmentCategory: equipmentCategory ?? this.equipmentCategory,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      nurseId: nurseId ?? this.nurseId,
      nurseName: nurseName ?? this.nurseName,
      nurseDepartment: nurseDepartment ?? this.nurseDepartment,
      reportedLocation: reportedLocation ?? this.reportedLocation,
      description: description ?? this.description,
      errorCode: errorCode ?? this.errorCode,
      reportedAt: reportedAt ?? this.reportedAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      assignedTechName: assignedTechName ?? this.assignedTechName,
      resolutionSummary: resolutionSummary ?? this.resolutionSummary,
      timeline: timeline ?? this.timeline,
    );
  }
}

enum EquipmentAvailability {
  available,
  inUse,
  reserved,
  underMaintenance,
  missing,
  outOfService,
}

enum OperationalStatus {
  optimal,
  minorIssue,
  criticalError,
  needsSanitizing,
}

enum MaintenanceHealth {
  good,
  routineDueSoon,
  calibrationOverdue,
  underRepair,
}

class EquipmentLocation {
  final String building;
  final String floor;
  final String department;
  final String room;
  final String? bedOrStation;

  const EquipmentLocation({
    required this.building,
    required this.floor,
    required this.department,
    required this.room,
    this.bedOrStation,
  });

  String get displayLocation => '$department ($floor) • Room $room${bedOrStation != null ? ' - $bedOrStation' : ''}';
  String get shortLocation => '$department • Rm $room';
}

class EquipmentModel {
  final String id;
  final String qrCode;
  final String name;
  final String category; // e.g., 'Ventilator', 'Infusion Pump', 'Defibrillator', 'Patient Monitor', 'ECG', 'Dialysis'
  final String modelNumber;
  final String serialNumber;
  final EquipmentLocation location;
  final EquipmentAvailability availability;
  final OperationalStatus operationalStatus;
  final MaintenanceHealth maintenanceHealth;
  final int? batteryLevel; // null if wall-powered
  final bool isWallPowered;
  final bool isSanitized;
  final DateTime lastMaintainedDate;
  final DateTime nextMaintenanceDate;
  final DateTime lastUpdatedTime;
  final String lastUpdatedBy;
  final String? currentAssignedPatient;
  final String notes;
  final String manufacturer;

  const EquipmentModel({
    required this.id,
    required this.qrCode,
    required this.name,
    required this.category,
    required this.modelNumber,
    required this.serialNumber,
    required this.location,
    required this.availability,
    required this.operationalStatus,
    required this.maintenanceHealth,
    this.batteryLevel,
    this.isWallPowered = false,
    this.isSanitized = true,
    required this.lastMaintainedDate,
    required this.nextMaintenanceDate,
    required this.lastUpdatedTime,
    required this.lastUpdatedBy,
    this.currentAssignedPatient,
    this.notes = '',
    required this.manufacturer,
  });

  EquipmentModel copyWith({
    String? id,
    String? qrCode,
    String? name,
    String? category,
    String? modelNumber,
    String? serialNumber,
    EquipmentLocation? location,
    EquipmentAvailability? availability,
    OperationalStatus? operationalStatus,
    MaintenanceHealth maintenanceHealth = MaintenanceHealth.good,
    int? batteryLevel,
    bool? isWallPowered,
    bool? isSanitized,
    DateTime? lastMaintainedDate,
    DateTime? nextMaintenanceDate,
    DateTime? lastUpdatedTime,
    String? lastUpdatedBy,
    String? currentAssignedPatient,
    String? notes,
    String? manufacturer,
  }) {
    return EquipmentModel(
      id: id ?? this.id,
      qrCode: qrCode ?? this.qrCode,
      name: name ?? this.name,
      category: category ?? this.category,
      modelNumber: modelNumber ?? this.modelNumber,
      serialNumber: serialNumber ?? this.serialNumber,
      location: location ?? this.location,
      availability: availability ?? this.availability,
      operationalStatus: operationalStatus ?? this.operationalStatus,
      maintenanceHealth: maintenanceHealth,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isWallPowered: isWallPowered ?? this.isWallPowered,
      isSanitized: isSanitized ?? this.isSanitized,
      lastMaintainedDate: lastMaintainedDate ?? this.lastMaintainedDate,
      nextMaintenanceDate: nextMaintenanceDate ?? this.nextMaintenanceDate,
      lastUpdatedTime: lastUpdatedTime ?? this.lastUpdatedTime,
      lastUpdatedBy: lastUpdatedBy ?? this.lastUpdatedBy,
      currentAssignedPatient: currentAssignedPatient ?? this.currentAssignedPatient,
      notes: notes ?? this.notes,
      manufacturer: manufacturer ?? this.manufacturer,
    );
  }
}

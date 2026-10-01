import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/equipment.dart';
import '../models/complaint.dart';
import '../models/notification_item.dart';
import '../theme/app_theme.dart';
import 'mock_data.dart';

class AppState extends ChangeNotifier {
  final Uuid _uuid = const Uuid();

  UserModel? _currentUser;
  List<UserModel> _nurses = [];
  List<EquipmentModel> _equipments = [];
  List<ComplaintModel> _complaints = [];
  List<NotificationItem> _notifications = [];

  UserModel? get currentUser => _currentUser;
  List<UserModel> get nurses => List.unmodifiable(_nurses);
  List<EquipmentModel> get equipments => List.unmodifiable(_equipments);
  List<ComplaintModel> get complaints => List.unmodifiable(_complaints);
  List<NotificationItem> get notifications => List.unmodifiable(_notifications);

  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  bool get isNurse => _currentUser?.role == UserRole.nurse;

  int get unreadNotificationsCount {
    if (_currentUser == null) return 0;
    return _notifications.where((n) {
      if (n.isRead) return false;
      if (n.targetNurseId != null && n.targetNurseId != _currentUser!.id) {
        return false;
      }
      return true;
    }).length;
  }

  List<NotificationItem> get currentUserNotifications {
    if (_currentUser == null) return [];
    return _notifications.where((n) {
      if (n.targetNurseId != null && n.targetNurseId != _currentUser!.id) {
        return false;
      }
      return true;
    }).toList();
  }

  AppState() {
    _initializeData();
  }

  void _initializeData() {
    _nurses = MockData.getNurses();
    _equipments = MockData.getEquipments();
    _complaints = MockData.getComplaints();
    _notifications = MockData.getNotifications();
    // Default initial login for nurse Elena Vance for immediate preview
    _currentUser = _nurses.firstWhere((n) => n.id == 'nurse-1');
  }

  // --- Auth Operations ---
  bool loginWithIdAndPin(String employeeId, String pin) {
    final cleanId = employeeId.trim().toUpperCase();
    final cleanPin = pin.trim();

    final user = _nurses.cast<UserModel?>().firstWhere(
          (u) => u?.employeeId.toUpperCase() == cleanId && u?.pin == cleanPin,
          orElse: () => null,
        );

    if (user != null) {
      if (!user.isActive) {
        return false; // Inactive account
      }
      _currentUser = user;
      notifyListeners();
      return true;
    }
    return false;
  }

  void loginAs(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  // --- Admin Nurse Management (Nurses cannot self-register) ---
  UserModel createNurse({
    required String employeeId,
    required String name,
    required String email,
    required String department,
    required String roleTitle,
    required String shift,
    required String pin,
  }) {
    final newNurse = UserModel(
      id: 'nurse-${_uuid.v4().substring(0, 8)}',
      employeeId: employeeId.trim().toUpperCase(),
      name: name.trim(),
      email: email.trim().toLowerCase(),
      department: department.trim(),
      roleTitle: roleTitle.trim(),
      shift: shift,
      role: UserRole.nurse,
      pin: pin.trim().isEmpty ? '1234' : pin.trim(),
      isActive: true,
      createdAt: DateTime.now(),
    );

    _nurses.add(newNurse);

    // Add audit notification
    _notifications.insert(
      0,
      NotificationItem(
        id: 'notif-${_uuid.v4().substring(0, 8)}',
        title: 'New Nurse Registered by Admin',
        message: 'Account created for ${newNurse.name} (${newNurse.employeeId}) in ${newNurse.department}.',
        type: NotificationType.systemBroadcast,
        timestamp: DateTime.now(),
        isRead: false,
      ),
    );

    notifyListeners();
    return newNurse;
  }

  void toggleNurseActive(String nurseId) {
    final index = _nurses.indexWhere((n) => n.id == nurseId);
    if (index != -1) {
      final nurse = _nurses[index];
      _nurses[index] = nurse.copyWith(isActive: !nurse.isActive);
      notifyListeners();
    }
  }

  // --- Equipment Operations ---
  EquipmentModel? getEquipmentById(String id) {
    return _equipments.cast<EquipmentModel?>().firstWhere(
          (e) => e?.id == id,
          orElse: () => null,
        );
  }

  EquipmentModel? getEquipmentByQrOrCode(String code) {
    final clean = code.trim().toUpperCase();
    return _equipments.cast<EquipmentModel?>().firstWhere(
          (e) =>
              e?.qrCode.toUpperCase() == clean ||
              e?.id.toUpperCase() == clean ||
              e?.serialNumber.toUpperCase() == clean,
          orElse: () => null,
        );
  }

  void updateEquipmentAvailability(String id, EquipmentAvailability newStatus) {
    final index = _equipments.indexWhere((e) => e.id == id);
    if (index != -1) {
      final eq = _equipments[index];
      _equipments[index] = eq.copyWith(
        availability: newStatus,
        lastUpdatedTime: DateTime.now(),
        lastUpdatedBy: _currentUser != null ? '${_currentUser!.name} (${_currentUser!.department})' : 'System',
      );

      // Create notification
      _notifications.insert(
        0,
        NotificationItem(
          id: 'notif-${_uuid.v4().substring(0, 8)}',
          title: 'Equipment Availability Changed',
          message: '${eq.name} (#${eq.qrCode}) is now ${AppTheme.getAvailabilityLabel(newStatus)}.',
          type: NotificationType.equipmentStatusChange,
          timestamp: DateTime.now(),
          isRead: false,
          relatedEquipmentId: eq.id,
        ),
      );

      notifyListeners();
    }
  }

  void updateEquipmentLocation(String id, EquipmentLocation newLocation) {
    final index = _equipments.indexWhere((e) => e.id == id);
    if (index != -1) {
      final eq = _equipments[index];
      _equipments[index] = eq.copyWith(
        location: newLocation,
        lastUpdatedTime: DateTime.now(),
        lastUpdatedBy: _currentUser != null ? _currentUser!.name : 'BioMed Ops',
      );
      notifyListeners();
    }
  }

  // --- Complaints Operations ---
  ComplaintModel submitComplaint({
    required String equipmentId,
    required ComplaintType type,
    required ComplaintSeverity severity,
    required String reportedLocation,
    required String description,
    String? errorCode,
  }) {
    final eq = getEquipmentById(equipmentId);
    final nurse = _currentUser!;
    final now = DateTime.now();
    final ticketNum = 'CMP-${(1000 + _complaints.length + 1)}';

    String typeLabel = 'Problem';
    if (type == ComplaintType.missingEquipment) typeLabel = 'Missing Equipment';
    if (type == ComplaintType.unavailableEquipment) typeLabel = 'Unavailable Equipment';

    final newComplaint = ComplaintModel(
      id: 'cmp-${_uuid.v4().substring(0, 8)}',
      ticketNumber: ticketNum,
      equipmentId: equipmentId,
      equipmentName: eq != null ? eq.name : 'Medical Equipment',
      equipmentCode: eq != null ? eq.qrCode : 'UNKNOWN',
      equipmentCategory: eq != null ? eq.category : 'General',
      type: type,
      severity: severity,
      status: ComplaintStatus.submitted,
      nurseId: nurse.id,
      nurseName: nurse.name,
      nurseDepartment: nurse.department,
      reportedLocation: reportedLocation,
      description: description,
      errorCode: errorCode?.trim().isEmpty == true ? null : errorCode?.trim(),
      reportedAt: now,
      lastUpdatedAt: now,
      timeline: [
        ComplaintTimelineEvent(
          title: 'Report Submitted',
          description: 'Nurse ${nurse.name} filed $typeLabel for ${eq?.qrCode ?? 'equipment'}.',
          timestamp: now,
          actorName: nurse.name,
          actorRole: nurse.roleTitle,
        )
      ],
    );

    _complaints.insert(0, newComplaint);

    // If marked missing or out of service, update equipment status
    if (type == ComplaintType.missingEquipment && eq != null) {
      updateEquipmentAvailability(eq.id, EquipmentAvailability.missing);
    } else if (severity == ComplaintSeverity.emergency && eq != null) {
      updateEquipmentAvailability(eq.id, EquipmentAvailability.underMaintenance);
    }

    // Add notification
    _notifications.insert(
      0,
      NotificationItem(
        id: 'notif-${_uuid.v4().substring(0, 8)}',
        title: 'Ticket $ticketNum Submitted',
        message: 'Your report for "${newComplaint.equipmentName}" is now queued for BioMed review.',
        type: NotificationType.complaintUpdate,
        timestamp: now,
        isRead: false,
        relatedComplaintId: newComplaint.id,
        relatedEquipmentId: equipmentId,
        targetNurseId: nurse.id,
      ),
    );

    notifyListeners();
    return newComplaint;
  }

  List<ComplaintModel> getComplaintsForCurrentNurse() {
    if (_currentUser == null) return [];
    if (isAdmin) return _complaints;
    return _complaints.where((c) => c.nurseId == _currentUser!.id).toList();
  }

  void updateComplaintStatus(
    String complaintId,
    ComplaintStatus newStatus, {
    required String note,
    String? assignedTech,
    String? resolution,
  }) {
    final index = _complaints.indexWhere((c) => c.id == complaintId);
    if (index != -1) {
      final cmp = _complaints[index];
      final now = DateTime.now();

      final newTimeline = List<ComplaintTimelineEvent>.from(cmp.timeline);
      newTimeline.add(
        ComplaintTimelineEvent(
          title: 'Status: ${AppTheme.getComplaintStatusLabel(newStatus)}',
          description: note,
          timestamp: now,
          actorName: _currentUser?.name ?? 'BioMed Admin',
          actorRole: _currentUser?.roleTitle ?? 'System',
        ),
      );

      final updated = cmp.copyWith(
        status: newStatus,
        lastUpdatedAt: now,
        assignedTechName: assignedTech ?? cmp.assignedTechName,
        resolutionSummary: resolution ?? cmp.resolutionSummary,
        timeline: newTimeline,
      );

      _complaints[index] = updated;

      // Notify the nurse who filed it
      _notifications.insert(
        0,
        NotificationItem(
          id: 'notif-${_uuid.v4().substring(0, 8)}',
          title: 'Ticket #${cmp.ticketNumber} Updated',
          message: 'Status changed to "${AppTheme.getComplaintStatusLabel(newStatus)}": $note',
          type: NotificationType.complaintUpdate,
          timestamp: now,
          isRead: false,
          relatedComplaintId: cmp.id,
          relatedEquipmentId: cmp.equipmentId,
          targetNurseId: cmp.nurseId,
        ),
      );

      notifyListeners();
    }
  }

  // --- Notification Operations ---
  void markNotificationAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  void markAllNotificationsAsRead() {
    bool changed = false;
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        if (_notifications[i].targetNurseId == null ||
            _notifications[i].targetNurseId == _currentUser?.id) {
          _notifications[i] = _notifications[i].copyWith(isRead: true);
          changed = true;
        }
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  void clearAllNotifications() {
    _notifications.removeWhere((n) =>
        n.targetNurseId == null || n.targetNurseId == _currentUser?.id);
    notifyListeners();
  }
}

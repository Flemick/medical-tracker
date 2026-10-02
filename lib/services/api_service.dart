import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/equipment.dart';
import '../models/complaint.dart';
import '../models/notification_item.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Configurable base URL:
  // Default for Web: 'http://localhost:5000', Mobile (Wi-Fi): 'http://172.16.17.33:5000'
  String _baseUrl = kIsWeb ? 'http://localhost:5000' : 'http://172.16.17.33:5000';
  String? _authToken;
  bool _isConnected = false;

  String get baseUrl => _baseUrl;
  bool get isConnected => _isConnected;
  String? get authToken => _authToken;

  void setBaseUrl(String newUrl) {
    _baseUrl = newUrl.replaceAll(RegExp(r'/+$'), '');
  }

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> get _headers {
    final map = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      map['Authorization'] = 'Bearer $_authToken';
    }
    return map;
  }

  // --- Health Check ---
  Future<bool> checkHealth() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/health'),
        headers: _headers,
      ).timeout(const Duration(seconds: 4));
      _isConnected = res.statusCode == 200;
      return _isConnected;
    } catch (_) {
      _isConnected = false;
      return false;
    }
  }

  // --- Auth ---
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/auth/login'),
        headers: _headers,
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _authToken = data['access_token'];
        _isConnected = true;
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('API login error: $e');
      return null;
    }
  }

  // --- Equipment ---
  Future<List<EquipmentModel>?> fetchEquipment() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/equipment'),
        headers: _headers,
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final list = json['data'] as List? ?? [];
        return list.map((item) => _parseEquipment(item)).toList();
      }
      return null;
    } catch (e) {
      debugPrint('API fetchEquipment error: $e');
      return null;
    }
  }

  Future<bool> updateEquipment(String id, Map<String, dynamic> fields) async {
    try {
      final res = await http.put(
        Uri.parse('$_baseUrl/api/equipment/$id'),
        headers: _headers,
        body: jsonEncode(fields),
      ).timeout(const Duration(seconds: 6));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('API updateEquipment error: $e');
      return false;
    }
  }

  // --- Complaints ---
  Future<List<ComplaintModel>?> fetchComplaints() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/complaints'),
        headers: _headers,
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final list = json['data'] as List? ?? [];
        return list.map((item) => _parseComplaint(item)).toList();
      }
      return null;
    } catch (e) {
      debugPrint('API fetchComplaints error: $e');
      return null;
    }
  }

  Future<ComplaintModel?> createComplaint({
    required String equipmentId,
    required String equipmentName,
    required String equipmentCode,
    required String equipmentCategory,
    required ComplaintType type,
    required ComplaintSeverity severity,
    required String reportedLocation,
    required String description,
    String? errorCode,
  }) async {
    String typeStr = 'EQUIPMENT_PROBLEM';
    if (type == ComplaintType.missingEquipment) typeStr = 'MISSING_EQUIPMENT';
    if (type == ComplaintType.unavailableEquipment) typeStr = 'UNAVAILABLE_EQUIPMENT';

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/complaints'),
        headers: _headers,
        body: jsonEncode({
          'equipment_id': equipmentId,
          'equipment_name': equipmentName,
          'equipment_code': equipmentCode,
          'equipment_category': equipmentCategory,
          'type': typeStr,
          'severity': severity.name.toUpperCase(),
          'reported_location': reportedLocation,
          'description': description,
          'error_code': errorCode ?? '',
        }),
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 201 || res.statusCode == 200) {
        final json = jsonDecode(res.body);
        return _parseComplaint(json['data'] ?? json);
      }
      return null;
    } catch (e) {
      debugPrint('API createComplaint error: $e');
      return null;
    }
  }

  Future<bool> updateComplaintStatus({
    required String complaintId,
    required ComplaintStatus status,
    String? assignedTechName,
    String? resolutionSummary,
  }) async {
    try {
      final payload = <String, dynamic>{
        'status': status.name.toUpperCase(),
      };
      if (assignedTechName != null) {
        payload['assigned_tech_name'] = assignedTechName;
      }
      if (resolutionSummary != null) {
        payload['resolution_summary'] = resolutionSummary;
      }

      final res = await http.put(
        Uri.parse('$_baseUrl/api/complaints/$complaintId/status'),
        headers: _headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 6));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('API updateComplaintStatus error: $e');
      return false;
    }
  }

  // --- Notifications ---
  Future<List<NotificationItem>?> fetchNotifications() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/notifications'),
        headers: _headers,
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final list = json['data'] as List? ?? [];
        return list.map((item) => _parseNotification(item)).toList();
      }
      return null;
    } catch (e) {
      debugPrint('API fetchNotifications error: $e');
      return null;
    }
  }

  Future<bool> markNotificationRead(String notificationId) async {
    try {
      final res = await http.put(
        Uri.parse('$_baseUrl/api/notifications/$notificationId/read'),
        headers: _headers,
      ).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('API markNotificationRead error: $e');
      return false;
    }
  }

  // --- Parsers ---
  EquipmentModel _parseEquipment(Map<String, dynamic> json) {
    final locationData = json['locations'] as Map<String, dynamic>? ?? {};
    final qrDataList = json['qr_codes'] as List? ?? [];
    final idStr = json['equipment_id']?.toString() ?? '';
    String qrCodeVal = idStr.length >= 8 ? idStr.substring(0, 8) : (idStr.isNotEmpty ? idStr : 'EQ-001');
    if (qrDataList.isNotEmpty) {
      qrCodeVal = qrDataList.first['qr_url'] ?? qrCodeVal;
    }

    final statusStr = (json['status'] ?? 'AVAILABLE').toString().toUpperCase();
    EquipmentAvailability avail = EquipmentAvailability.available;
    if (statusStr.contains('USE')) avail = EquipmentAvailability.inUse;
    if (statusStr.contains('RESERV')) avail = EquipmentAvailability.reserved;
    if (statusStr.contains('MAINT')) avail = EquipmentAvailability.underMaintenance;
    if (statusStr.contains('MISS')) avail = EquipmentAvailability.missing;
    if (statusStr.contains('OUT')) avail = EquipmentAvailability.outOfService;

    final maintStr = (json['maintenance_status'] ?? 'NORMAL').toString().toUpperCase();
    MaintenanceHealth health = MaintenanceHealth.good;
    if (maintStr.contains('MAINT') || maintStr.contains('REPAIR')) health = MaintenanceHealth.underRepair;
    if (maintStr.contains('DUE')) health = MaintenanceHealth.routineDueSoon;
    if (maintStr.contains('OVERDUE')) health = MaintenanceHealth.calibrationOverdue;

    return EquipmentModel(
      id: json['equipment_id']?.toString() ?? '',
      qrCode: qrCodeVal,
      name: json['equipment_name']?.toString() ?? 'Equipment',
      category: json['category']?.toString() ?? 'General',
      modelNumber: json['model_number']?.toString() ?? 'MD-100',
      serialNumber: json['serial_number']?.toString() ?? 'SN-84920',
      location: EquipmentLocation(
        building: locationData['building']?.toString() ?? 'Main Hospital Tower',
        floor: locationData['floor']?.toString() ?? 'Floor 3',
        department: locationData['department']?.toString() ?? 'Cardiology & ICU',
        room: locationData['room']?.toString() ?? '302',
        bedOrStation: locationData['bed_or_station']?.toString(),
      ),
      availability: avail,
      operationalStatus: OperationalStatus.optimal,
      maintenanceHealth: health,
      batteryLevel: json['battery_level'] != null ? int.tryParse(json['battery_level'].toString()) : 85,
      isWallPowered: json['is_wall_powered'] == true,
      isSanitized: json['is_sanitized'] ?? true,
      lastMaintainedDate: json['last_maintained_date'] != null
          ? DateTime.tryParse(json['last_maintained_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      nextMaintenanceDate: json['next_maintenance_date'] != null
          ? DateTime.tryParse(json['next_maintenance_date'].toString()) ?? DateTime.now().add(const Duration(days: 60))
          : DateTime.now().add(const Duration(days: 60)),
      lastUpdatedTime: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lastUpdatedBy: json['last_updated_by']?.toString() ?? 'BioMed Admin',
      currentAssignedPatient: json['current_assigned_patient']?.toString(),
      notes: json['notes']?.toString() ?? '',
      manufacturer: json['manufacturer']?.toString() ?? 'MediCore BioTech',
    );
  }

  ComplaintModel _parseComplaint(Map<String, dynamic> json) {
    final statusStr = (json['status'] ?? 'SUBMITTED').toString().toUpperCase();
    ComplaintStatus status = ComplaintStatus.submitted;
    if (statusStr.contains('REVIEW')) status = ComplaintStatus.underReview;
    if (statusStr.contains('ASSIGN')) status = ComplaintStatus.assignedToTech;
    if (statusStr.contains('PROG')) status = ComplaintStatus.inProgress;
    if (statusStr.contains('RESOLV')) status = ComplaintStatus.resolved;
    if (statusStr.contains('ESCALAT')) status = ComplaintStatus.escalated;
    if (statusStr.contains('REJECT')) status = ComplaintStatus.rejected;

    final sevStr = (json['severity'] ?? 'MEDIUM').toString().toUpperCase();
    ComplaintSeverity sev = ComplaintSeverity.medium;
    if (sevStr == 'LOW') sev = ComplaintSeverity.low;
    if (sevStr == 'HIGH') sev = ComplaintSeverity.high;
    if (sevStr == 'EMERGENCY' || sevStr == 'CRITICAL') sev = ComplaintSeverity.emergency;

    final rawType = (json['type'] ?? 'EQUIPMENT_PROBLEM').toString().toUpperCase();
    ComplaintType type = ComplaintType.equipmentProblem;
    if (rawType.contains('MISSING')) {
      type = ComplaintType.missingEquipment;
    } else if (rawType.contains('UNAVAILABLE') || rawType.contains('BLOCK')) {
      type = ComplaintType.unavailableEquipment;
    }

    return ComplaintModel(
      id: json['id']?.toString() ?? '',
      ticketNumber: json['ticket_number']?.toString() ?? 'CMP-1001',
      equipmentId: json['equipment_id']?.toString() ?? '',
      equipmentName: json['equipment_name']?.toString() ?? 'Medical Equipment',
      equipmentCode: json['equipment_code']?.toString() ?? 'EQ-001',
      equipmentCategory: json['equipment_category']?.toString() ?? 'General',
      type: type,
      severity: sev,
      status: status,
      nurseId: json['nurse_id']?.toString() ?? '',
      nurseName: json['nurse_name']?.toString() ?? 'Nurse Staff',
      nurseDepartment: json['nurse_department']?.toString() ?? 'Cardiology & ICU',
      reportedLocation: json['reported_location']?.toString() ?? 'Room 302',
      description: json['description']?.toString() ?? '',
      errorCode: json['error_code']?.toString(),
      reportedAt: json['reported_at'] != null
          ? DateTime.tryParse(json['reported_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lastUpdatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      assignedTechName: json['assigned_tech_name']?.toString(),
      resolutionSummary: json['resolution_summary']?.toString(),
    );
  }

  NotificationItem _parseNotification(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id']?.toString() ?? 'notif-1',
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? '',
      type: NotificationType.systemBroadcast,
      timestamp: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: json['is_read'] == true,
      relatedEquipmentId: json['reference_id']?.toString(),
    );
  }
}

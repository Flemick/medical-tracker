// ApiService — centralized HTTP client for the MediPulse Flask REST API.
// All requests use JWT Bearer token from AuthService.
// Flutter NEVER connects to Supabase directly.
// Base URL is configurable — do NOT hardcode IPs in screens.
//
// Backend response shapes (verified against d:\medeqp\backend\app.py):
//   POST /api/auth/login  → { access_token, user: {id, email}, profile: {...} }
//   GET  /api/auth/me     → { user: {id, email}, profile: {...} }
//   GET  /api/equipment   → { count, data: [ {equipment_id, equipment_name, category,
//                              model_number, serial_number, manufacturer, status,
//                              maintenance_status, battery_level, is_wall_powered,
//                              is_sanitized, last_maintained_date, next_maintenance_date,
//                              notes, last_updated_by, updated_at,
//                              locations: {location_id, building, floor, department, room, bed_or_station},
//                              qr_codes: [{qr_id, qr_url, status}] } ] }
//   GET  /api/equipment/{id}    → { data: { ...same as above (single object)... } }
//   GET  /api/locations         → { data: [{location_id, building, floor, department, room}] }
//   GET  /api/complaints        → { count, data: [{id, ticket_number, equipment_id,
//                                    equipment_name, equipment_code, equipment_category,
//                                    type, severity, status, nurse_id, nurse_name,
//                                    nurse_department, reported_location, description,
//                                    error_code, assigned_tech_name, resolution_summary,
//                                    reported_at, created_at, updated_at}] }
//   POST /api/complaints        → { message, data: {...} }
//   PUT  /api/complaints/{id}/status → { message, data: [...] }
//   GET  /api/notifications     → { data: [{id, title, message, type, severity,
//                                    target_role, reference_id, is_read, created_at}] }
//   PUT  /api/notifications/{id}/read → { message, data: [...] }
//   GET  /api/equipment/{id}/qr → { data: {qr_id, equipment_id, qr_url, status, created_at} }

import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/equipment.dart';
import '../models/complaint.dart';
import '../models/notification_item.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // ── Base URL Configuration ────────────────────────────────────────────────
  // Set this once on app startup. kIsWeb uses localhost; Android/iOS uses
  // the actual server IP on the local network.
  // Change via AppState.setApiBaseUrl() — never hardcode in screens.
  String _baseUrl = 'http://10.167.72.91:5000';

  final AuthService _auth = AuthService();

  String get baseUrl => _baseUrl;

  void setBaseUrl(String url) {
    _baseUrl = url.replaceAll(RegExp(r'/+$'), '');
  }

  // ── HTTP Headers ─────────────────────────────────────────────────────────
  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_auth.hasToken) {
      headers['Authorization'] = 'Bearer ${_auth.token}';
    }
    return headers;
  }

  // ── Generic Error Extraction ─────────────────────────────────────────────
  String _extractError(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      return body['message'] ?? body['error'] ?? 'Unknown error (${res.statusCode})';
    } catch (_) {
      return 'Server error (${res.statusCode})';
    }
  }

  // ── Health Check ─────────────────────────────────────────────────────────
  Future<bool> checkHealth() async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/api/health'), headers: _headers)
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Authentication ───────────────────────────────────────────────────────

  /// POST /api/auth/login
  /// Returns { 'access_token': String, 'profile': Map } on success,
  /// or throws a [ApiException] on failure.
  Future<LoginResult> login(String email, String password) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/api/auth/login'),
            headers: _headers,
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200) {
        final token = body['access_token'] as String;
        final profileJson = body['profile'] as Map<String, dynamic>? ?? {};
        return LoginResult(token: token, profileJson: profileJson);
      } else if (res.statusCode == 403) {
        throw ApiException('Your account has been disabled. Contact the administrator.');
      } else if (res.statusCode == 401) {
        throw ApiException('Invalid email or password.');
      } else {
        throw ApiException(_extractError(res));
      }
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('Connection timed out. The server at $_baseUrl did not respond. Check firewall rules.');
    } on SocketException catch (e) {
      if (e.osError?.errorCode == 111 || e.osError?.errorCode == 10061 || e.osError?.errorCode == 113) {
        throw ApiException('Connection refused. Is the Flask server running and accessible at $_baseUrl?');
      } else {
        throw ApiException('Network error (SocketException). Check Wi-Fi and firewall. Details: ${e.message}');
      }
    } on http.ClientException catch (e) {
      throw ApiException('HTTP Client error connecting to $_baseUrl. Details: ${e.message}');
    } catch (e) {
      throw ApiException('Unexpected error connecting to server: $e');
    }
  }

  /// GET /api/auth/me
  /// Returns the current user's profile, or null if the token is invalid/expired.
  Future<UserModel?> fetchMe() async {
    if (!_auth.hasToken) return null;
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/api/auth/me'), headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final profileJson = body['profile'] as Map<String, dynamic>? ?? {};
        return UserModel.fromProfileJson(profileJson);
      } else if (res.statusCode == 401 || res.statusCode == 403) {
        // Token expired or invalid — caller should clear session
        return null;
      } else {
        debugPrint('ApiService.fetchMe: ${res.statusCode} ${res.body}');
        return null;
      }
    } catch (e) {
      debugPrint('ApiService.fetchMe error: $e');
      return null;
    }
  }

  // ── Equipment ────────────────────────────────────────────────────────────

  /// GET /api/equipment
  /// Response: { count, data: [ { equipment_id, ..., locations: {...}, qr_codes: [...] } ] }
  Future<List<EquipmentModel>> fetchEquipment() async {
    final res = await http
        .get(Uri.parse('$_baseUrl/api/equipment'), headers: _headers)
        .timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final list = (body['data'] as List? ?? []);
      return list.map((e) => _parseEquipment(e as Map<String, dynamic>)).toList();
    } else if (res.statusCode == 401) {
      throw ApiException('Session expired. Please log in again.', isUnauthorized: true);
    } else {
      throw ApiException(_extractError(res));
    }
  }

  /// GET /api/equipment/{id}
  /// Response: { data: { ...single equipment object... } }
  Future<EquipmentModel> fetchEquipmentById(String equipmentId) async {
    final res = await http
        .get(Uri.parse('$_baseUrl/api/equipment/$equipmentId'), headers: _headers)
        .timeout(const Duration(seconds: 8));

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return _parseEquipment(body['data'] as Map<String, dynamic>);
    } else if (res.statusCode == 404) {
      throw ApiException('Equipment not found.');
    } else if (res.statusCode == 401) {
      throw ApiException('Session expired. Please log in again.', isUnauthorized: true);
    } else {
      throw ApiException(_extractError(res));
    }
  }

  // ── Locations ────────────────────────────────────────────────────────────

  /// GET /api/locations
  /// Response: { data: [ { location_id, building, floor, department, room, bed_or_station } ] }
  Future<List<Map<String, dynamic>>> fetchLocations() async {
    final res = await http
        .get(Uri.parse('$_baseUrl/api/locations'), headers: _headers)
        .timeout(const Duration(seconds: 8));

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return List<Map<String, dynamic>>.from(body['data'] as List? ?? []);
    } else if (res.statusCode == 401) {
      throw ApiException('Session expired. Please log in again.', isUnauthorized: true);
    } else {
      throw ApiException(_extractError(res));
    }
  }

  // ── Complaints ───────────────────────────────────────────────────────────

  /// GET /api/complaints
  /// Response: { count, data: [ { id, ticket_number, equipment_id, equipment_name,
  ///   equipment_code, equipment_category, type, severity, status, nurse_id,
  ///   nurse_name, nurse_department, reported_location, description, error_code,
  ///   assigned_tech_name, resolution_summary, reported_at, created_at, updated_at } ] }
  Future<List<ComplaintModel>> fetchComplaints() async {
    final res = await http
        .get(Uri.parse('$_baseUrl/api/complaints'), headers: _headers)
        .timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final list = (body['data'] as List? ?? []);
      return list.map((e) => _parseComplaint(e as Map<String, dynamic>)).toList();
    } else if (res.statusCode == 401) {
      throw ApiException('Session expired. Please log in again.', isUnauthorized: true);
    } else {
      throw ApiException(_extractError(res));
    }
  }

  /// POST /api/complaints
  /// Request: { equipment_id, equipment_name, equipment_code, equipment_category,
  ///            type, severity, reported_location, description, error_code }
  /// Response: { message, data: { ...complaint fields... } }
  Future<ComplaintModel> createComplaint({
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
    final payload = {
      'equipment_id': equipmentId,
      'equipment_name': equipmentName,
      'equipment_code': equipmentCode,
      'equipment_category': equipmentCategory,
      'type': _complaintTypeToString(type),
      'severity': _severityToString(severity),
      'reported_location': reportedLocation,
      'description': description,
      if (errorCode != null && errorCode.trim().isNotEmpty) 'error_code': errorCode.trim(),
    };

    final res = await http
        .post(
          Uri.parse('$_baseUrl/api/complaints'),
          headers: _headers,
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode == 201) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return _parseComplaint(body['data'] as Map<String, dynamic>);
    } else if (res.statusCode == 401) {
      throw ApiException('Session expired. Please log in again.', isUnauthorized: true);
    } else {
      throw ApiException(_extractError(res));
    }
  }

  /// PUT /api/complaints/{id}/status
  /// Request: { status, assigned_tech_name?, resolution_summary? }
  Future<void> updateComplaintStatus({
    required String complaintId,
    required ComplaintStatus status,
    String? assignedTechName,
    String? resolutionSummary,
  }) async {
    final payload = <String, dynamic>{
      'status': _complaintStatusToString(status),
      if (assignedTechName != null) 'assigned_tech_name': assignedTechName,
      if (resolutionSummary != null) 'resolution_summary': resolutionSummary,
    };

    final res = await http
        .put(
          Uri.parse('$_baseUrl/api/complaints/$complaintId/status'),
          headers: _headers,
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 8));

    if (res.statusCode != 200) {
      if (res.statusCode == 401) {
        throw ApiException('Session expired. Please log in again.', isUnauthorized: true);
      }
      throw ApiException(_extractError(res));
    }
  }

  // ── Notifications ────────────────────────────────────────────────────────

  /// GET /api/notifications
  /// Response: { data: [ { id, title, message, type, severity, target_role,
  ///                       reference_id, is_read, created_at } ] }
  Future<List<NotificationItem>> fetchNotifications() async {
    final res = await http
        .get(Uri.parse('$_baseUrl/api/notifications'), headers: _headers)
        .timeout(const Duration(seconds: 8));

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final list = (body['data'] as List? ?? []);
      return list.map((e) => _parseNotification(e as Map<String, dynamic>)).toList();
    } else if (res.statusCode == 401) {
      throw ApiException('Session expired. Please log in again.', isUnauthorized: true);
    } else {
      throw ApiException(_extractError(res));
    }
  }

  /// PUT /api/notifications/{id}/read
  Future<void> markNotificationRead(String notificationId) async {
    try {
      await http
          .put(
            Uri.parse('$_baseUrl/api/notifications/$notificationId/read'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('ApiService.markNotificationRead: $e');
    }
  }

  // ── QR Code ──────────────────────────────────────────────────────────────

  /// GET /api/equipment/{id}/qr
  /// Response: { data: { qr_id, equipment_id, qr_url, status, created_at } }
  /// The qr_url is a stable URL like http://server/equipment/{equipment_id}
  /// Flutter SCANS this URL to navigate to the equipment.
  Future<Map<String, dynamic>?> fetchEquipmentQr(String equipmentId) async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/api/equipment/$equipmentId/qr'), headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return body['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint('ApiService.fetchEquipmentQr: $e');
      return null;
    }
  }

  // ── Parsers ───────────────────────────────────────────────────────────────

  EquipmentModel _parseEquipment(Map<String, dynamic> json) {
    // locations is an embedded object (joined via Supabase select *)
    final loc = json['locations'] as Map<String, dynamic>? ?? {};
    // qr_codes is an embedded list
    final qrList = json['qr_codes'] as List? ?? [];
    String qrCode = json['equipment_id']?.toString() ?? '';
    if (qrList.isNotEmpty) {
      // Prefer ACTIVE qr_url
      final activeQr = qrList.firstWhere(
        (q) => (q['status'] ?? '').toString().toUpperCase() == 'ACTIVE',
        orElse: () => qrList.first,
      );
      qrCode = activeQr['qr_url']?.toString() ?? qrCode;
    }

    final statusStr = (json['status'] ?? 'AVAILABLE').toString().toUpperCase();
    EquipmentAvailability avail = EquipmentAvailability.available;
    if (statusStr == 'IN_USE') avail = EquipmentAvailability.inUse;
    if (statusStr == 'RESERVED') avail = EquipmentAvailability.reserved;
    if (statusStr == 'UNDER_MAINTENANCE') avail = EquipmentAvailability.underMaintenance;
    if (statusStr == 'MISSING') avail = EquipmentAvailability.missing;
    if (statusStr == 'OUT_OF_SERVICE') avail = EquipmentAvailability.outOfService;

    final maintStr = (json['maintenance_status'] ?? 'NORMAL').toString().toUpperCase();
    MaintenanceHealth health = MaintenanceHealth.good;
    if (maintStr == 'UNDER_MAINTENANCE') health = MaintenanceHealth.underRepair;
    if (maintStr == 'SCHEDULED') health = MaintenanceHealth.routineDueSoon;
    if (maintStr == 'OVERDUE') health = MaintenanceHealth.calibrationOverdue;

    final opStr = (json['operational_status'] ?? 'OPTIMAL').toString().toUpperCase();
    OperationalStatus opStatus = OperationalStatus.optimal;
    if (opStr == 'MINOR_ISSUE') opStatus = OperationalStatus.minorIssue;
    if (opStr == 'CRITICAL_ERROR') opStatus = OperationalStatus.criticalError;
    if (opStr == 'NEEDS_SANITIZING') opStatus = OperationalStatus.needsSanitizing;

    return EquipmentModel(
      id: json['equipment_id']?.toString() ?? '',
      qrCode: qrCode,
      name: json['equipment_name']?.toString() ?? 'Equipment',
      category: json['category']?.toString() ?? 'General',
      modelNumber: json['model_number']?.toString() ?? '',
      serialNumber: json['serial_number']?.toString() ?? '',
      manufacturer: json['manufacturer']?.toString() ?? '',
      location: EquipmentLocation(
        building: loc['building']?.toString() ?? 'Main Hospital',
        floor: loc['floor']?.toString() ?? 'Floor 1',
        department: loc['department']?.toString() ?? 'General',
        room: loc['room']?.toString() ?? '101',
        bedOrStation: loc['bed_or_station']?.toString(),
      ),
      availability: avail,
      operationalStatus: opStatus,
      maintenanceHealth: health,
      batteryLevel: json['battery_level'] != null
          ? int.tryParse(json['battery_level'].toString())
          : null,
      isWallPowered: json['is_wall_powered'] == true,
      isSanitized: json['is_sanitized'] != false,
      lastMaintainedDate: _parseDate(json['last_maintained_date']) ?? DateTime.now(),
      nextMaintenanceDate: _parseDate(json['next_maintenance_date']) ??
          DateTime.now().add(const Duration(days: 90)),
      lastUpdatedTime: _parseDate(json['updated_at']) ?? DateTime.now(),
      lastUpdatedBy: json['last_updated_by']?.toString() ?? 'System',
      currentAssignedPatient: json['current_assigned_patient']?.toString(),
      notes: json['notes']?.toString() ?? '',
    );
  }

  ComplaintModel _parseComplaint(Map<String, dynamic> json) {
    final statusStr = (json['status'] ?? 'SUBMITTED').toString().toUpperCase();
    ComplaintStatus status = ComplaintStatus.submitted;
    if (statusStr == 'UNDER_REVIEW') status = ComplaintStatus.underReview;
    if (statusStr == 'ASSIGNED_TO_TECH') status = ComplaintStatus.assignedToTech;
    if (statusStr == 'IN_PROGRESS') status = ComplaintStatus.inProgress;
    if (statusStr == 'RESOLVED') status = ComplaintStatus.resolved;
    if (statusStr == 'ESCALATED') status = ComplaintStatus.escalated;
    if (statusStr == 'REJECTED') status = ComplaintStatus.rejected;

    final sevStr = (json['severity'] ?? 'MEDIUM').toString().toUpperCase();
    ComplaintSeverity sev = ComplaintSeverity.medium;
    if (sevStr == 'LOW') sev = ComplaintSeverity.low;
    if (sevStr == 'HIGH') sev = ComplaintSeverity.high;
    if (sevStr == 'EMERGENCY') sev = ComplaintSeverity.emergency;

    final typeStr = (json['type'] ?? 'EQUIPMENT_PROBLEM').toString().toUpperCase();
    ComplaintType type = ComplaintType.equipmentProblem;
    if (typeStr == 'MISSING_EQUIPMENT') type = ComplaintType.missingEquipment;
    if (typeStr == 'UNAVAILABLE_EQUIPMENT') type = ComplaintType.unavailableEquipment;
    if (typeStr == 'OTHER') type = ComplaintType.other;

    return ComplaintModel(
      id: json['id']?.toString() ?? '',
      ticketNumber: json['ticket_number']?.toString() ?? 'CMP-0000',
      equipmentId: json['equipment_id']?.toString() ?? '',
      equipmentName: json['equipment_name']?.toString() ?? 'Medical Equipment',
      equipmentCode: json['equipment_code']?.toString() ?? '',
      equipmentCategory: json['equipment_category']?.toString() ?? 'General',
      type: type,
      severity: sev,
      status: status,
      nurseId: json['nurse_id']?.toString() ?? '',
      nurseName: json['nurse_name']?.toString() ?? 'Staff Member',
      nurseDepartment: json['nurse_department']?.toString() ?? 'General',
      reportedLocation: json['reported_location']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      errorCode: json['error_code']?.toString(),
      reportedAt: _parseDate(json['reported_at']) ?? DateTime.now(),
      lastUpdatedAt: _parseDate(json['updated_at']) ?? DateTime.now(),
      assignedTechName: json['assigned_tech_name']?.toString(),
      resolutionSummary: json['resolution_summary']?.toString(),
    );
  }

  NotificationItem _parseNotification(Map<String, dynamic> json) {
    // Backend notification types: GENERAL, COMPLAINT, MAINTENANCE, ALERT, ASSIGNMENT
    final typeStr = (json['type'] ?? 'GENERAL').toString().toUpperCase();
    NotificationType nType = NotificationType.systemBroadcast;
    if (typeStr == 'COMPLAINT') nType = NotificationType.complaintUpdate;
    if (typeStr == 'MAINTENANCE') nType = NotificationType.maintenanceAlert;
    if (typeStr == 'ALERT') nType = NotificationType.equipmentStatusChange;

    return NotificationItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? '',
      type: nType,
      timestamp: _parseDate(json['created_at']) ?? DateTime.now(),
      isRead: json['is_read'] == true,
      relatedEquipmentId: json['reference_id']?.toString(),
    );
  }

  // ── Enum Converters ──────────────────────────────────────────────────────

  String _complaintTypeToString(ComplaintType t) {
    switch (t) {
      case ComplaintType.missingEquipment: return 'MISSING_EQUIPMENT';
      case ComplaintType.unavailableEquipment: return 'UNAVAILABLE_EQUIPMENT';
      case ComplaintType.other: return 'OTHER';
      case ComplaintType.equipmentProblem: return 'EQUIPMENT_PROBLEM';
    }
  }

  String _severityToString(ComplaintSeverity s) {
    switch (s) {
      case ComplaintSeverity.low: return 'LOW';
      case ComplaintSeverity.medium: return 'MEDIUM';
      case ComplaintSeverity.high: return 'HIGH';
      case ComplaintSeverity.emergency: return 'EMERGENCY';
    }
  }

  String _complaintStatusToString(ComplaintStatus s) {
    switch (s) {
      case ComplaintStatus.submitted: return 'SUBMITTED';
      case ComplaintStatus.underReview: return 'UNDER_REVIEW';
      case ComplaintStatus.assignedToTech: return 'ASSIGNED_TO_TECH';
      case ComplaintStatus.inProgress: return 'IN_PROGRESS';
      case ComplaintStatus.resolved: return 'RESOLVED';
      case ComplaintStatus.escalated: return 'ESCALATED';
      case ComplaintStatus.rejected: return 'REJECTED';
    }
  }

  // ── Utilities ────────────────────────────────────────────────────────────

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

// ── Result & Exception types ─────────────────────────────────────────────────

class LoginResult {
  final String token;
  final Map<String, dynamic> profileJson;
  const LoginResult({required this.token, required this.profileJson});
}

class ApiException implements Exception {
  final String message;
  final bool isUnauthorized;
  const ApiException(this.message, {this.isUnauthorized = false});

  @override
  String toString() => message;
}

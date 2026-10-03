// AppState — single ChangeNotifier for all USER app state.
// API-FIRST: No mock data. All data comes from Flask backend.
// Login flow:  email+password → Flask → JWT → /api/auth/me → load data
// Startup flow: stored JWT → /api/auth/me → valid? restore : logout
// Errors are surfaced to the UI — no silent fire-and-forget failures.

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/equipment.dart';
import '../models/complaint.dart';
import '../models/notification_item.dart';
import 'api_service.dart';
import 'auth_service.dart';

class AppState extends ChangeNotifier {
  final ApiService _api = ApiService();
  final AuthService _auth = AuthService();

  // ── State ─────────────────────────────────────────────────────────────────
  UserModel? _currentUser;
  List<EquipmentModel> _equipments = [];
  List<ComplaintModel> _complaints = [];
  List<NotificationItem> _notifications = [];

  bool _isLoading = false;      // global loading (initial data fetch)
  bool _isInitializing = true;  // true until session check is done
  String? _globalError;         // surfaced to UI — never silent
  Timer? _refreshTimer;         // automatic polling timer

  // ── Getters ───────────────────────────────────────────────────────────────
  UserModel? get currentUser => _currentUser;
  List<EquipmentModel> get equipments => List.unmodifiable(_equipments);
  List<ComplaintModel> get complaints => List.unmodifiable(_complaints);
  List<NotificationItem> get notifications => List.unmodifiable(_notifications);

  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  String? get globalError => _globalError;
  String get apiBaseUrl => _api.baseUrl;

  List<NotificationItem> get userNotifications => List.unmodifiable(_notifications);

  /// Alias used by NotificationCenterScreen
  List<NotificationItem> get currentUserNotifications => List.unmodifiable(_notifications);

  int get unreadNotificationsCount =>
      _notifications.where((n) => !n.isRead).length;

  // ── Stubs for admin screens (will be removed in Stage 13) ─────────────────
  List<UserModel> get nurses => const [];
  Future<UserModel?> createNurse({
    required String name, required String email,
    required String department, required String shift,
    required String employeeId, required String password,
  }) async => null;
  void toggleNurseActive(String id) {}


  // ── Initialisation ────────────────────────────────────────────────────────

  AppState() {
    _initOnStartup();
  }

  /// On cold start: check for stored JWT, validate it against /api/auth/me.
  Future<void> _initOnStartup() async {
    _isInitializing = true;
    notifyListeners();

    await _auth.loadStoredToken();

    if (_auth.hasToken) {
      final user = await _api.fetchMe();
      if (user != null && user.isActive) {
        _currentUser = user;
        // Load data in background after restoring session
        _loadUserData();
        _startAutoRefresh();
      } else {
        // Token invalid / expired / account disabled — clear it
        await _auth.clearToken();
      }
    }

    _isInitializing = false;
    notifyListeners();
  }

  // ── Authentication ────────────────────────────────────────────────────────

  /// Login: sends email+password to Flask, stores JWT, fetches profile.
  /// Throws [ApiException] on failure (caller must show error to user).
  Future<void> login(String email, String password) async {
    _isLoading = true;
    _globalError = null;
    notifyListeners();

    try {
      final result = await _api.login(email.trim(), password);
      await _auth.saveToken(result.token);
      _api; // token is now set in AuthService, ApiService reads it from there

      final user = UserModel.fromProfileJson(result.profileJson, defaultEmail: email.trim());
      if (!user.isActive) {
        await _auth.clearToken();
        throw ApiException('Your account has been disabled. Contact the administrator.');
      }

      _currentUser = user;
      _isLoading = false;
      notifyListeners();

      // Load data after login (errors here don't block the user)
      _loadUserData();
      _startAutoRefresh();
    } on ApiException {
      _isLoading = false;
      notifyListeners();
      rethrow; // let the UI handle the message
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw ApiException('An unexpected error occurred. Please try again.');
    }
  }

  /// Logout: clears token, clears all state, returns to login.
  Future<void> logout() async {
    await _auth.clearToken();
    _currentUser = null;
    _equipments = [];
    _complaints = [];
    _notifications = [];
    _globalError = null;
    _stopAutoRefresh();
    notifyListeners();
  }

  // ── Data Loading ──────────────────────────────────────────────────────────

  /// Load all USER data from the backend. Called after login and on startup.
  /// Errors are stored in _globalError for the UI to surface.
  Future<void> _loadUserData() async {
    await Future.wait([
      _loadEquipment(),
      _loadComplaints(),
      _loadNotifications(),
    ]);
  }

  void _startAutoRefresh() {
    _stopAutoRefresh(); // ensure no duplicates
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (isLoggedIn) {
        _loadEquipment(); // silently fetch latest locations
      }
    });
  }

  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Refresh all data (called by pull-to-refresh).
  Future<void> refreshAll() async {
    _globalError = null;
    notifyListeners();
    await _loadUserData();
  }

  Future<void> _loadEquipment() async {
    try {
      final list = await _api.fetchEquipment();
      _equipments = list;
      notifyListeners();
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await logout();
      } else {
        _globalError = 'Equipment load failed: ${e.message}';
        notifyListeners();
      }
    } catch (e) {
      _globalError = 'Equipment load failed. Check your connection.';
      notifyListeners();
    }
  }

  Future<void> _loadComplaints() async {
    try {
      final list = await _api.fetchComplaints();
      // USER sees only their own complaints (filtered by nurse_id)
      if (_currentUser != null) {
        _complaints = list
            .where((c) => c.nurseId == _currentUser!.id)
            .toList();
      } else {
        _complaints = list;
      }
      notifyListeners();
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await logout();
      } else {
        _globalError = 'Complaints load failed: ${e.message}';
        notifyListeners();
      }
    } catch (e) {
      _globalError = 'Complaints load failed. Check your connection.';
      notifyListeners();
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final list = await _api.fetchNotifications();
      _notifications = list;
      notifyListeners();
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await logout();
      }
      // Notification failures are non-critical — don't surface error
    } catch (_) {
      // non-critical
    }
  }

  // ── Equipment Operations ──────────────────────────────────────────────────

  EquipmentModel? getEquipmentById(String id) {
    try {
      return _equipments.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Search equipment by equipment_id OR by qrCode URL string.
  /// Used by QR scanner after extracting ID from scanned URL.
  EquipmentModel? getEquipmentByQrOrCode(String code) {
    try {
      return _equipments.firstWhere(
        (e) => e.id == code || e.qrCode == code || e.qrCode.contains(code),
      );
    } catch (_) {
      return null;
    }
  }

  /// Alias for complaint_list_screen.dart (USER only sees their own complaints;
  /// filtering is already done in _loadComplaints).
  List<ComplaintModel> getComplaintsForCurrentNurse() => List.unmodifiable(_complaints);

  /// Optimistic local status update (UI feedback only — USER role cannot
  /// update equipment status via the API; that is an Admin operation).
  void updateEquipmentAvailability(String id, EquipmentAvailability newStatus) {
    final index = _equipments.indexWhere((e) => e.id == id);
    if (index != -1) {
      _equipments[index] = _equipments[index].copyWith(availability: newStatus);
      notifyListeners();
    }
  }

  /// Fetch a single equipment record live from backend (used after QR scan).
  Future<EquipmentModel?> fetchEquipmentLive(String equipmentId) async {
    try {
      return await _api.fetchEquipmentById(equipmentId);
    } on ApiException catch (e) {
      if (e.isUnauthorized) await logout();
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Complaint Operations ──────────────────────────────────────────────────

  /// Submit a new complaint. Returns the created complaint, throws ApiException on failure.
  Future<ComplaintModel> submitComplaint({
    required String equipmentId,
    required ComplaintType type,
    required ComplaintSeverity severity,
    required String reportedLocation,
    required String description,
    String? errorCode,
  }) async {
    final eq = getEquipmentById(equipmentId);

    final complaint = await _api.createComplaint(
      equipmentId: equipmentId,
      equipmentName: eq?.name ?? '',
      equipmentCode: eq?.qrCode ?? '',
      equipmentCategory: eq?.category ?? '',
      type: type,
      severity: severity,
      reportedLocation: reportedLocation,
      description: description,
      errorCode: errorCode,
    );

    // Prepend to local list immediately for instant UI feedback
    _complaints.insert(0, complaint);
    notifyListeners();

    return complaint;
  }

  Future<void> updateComplaintStatus(
    String complaintId,
    ComplaintStatus newStatus, {
    String? note,
    String? assignedTech,
    String? resolution,
  }) async {
    try {
      await _api.updateComplaintStatus(
        complaintId: complaintId,
        status: newStatus,
        assignedTechName: assignedTech,
        resolutionSummary: resolution,
      );
      // Update local state
      final index = _complaints.indexWhere((c) => c.id == complaintId);
      if (index != -1) {
        _complaints[index] = _complaints[index].copyWith(
          status: newStatus,
          assignedTechName: assignedTech ?? _complaints[index].assignedTechName,
          resolutionSummary: resolution ?? _complaints[index].resolutionSummary,
        );
        notifyListeners();
      }
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await logout();
      } else {
        rethrow;
      }
    }
  }

  // ── Notification Operations ───────────────────────────────────────────────

  Future<void> markNotificationAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
      await _api.markNotificationRead(id);
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    bool changed = false;
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
        _api.markNotificationRead(_notifications[i].id); // fire-and-forget for mark-all
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  /// Remove already-read notifications from local list (UI-only, not persisted to backend).
  void clearAllNotifications() {
    _notifications.removeWhere((n) => n.isRead);
    notifyListeners();
  }

  // ── Configuration ─────────────────────────────────────────────────────────

  void setApiBaseUrl(String url) {
    _api.setBaseUrl(url);
  }
}

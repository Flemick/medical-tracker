// UserHomeScreen — 5-tab bottom navigation shell for the USER role
// (Nurse and Staff are the same USER role in this Flutter app).
// All data comes from AppState which fetches from the Flask API.

import 'package:flutter/material.dart';
import '../models/equipment.dart';
import '../models/complaint.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';
import '../widgets/quick_stat_card.dart';
import 'equipment/equipment_list_screen.dart';
import 'equipment/equipment_detail_screen.dart';
import 'equipment/qr_scanner_screen.dart';
import 'complaints/complaint_list_screen.dart';
import 'complaints/create_complaint_screen.dart';
import 'notifications/notification_center_screen.dart';
import 'login_screen.dart';

class UserHomeScreen extends StatefulWidget {
  final AppState appState;

  const UserHomeScreen({super.key, required this.appState});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      _UserDashboardTab(
        appState: widget.appState,
        onNavigateTab: (index) => setState(() => _currentIndex = index),
      ),
      EquipmentListScreen(appState: widget.appState),
      QrScannerScreen(appState: widget.appState),
      ComplaintListScreen(appState: widget.appState),
      NotificationCenterScreen(appState: widget.appState),
    ];

    final unreadCount = widget.appState.unreadNotificationsCount;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.borderLight, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.white,
          elevation: 0,
          indicatorColor: AppColors.primarySurface,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: AppColors.primaryDark),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2_rounded, color: AppColors.primaryDark),
              label: 'Equipment',
            ),
            const NavigationDestination(
              icon: Icon(Icons.qr_code_scanner_rounded),
              selectedIcon: Icon(Icons.qr_code_scanner_rounded, color: AppColors.primaryDark),
              label: 'QR Scan',
            ),
            const NavigationDestination(
              icon: Icon(Icons.assignment_late_outlined),
              selectedIcon: Icon(Icons.assignment_late_rounded, color: AppColors.primaryDark),
              label: 'Complaints',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: unreadCount > 0,
                label: Text('$unreadCount'),
                child: const Icon(Icons.notifications_none_rounded),
              ),
              selectedIcon: Badge(
                isLabelVisible: unreadCount > 0,
                label: Text('$unreadCount'),
                child: const Icon(Icons.notifications_rounded, color: AppColors.primaryDark),
              ),
              label: 'Alerts',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dashboard Home Tab ────────────────────────────────────────────────────────

class _UserDashboardTab extends StatelessWidget {
  final AppState appState;
  final Function(int) onNavigateTab;

  const _UserDashboardTab({
    required this.appState,
    required this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final user = appState.currentUser;
        final equipments = appState.equipments;
        final myComplaints = appState.complaints;

        final availableCount = equipments
            .where((e) => e.availability == EquipmentAvailability.available)
            .length;
        final inUseCount = equipments
            .where((e) => e.availability == EquipmentAvailability.inUse)
            .length;
        final myOpenTickets = myComplaints
            .where((c) => c.status != ComplaintStatus.resolved)
            .length;

        return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.local_hospital_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'MediPulse',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMainLight),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: appState.unreadNotificationsCount > 0,
              label: Text('${appState.unreadNotificationsCount}'),
              child: const Icon(Icons.notifications_outlined),
            ),
            tooltip: 'Notifications',
            onPressed: () => onNavigateTab(4),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () async {
              await appState.logout();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => LoginScreen(appState: appState)),
                );
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: appState.refreshAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error banner if there's a global load error
              if (appState.globalError != null)
                _ErrorBanner(message: appState.globalError!),

              // User Profile Banner
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: const Icon(Icons.person_outline_rounded,
                              color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.name ?? 'Staff Member',
                                style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${user?.department ?? "General Ward"}'
                                '${user?.employeeId.isNotEmpty == true ? " · ${user!.employeeId}" : ""}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded,
                            color: Colors.white70, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          user?.shift ?? 'Shift not set',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Quick Actions
              const Text('Quick Actions',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMainLight)),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildActionTile(
                    context: context,
                    icon: Icons.qr_code_scanner_rounded,
                    label: 'Scan QR Tag',
                    color: AppColors.primary,
                    onTap: () => onNavigateTab(2),
                  ),
                  const SizedBox(width: 10),
                  _buildActionTile(
                    context: context,
                    icon: Icons.search_rounded,
                    label: 'Find Equipment',
                    color: const Color(0xFF0284C7),
                    onTap: () => onNavigateTab(1),
                  ),
                  const SizedBox(width: 10),
                  _buildActionTile(
                    context: context,
                    icon: Icons.report_problem_rounded,
                    label: 'Report Issue',
                    color: const Color(0xFFEF4444),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CreateComplaintScreen(appState: appState),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Metric Cards
              Row(
                children: [
                  Expanded(
                    child: QuickStatCard(
                      title: 'Available',
                      value: '$availableCount',
                      icon: Icons.check_circle_outline_rounded,
                      color: const Color(0xFF10B981),
                      bgColor: const Color(0xFFD1FAE5),
                      onTap: () => onNavigateTab(1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: QuickStatCard(
                      title: 'In Use',
                      value: '$inUseCount',
                      icon: Icons.play_circle_outline_rounded,
                      color: const Color(0xFF0284C7),
                      bgColor: const Color(0xFFE0F2FE),
                      onTap: () => onNavigateTab(1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: QuickStatCard(
                      title: 'My Tickets',
                      value: '$myOpenTickets',
                      icon: Icons.assignment_late_outlined,
                      color: const Color(0xFF6366F1),
                      bgColor: const Color(0xFFEEF2FF),
                      onTap: () => onNavigateTab(3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Equipment Preview (first 4)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Hospital Devices',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMainLight)),
                  TextButton(
                    onPressed: () => onNavigateTab(1),
                    child: const Text('View All',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              if (appState.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (equipments.isEmpty)
                _EmptyState(
                  icon: Icons.devices_other_rounded,
                  message: 'No equipment loaded yet.\nPull down to refresh.',
                )
              else
                ...equipments.take(4).map((eq) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EquipmentDetailScreen(
                                equipmentId: eq.id, appState: appState),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.devices_other_rounded,
                                  color: AppColors.primary, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    eq.name,
                                    style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textMainLight),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${eq.category} · ${eq.location.shortLocation}',
                                    style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.textMutedLight),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            AvailabilityBadge(
                                availability: eq.availability, compact: true),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
      }
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMainLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helper Widgets ────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFEF4444), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(icon, size: 48, color: AppColors.textLight),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textMutedLight, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

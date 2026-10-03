import 'package:flutter/material.dart';
import '../../models/equipment.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/quick_stat_card.dart';
import 'create_nurse_dialog.dart';
import 'nurse_management_screen.dart';
import '../equipment/equipment_list_screen.dart';
import '../complaints/complaint_list_screen.dart';
import '../login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final AppState appState;

  const AdminDashboardScreen({super.key, required this.appState});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final equipments = widget.appState.equipments;
        final complaints = widget.appState.complaints;

        final availableCount = equipments.where((e) => e.availability == EquipmentAvailability.available).length;
        final inUseCount = equipments.where((e) => e.availability == EquipmentAvailability.inUse).length;
        final maintenanceCount = equipments.where((e) => e.availability == EquipmentAvailability.underMaintenance).length;
        final missingCount = equipments.where((e) => e.availability == EquipmentAvailability.missing).length;

        return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('BioMed & Admin Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () {
              widget.appState.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen(appState: widget.appState)),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: widget.appState.refreshAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admin Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF38BDF8), size: 32),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hospital Admin & BioMed Control',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Logged in as ${widget.appState.currentUser?.name ?? "Administrator"}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Nurse Management Highlights
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.badge_rounded, color: AppColors.primary, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Nurse Staff Provisioning',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textMainLight),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => NurseManagementScreen(appState: widget.appState)),
                          );
                        },
                        child: const Text('View All Nurses', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Nurses cannot self-register. Use this portal to create credentials, assign departments, and configure shifts.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMutedLight),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await CreateNurseDialog.show(context, widget.appState);
                        setState(() {});
                      },
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                      label: const Text('Register / Create New Nurse Account'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Equipment Inventory Overview Grid
            const Text(
              'Equipment Tracking & Availability Overview',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textMainLight),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.45,
              children: [
                QuickStatCard(
                  title: 'Available Devices',
                  value: '$availableCount',
                  icon: Icons.check_circle_outline_rounded,
                  color: const Color(0xFF10B981),
                  bgColor: const Color(0xFFD1FAE5),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EquipmentListScreen(
                          appState: widget.appState,
                          initialAvailability: EquipmentAvailability.available,
                        ),
                      ),
                    );
                  },
                ),
                QuickStatCard(
                  title: 'In Active Use',
                  value: '$inUseCount',
                  icon: Icons.play_circle_outline_rounded,
                  color: const Color(0xFF0284C7),
                  bgColor: const Color(0xFFE0F2FE),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EquipmentListScreen(
                          appState: widget.appState,
                          initialAvailability: EquipmentAvailability.inUse,
                        ),
                      ),
                    );
                  },
                ),
                QuickStatCard(
                  title: 'In Maintenance',
                  value: '$maintenanceCount',
                  icon: Icons.build_circle_outlined,
                  color: const Color(0xFFF59E0B),
                  bgColor: const Color(0xFFFEF3C7),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EquipmentListScreen(
                          appState: widget.appState,
                          initialAvailability: EquipmentAvailability.underMaintenance,
                        ),
                      ),
                    );
                  },
                ),
                QuickStatCard(
                  title: 'Missing / Urgent',
                  value: '$missingCount',
                  icon: Icons.warning_amber_rounded,
                  color: const Color(0xFFEF4444),
                  bgColor: const Color(0xFFFEE2E2),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EquipmentListScreen(
                          appState: widget.appState,
                          initialAvailability: EquipmentAvailability.missing,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Complaints Management Bar
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.assignment_late_rounded, color: Color(0xFF6366F1), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${complaints.length} Total Complaints Logged',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textMainLight),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Review nurse incident reports & update resolution logs',
                          style: TextStyle(fontSize: 12, color: AppColors.textMutedLight),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ComplaintListScreen(appState: widget.appState)),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    child: const Text('Open Queue'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      ),
    );
      }
    );
  }
}

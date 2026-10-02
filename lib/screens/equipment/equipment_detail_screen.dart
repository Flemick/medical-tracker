import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/complaint.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_badge.dart';
import '../complaints/create_complaint_screen.dart';

class EquipmentDetailScreen extends StatefulWidget {
  final String equipmentId;
  final AppState appState;

  const EquipmentDetailScreen({
    super.key,
    required this.equipmentId,
    required this.appState,
  });

  @override
  State<EquipmentDetailScreen> createState() => _EquipmentDetailScreenState();
}

class _EquipmentDetailScreenState extends State<EquipmentDetailScreen> {
  String _formatRelativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hrs ago';
    return DateFormat('MMM d, y • h:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final equipment = widget.appState.getEquipmentById(widget.equipmentId);

    if (equipment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Equipment Details')),
        body: const Center(child: Text('Equipment not found.')),
      );
    }

    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(equipment.qrCode),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Primary Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    AppColors.primarySurface.withValues(alpha: 0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      equipment.category.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    equipment.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMainLight,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Model: ${equipment.modelNumber} • SN: ${equipment.serialNumber}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMutedLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: AppColors.borderLight),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AvailabilityBadge(availability: equipment.availability),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 1. Location Section
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
                  const Row(
                    children: [
                      Icon(Icons.location_on_rounded, color: Color(0xFFEF4444), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Hospital Location & Station',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMainLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      children: [
                        _buildLocationRow('Ward / Department', equipment.location.department),
                        const Divider(height: 16, color: AppColors.borderLight),
                        _buildLocationRow('Building & Floor', '${equipment.location.building} • ${equipment.location.floor}'),
                        const Divider(height: 16, color: AppColors.borderLight),
                        _buildLocationRow('Room & Station Slot', 'Room ${equipment.location.room}${equipment.location.bedOrStation != null ? ' (${equipment.location.bedOrStation})' : ''}'),
                        if (equipment.currentAssignedPatient != null) ...[
                          const Divider(height: 16, color: AppColors.borderLight),
                          _buildLocationRow('Assigned Patient', equipment.currentAssignedPatient!),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Maintenance Status & History
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
                  const Row(
                    children: [
                      Icon(Icons.build_circle_rounded, color: Color(0xFFF59E0B), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'BioMed Maintenance Status',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMainLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildMaintenanceRow(
                    label: 'Last Inspection / Service',
                    value: dateFormat.format(equipment.lastMaintainedDate),
                    icon: Icons.history_rounded,
                    isPositive: true,
                  ),
                  const SizedBox(height: 10),
                  _buildMaintenanceRow(
                    label: 'Next Calibration Due',
                    value: dateFormat.format(equipment.nextMaintenanceDate),
                    icon: Icons.event_available_rounded,
                    isPositive: equipment.nextMaintenanceDate.isAfter(DateTime.now()),
                  ),
                  const SizedBox(height: 10),
                  _buildMaintenanceRow(
                    label: 'Manufacturer & Support',
                    value: equipment.manufacturer,
                    icon: Icons.business_rounded,
                    isPositive: true,
                  ),
                  if (equipment.notes.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.sticky_note_2_rounded, size: 16, color: Color(0xFFD97706)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              equipment.notes,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF92400E),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Last Updated Tracker Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.update_rounded, size: 18, color: AppColors.textMutedLight),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Last updated ${_formatRelativeTime(equipment.lastUpdatedTime)} by ${equipment.lastUpdatedBy}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMutedLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Complaint Report Action Buttons
            const Text(
              'Report Issue for this Equipment',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textMainLight,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateComplaintScreen(
                            appState: widget.appState,
                            preselectedEquipmentId: equipment.id,
                            initialType: ComplaintType.equipmentProblem,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.report_problem_rounded, size: 18),
                    label: const Text('Problem / Error'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD97706),
                      side: const BorderSide(color: Color(0xFFD97706)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateComplaintScreen(
                            appState: widget.appState,
                            preselectedEquipmentId: equipment.id,
                            initialType: ComplaintType.missingEquipment,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.search_off_rounded, size: 18),
                    label: const Text('Missing'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  side: const BorderSide(color: AppColors.secondary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateComplaintScreen(
                        appState: widget.appState,
                        preselectedEquipmentId: equipment.id,
                        initialType: ComplaintType.unavailableEquipment,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.lock_clock_rounded, size: 18),
                label: const Text('Report Unavailable / Blocked'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.textMutedLight,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textMainLight,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildMaintenanceRow({
    required String label,
    required String value,
    required IconData icon,
    required bool isPositive,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isPositive ? AppColors.textMutedLight : Colors.red),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.textMutedLight,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isPositive ? AppColors.textMainLight : Colors.red,
          ),
        ),
      ],
    );
  }
}

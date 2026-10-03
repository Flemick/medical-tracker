import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/complaint.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_badge.dart';
import '../equipment/equipment_detail_screen.dart';

class ComplaintDetailScreen extends StatefulWidget {
  final String complaintId;
  final AppState appState;

  const ComplaintDetailScreen({
    super.key,
    required this.complaintId,
    required this.appState,
  });

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  final _resolutionController = TextEditingController();

  @override
  void dispose() {
    _resolutionController.dispose();
    super.dispose();
  }

  void _showStatusUpdateDialog(ComplaintModel complaint) {
    ComplaintStatus selectedStatus = complaint.status;
    final noteController = TextEditingController(
      text: 'BioMed engineer dispatched on-site to inspect device.',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Update Ticket #${complaint.ticketNumber} Status'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select New Status:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<ComplaintStatus>(
                      initialValue: selectedStatus,
                      items: ComplaintStatus.values.map((s) {
                        return DropdownMenuItem(
                          value: s,
                          child: Text(AppTheme.getComplaintStatusLabel(s)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedStatus = val);
                        }
                      },
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Status Note / Tech Update:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: noteController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Enter explanation or technician action...',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await widget.appState.updateComplaintStatus(
                        complaint.id,
                        selectedStatus,
                        note: noteController.text.trim().isNotEmpty
                            ? noteController.text.trim()
                            : 'Status updated to ${AppTheme.getComplaintStatusLabel(selectedStatus)}',
                        assignedTech: selectedStatus == ComplaintStatus.assignedToTech ||
                                selectedStatus == ComplaintStatus.inProgress
                            ? 'Tech Jackson (BioMed)'
                            : null,
                        resolution: selectedStatus == ComplaintStatus.resolved
                            ? 'Device recalibrated, tested, and returned to clinical pool.'
                            : null,
                      );
                      if (!mounted) return;
                      Navigator.pop(ctx);
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Ticket updated to "${AppTheme.getComplaintStatusLabel(selectedStatus)}"'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppColors.primaryDark,
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update: $e')),
                      );
                    }
                  },
                  child: const Text('Update Ticket'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final complaint = widget.appState.complaints.cast<ComplaintModel?>().firstWhere(
          (c) => c?.id == widget.complaintId,
          orElse: () => null,
        );

    if (complaint == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Complaint Details')),
        body: const Center(child: Text('Complaint not found.')),
      );
    }

    final dateFormat = DateFormat('MMM dd, yyyy • h:mm a');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Ticket #${complaint.ticketNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_alt_rounded),
            tooltip: 'Simulate Tech Status Progression',
            onPressed: () => _showStatusUpdateDialog(complaint),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Ticket Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TICKET #${complaint.ticketNumber}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                      ComplaintStatusBadge(status: complaint.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SeverityBadge(severity: complaint.severity),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getTypeLabel(complaint.type),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMainLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: AppColors.borderLight),
                  const SizedBox(height: 14),
                  _buildDetailRow('Reported By', '${complaint.nurseName} (${complaint.nurseDepartment})'),
                  const SizedBox(height: 8),
                  _buildDetailRow('Reported At', dateFormat.format(complaint.reportedAt)),
                  const SizedBox(height: 8),
                  _buildDetailRow('Incident Location', complaint.reportedLocation),
                  if (complaint.assignedTechName != null) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow('Assigned Technician', complaint.assignedTechName!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Associated Equipment Card (Clickable to jump to Equipment)
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EquipmentDetailScreen(
                      equipmentId: complaint.equipmentId,
                      appState: widget.appState,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.devices_other_rounded, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            complaint.equipmentName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMainLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tag: ${complaint.equipmentCode} • ${complaint.equipmentCategory}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textMutedLight),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Problem Description & Error Code
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reported Problem Description',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMainLight,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    complaint.description,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textMainLight,
                      height: 1.45,
                    ),
                  ),
                  if (complaint.errorCode != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.code_rounded, size: 16, color: Color(0xFFDC2626)),
                          const SizedBox(width: 8),
                          Text(
                            'Error Displayed: ${complaint.errorCode}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFB91C1C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (complaint.resolutionSummary != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF6EE7B7)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF059669)),
                              SizedBox(width: 6),
                              Text(
                                'Resolution Notes:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF065F46),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            complaint.resolutionSummary!,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF065F46),
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

            // Timeline Progress Log
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
                      Icon(Icons.timeline_rounded, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Ticket Audit Timeline',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMainLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(complaint.timeline.length, (index) {
                    final event = complaint.timeline[index];
                    final isLast = index == complaint.timeline.length - 1;

                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: isLast ? AppColors.primary : const Color(0xFF94A3B8),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              if (!isLast)
                                Expanded(
                                  child: Container(
                                    width: 2,
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        event.title,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textMainLight,
                                        ),
                                      ),
                                      Text(
                                        dateFormat.format(event.timestamp),
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: AppColors.textMutedLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    event.description,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMutedLight,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'by ${event.actorName} (${event.actorRole})',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action: Advance Status
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showStatusUpdateDialog(complaint),
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: const Text('Update Ticket Status & Progress'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(ComplaintType type) {
    switch (type) {
      case ComplaintType.equipmentProblem:
        return 'Equipment Malfunction';
      case ComplaintType.missingEquipment:
        return 'Missing Equipment Report';
      case ComplaintType.unavailableEquipment:
        return 'Equipment Unavailable';
      case ComplaintType.other:
        return 'General Issue';
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.textMutedLight,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textMainLight,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/complaint.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_badge.dart';
import 'create_complaint_screen.dart';
import 'complaint_detail_screen.dart';

class ComplaintListScreen extends StatefulWidget {
  final AppState appState;

  const ComplaintListScreen({super.key, required this.appState});

  @override
  State<ComplaintListScreen> createState() => _ComplaintListScreenState();
}

class _ComplaintListScreenState extends State<ComplaintListScreen> {
  String _filterTab = 'All'; // 'All', 'Active', 'Resolved'

  String _formatDate(DateTime dt) {
    return DateFormat('MMM d, y • h:mm a').format(dt);
  }

  List<ComplaintModel> _getComplaints() {
    final list = widget.appState.getComplaintsForCurrentNurse();

    if (_filterTab == 'Active') {
      return list.where((c) => c.status != ComplaintStatus.resolved && c.status != ComplaintStatus.rejected).toList();
    } else if (_filterTab == 'Resolved') {
      return list.where((c) => c.status == ComplaintStatus.resolved).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final complaints = _getComplaints();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Equipment Reports & Complaints'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateComplaintScreen(appState: widget.appState),
            ),
          );
          setState(() {});
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Report New Issue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // Filter Tabs Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                _buildTabButton('All (${widget.appState.getComplaintsForCurrentNurse().length})', 'All'),
                const SizedBox(width: 8),
                _buildTabButton('Active / In Progress', 'Active'),
                const SizedBox(width: 8),
                _buildTabButton('Resolved', 'Resolved'),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderLight),

          // Complaint List
          Expanded(
            child: complaints.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_turned_in_outlined, size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'No reports found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMainLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tap the button below to report an equipment issue',
                          style: TextStyle(fontSize: 13, color: AppColors.textMutedLight),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: complaints.length,
                    itemBuilder: (context, index) {
                      final item = complaints[index];
                      return _buildComplaintCard(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, String tabKey) {
    final isSelected = _filterTab == tabKey;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _filterTab = tabKey),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textMutedLight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComplaintCard(ComplaintModel item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ComplaintDetailScreen(
                complaintId: item.id,
                appState: widget.appState,
              ),
            ),
          );
          setState(() {});
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ticket & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        '#${item.ticketNumber}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SeverityBadge(severity: item.severity),
                    ],
                  ),
                  ComplaintStatusBadge(status: item.status, compact: true),
                ],
              ),
              const SizedBox(height: 10),

              // Equipment Title
              Text(
                item.equipmentName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMainLight,
                ),
              ),
              const SizedBox(height: 4),

              // Description snippet
              Text(
                item.description,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textMutedLight,
                  height: 1.35,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.borderLight),
              const SizedBox(height: 8),

              // Footer: Location & Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFFEF4444)),
                      const SizedBox(width: 4),
                      Text(
                        item.reportedLocation.split('•').first.trim(),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _formatDate(item.reportedAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

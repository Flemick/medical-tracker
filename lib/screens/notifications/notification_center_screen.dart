import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/notification_item.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';
import '../complaints/complaint_detail_screen.dart';
import '../equipment/equipment_detail_screen.dart';

class NotificationCenterScreen extends StatefulWidget {
  final AppState appState;

  const NotificationCenterScreen({super.key, required this.appState});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  bool _filterUnreadOnly = false;

  String _formatRelativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d, h:mm a').format(dateTime);
  }

  void _handleNotificationTap(NotificationItem notif) {
    widget.appState.markNotificationAsRead(notif.id);

    if (notif.relatedComplaintId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ComplaintDetailScreen(
            complaintId: notif.relatedComplaintId!,
            appState: widget.appState,
          ),
        ),
      );
    } else if (notif.relatedEquipmentId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EquipmentDetailScreen(
            equipmentId: notif.relatedEquipmentId!,
            appState: widget.appState,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allNotifications = widget.appState.currentUserNotifications;
    final notifications = _filterUnreadOnly
        ? allNotifications.where((n) => !n.isRead).toList()
        : allNotifications;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Notifications & Alerts'),
        actions: [
          if (widget.appState.unreadNotificationsCount > 0)
            TextButton.icon(
              onPressed: () {
                widget.appState.markAllNotificationsAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications marked as read'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.done_all_rounded, size: 18, color: AppColors.primary),
              label: const Text(
                'Mark all read',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Switch Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    FilterChip(
                      label: Text('All (${allNotifications.length})'),
                      selected: !_filterUnreadOnly,
                      onSelected: (_) => setState(() => _filterUnreadOnly = false),
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: !_filterUnreadOnly ? FontWeight.w700 : FontWeight.w500,
                        color: !_filterUnreadOnly ? Colors.white : AppColors.textMainLight,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text('Unread (${widget.appState.unreadNotificationsCount})'),
                      selected: _filterUnreadOnly,
                      onSelected: (_) => setState(() => _filterUnreadOnly = true),
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: _filterUnreadOnly ? FontWeight.w700 : FontWeight.w500,
                        color: _filterUnreadOnly ? Colors.white : AppColors.textMainLight,
                      ),
                    ),
                  ],
                ),
                if (allNotifications.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined, size: 20, color: AppColors.textMutedLight),
                    tooltip: 'Clear read notifications',
                    onPressed: () {
                      widget.appState.clearAllNotifications();
                    },
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderLight),

          // Notification List
          Expanded(
            child: notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _filterUnreadOnly ? Icons.mark_email_read_outlined : Icons.notifications_off_outlined,
                          size: 56,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _filterUnreadOnly ? 'No unread notifications' : 'No notifications yet',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMainLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'You are all caught up with equipment and ticket updates',
                          style: TextStyle(fontSize: 13, color: AppColors.textMutedLight),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final item = notifications[index];
                      return _buildNotificationCard(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem item) {
    IconData iconData;
    Color iconColor;
    Color iconBg;

    switch (item.type) {
      case NotificationType.complaintUpdate:
        iconData = Icons.assignment_turned_in_rounded;
        iconColor = const Color(0xFF6366F1);
        iconBg = const Color(0xFFEEF2FF);
        break;
      case NotificationType.equipmentStatusChange:
        iconData = Icons.sensors_rounded;
        iconColor = const Color(0xFF10B981);
        iconBg = const Color(0xFFECFDF5);
        break;
      case NotificationType.maintenanceAlert:
        iconData = Icons.build_circle_rounded;
        iconColor = const Color(0xFFF59E0B);
        iconBg = const Color(0xFFFEF3C7);
        break;
      case NotificationType.systemBroadcast:
        iconData = Icons.campaign_rounded;
        iconColor = const Color(0xFF0284C7);
        iconBg = const Color(0xFFE0F2FE);
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: item.isRead ? Colors.white : const Color(0xFFF0FDFA), // highlighted background for unread
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: item.isRead ? AppColors.borderLight : AppColors.primary.withValues(alpha: 0.4),
          width: item.isRead ? 1 : 1.5,
        ),
      ),
      child: InkWell(
        onTap: () => _handleNotificationTap(item),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Avatar
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),

              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                              color: AppColors.textMainLight,
                            ),
                          ),
                        ),
                        if (!item.isRead) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMutedLight,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatRelativeTime(item.timestamp),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textLight,
                          ),
                        ),
                        if (item.relatedComplaintId != null || item.relatedEquipmentId != null)
                          const Row(
                            children: [
                              Text(
                                'View Details',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primaryDark),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

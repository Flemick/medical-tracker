import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/app_state.dart';
import '../../models/equipment.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/qr_view_modal.dart';
import 'equipment_detail_screen.dart';
import 'qr_scanner_screen.dart';

class EquipmentListScreen extends StatefulWidget {
  final AppState appState;
  final String? initialCategory;
  final EquipmentAvailability? initialAvailability;

  const EquipmentListScreen({
    super.key,
    required this.appState,
    this.initialCategory,
    this.initialAvailability,
  });

  @override
  State<EquipmentListScreen> createState() => _EquipmentListScreenState();
}

class _EquipmentListScreenState extends State<EquipmentListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  EquipmentAvailability? _selectedAvailability;

  final List<String> _categories = [
    'All',
    'Ventilators',
    'Infusion Pumps',
    'Defibrillators',
    'Patient Monitors',
    'ECG Machines',
    'Ultrasound',
    'Dialysis',
    'Suction Units',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
    }
    if (widget.initialAvailability != null) {
      _selectedAvailability = widget.initialAvailability;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatRelativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d').format(dateTime);
  }

  List<EquipmentModel> _getFilteredEquipments() {
    final list = widget.appState.equipments;
    final query = _searchQuery.toLowerCase().trim();

    return list.where((eq) {
      // 1. Search Query Filter
      if (query.isNotEmpty) {
        final matchesName = eq.name.toLowerCase().contains(query);
        final matchesCode = eq.qrCode.toLowerCase().contains(query);
        final matchesSerial = eq.serialNumber.toLowerCase().contains(query);
        final matchesDept = eq.location.department.toLowerCase().contains(query);
        final matchesRoom = eq.location.room.toLowerCase().contains(query);
        final matchesCat = eq.category.toLowerCase().contains(query);

        if (!matchesName && !matchesCode && !matchesSerial && !matchesDept && !matchesRoom && !matchesCat) {
          return false;
        }
      }

      // 2. Category Filter
      if (_selectedCategory != 'All' && eq.category != _selectedCategory) {
        return false;
      }

      // 3. Availability Filter
      if (_selectedAvailability != null && eq.availability != _selectedAvailability) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredEquipments = _getFilteredEquipments();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Hospital Equipment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
            tooltip: 'Open QR Scanner',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QrScannerScreen(appState: widget.appState),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            color: Colors.white,
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search by equipment, QR tag, serial, room...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMutedLight),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                ),
                const SizedBox(height: 10),

                // Category Chips Carousel
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedCategory = cat);
                            }
                          },
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.textMainLight,
                          ),
                          selectedColor: AppColors.primary,
                          backgroundColor: const Color(0xFFF1F5F9),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide.none,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 6),

                // Availability Quick Filter Bar
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildAvailabilityFilterChip(null, 'All Status'),
                      _buildAvailabilityFilterChip(EquipmentAvailability.available, 'Available'),
                      _buildAvailabilityFilterChip(EquipmentAvailability.inUse, 'In Use'),
                      _buildAvailabilityFilterChip(EquipmentAvailability.underMaintenance, 'Maintenance'),
                      _buildAvailabilityFilterChip(EquipmentAvailability.missing, 'Missing'),
                      _buildAvailabilityFilterChip(EquipmentAvailability.reserved, 'Reserved'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Count & Active Filters Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Found ${filteredEquipments.length} equipment items',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMutedLight,
                  ),
                ),
                if (_searchQuery.isNotEmpty || _selectedCategory != 'All' || _selectedAvailability != null)
                  InkWell(
                    onTap: () {
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                        _selectedCategory = 'All';
                        _selectedAvailability = null;
                      });
                    },
                    child: const Text(
                      'Reset Filters',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Equipment List
          Expanded(
            child: filteredEquipments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'No equipment found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMainLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Try adjusting your search keywords or filter criteria',
                          style: TextStyle(fontSize: 13, color: AppColors.textMutedLight),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: filteredEquipments.length,
                    itemBuilder: (context, index) {
                      final item = filteredEquipments[index];
                      return _buildEquipmentCard(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityFilterChip(EquipmentAvailability? status, String label) {
    final isSelected = _selectedAvailability == status;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _selectedAvailability = isSelected ? null : status);
        },
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.textMutedLight,
        ),
        selectedColor: AppColors.primaryDark,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? AppColors.primaryDark : AppColors.borderLight,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 2),
      ),
    );
  }

  Widget _buildEquipmentCard(EquipmentModel item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EquipmentDetailScreen(
                equipmentId: item.id,
                appState: widget.appState,
              ),
            ),
          );
          setState(() {}); // refresh on return
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Tag, Category, Availability
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.qrCode,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.category,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                  AvailabilityBadge(availability: item.availability, compact: true),
                ],
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMainLight,
                ),
              ),
              const SizedBox(height: 6),

              // Location
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFFEF4444)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.location.displayLocation,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMainLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.borderLight),
              const SizedBox(height: 10),

              // Footer: Battery/Power, Last updated time, QR Icon button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        item.batteryLevel != null ? Icons.battery_charging_full_rounded : Icons.power_rounded,
                        size: 14,
                        color: AppColors.textMutedLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.batteryLevel != null ? '${item.batteryLevel}%' : 'AC Powered',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMutedLight,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '•  Updated ${_formatRelativeTime(item.lastUpdatedTime)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => QrViewModal.show(context, item),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.qr_code_2_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
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

import 'package:flutter/material.dart';
import '../../models/complaint.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';
import 'complaint_detail_screen.dart';

class CreateComplaintScreen extends StatefulWidget {
  final AppState appState;
  final String? preselectedEquipmentId;
  final ComplaintType? initialType;

  const CreateComplaintScreen({
    super.key,
    required this.appState,
    this.preselectedEquipmentId,
    this.initialType,
  });

  @override
  State<CreateComplaintScreen> createState() => _CreateComplaintScreenState();
}

class _CreateComplaintScreenState extends State<CreateComplaintScreen> {
  String? _selectedEquipmentId;
  late ComplaintType _selectedType;
  ComplaintSeverity _selectedSeverity = ComplaintSeverity.medium;
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _errorCodeController = TextEditingController();
  bool _hasPhotoAttached = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedEquipmentId = widget.preselectedEquipmentId ??
        (widget.appState.equipments.isNotEmpty ? widget.appState.equipments.first.id : null);
    _selectedType = widget.initialType ?? ComplaintType.equipmentProblem;

    if (_selectedEquipmentId != null) {
      final eq = widget.appState.getEquipmentById(_selectedEquipmentId!);
      if (eq != null) {
        _locationController.text = eq.location.displayLocation;
      }
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    _errorCodeController.dispose();
    super.dispose();
  }

  void _onEquipmentChanged(String? newId) {
    setState(() {
      _selectedEquipmentId = newId;
      if (newId != null) {
        final eq = widget.appState.getEquipmentById(newId);
        if (eq != null) {
          _locationController.text = eq.location.displayLocation;
        }
      }
    });
  }

  void _handleSubmit() {
    setState(() => _errorMessage = null);

    if (_selectedEquipmentId == null) {
      setState(() => _errorMessage = 'Please select a medical equipment.');
      return;
    }
    if (_locationController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please specify the location of the equipment.');
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please provide details or symptoms of the problem.');
      return;
    }

    final newComplaint = widget.appState.submitComplaint(
      equipmentId: _selectedEquipmentId!,
      type: _selectedType,
      severity: _selectedSeverity,
      reportedLocation: _locationController.text.trim(),
      description: _descriptionController.text.trim(),
      errorCode: _errorCodeController.text.trim().isNotEmpty ? _errorCodeController.text.trim() : null,
    );

    // Show Confirmation SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ticket #${newComplaint.ticketNumber} submitted successfully! BioMed alerted.'),
        backgroundColor: AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ComplaintDetailScreen(
          complaintId: newComplaint.id,
          appState: widget.appState,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('File Equipment Report'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reporter Info Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primarySurface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_circle_rounded, color: AppColors.primaryDark, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Reporting Nurse: ${widget.appState.currentUser?.name ?? "Nurse"} (${widget.appState.currentUser?.department ?? "Ward"})',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.statusMissingBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.statusMissing.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.statusMissing, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.statusMissing,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 1. Report Type Selector
            const Text(
              'Complaint / Report Category',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMainLight),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildTypeOption(
                  type: ComplaintType.equipmentProblem,
                  label: 'Equipment Problem',
                  icon: Icons.build_rounded,
                  color: const Color(0xFFEF4444),
                ),
                const SizedBox(width: 8),
                _buildTypeOption(
                  type: ComplaintType.missingEquipment,
                  label: 'Missing Item',
                  icon: Icons.search_off_rounded,
                  color: const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 8),
                _buildTypeOption(
                  type: ComplaintType.unavailableEquipment,
                  label: 'Unavailable',
                  icon: Icons.lock_clock_rounded,
                  color: const Color(0xFF6366F1),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 2. Select Equipment Dropdown
            const Text(
              'Select Medical Equipment',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMainLight),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedEquipmentId,
                  isExpanded: true,
                  hint: const Text('Choose equipment'),
                  icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary),
                  items: widget.appState.equipments.map((eq) {
                    return DropdownMenuItem<String>(
                      value: eq.id,
                      child: Text(
                        '${eq.qrCode} - ${eq.name}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: _onEquipmentChanged,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 3. Urgency / Severity Level
            const Text(
              'Priority / Severity Level',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMainLight),
            ),
            const SizedBox(height: 8),
            Row(
              children: ComplaintSeverity.values.map((sev) {
                final isSelected = _selectedSeverity == sev;
                final color = AppTheme.getSeverityColor(sev);
                String name;
                switch (sev) {
                  case ComplaintSeverity.low:
                    name = 'Low';
                    break;
                  case ComplaintSeverity.medium:
                    name = 'Medium';
                    break;
                  case ComplaintSeverity.high:
                    name = 'High';
                    break;
                  case ComplaintSeverity.emergency:
                    name = 'CRITICAL';
                    break;
                }

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      onTap: () => setState(() => _selectedSeverity = sev),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? color.withValues(alpha: 0.15) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? color : AppColors.borderLight,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? color : AppColors.textMutedLight,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // 4. Incident Location
            const Text(
              'Location / Ward / Room',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMainLight),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.location_on_rounded, color: Color(0xFFEF4444), size: 20),
                hintText: 'e.g. ICU 3rd Floor, Room 304-B',
              ),
            ),
            const SizedBox(height: 20),

            // 5. Error Code (Optional)
            const Text(
              'Error Code / Display Message (Optional)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMainLight),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _errorCodeController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.terminal_rounded, color: AppColors.textMutedLight, size: 20),
                hintText: 'e.g. ERR-302 / Pressure Sensor Fault',
              ),
            ),
            const SizedBox(height: 20),

            // 6. Detailed Problem Description
            const Text(
              'Detailed Description of the Issue',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMainLight),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Describe what happened, any alarms sounding, missing parts, or current patient risk...',
              ),
            ),
            const SizedBox(height: 20),

            // 7. Photo Attachment Simulation
            InkWell(
              onTap: () {
                setState(() => _hasPhotoAttached = !_hasPhotoAttached);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_hasPhotoAttached ? 'Photo snapshot attached to ticket' : 'Photo removed'),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _hasPhotoAttached ? AppColors.primarySurface.withValues(alpha: 0.4) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _hasPhotoAttached ? AppColors.primary : AppColors.borderLight,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _hasPhotoAttached ? Icons.check_circle_rounded : Icons.camera_alt_outlined,
                      color: _hasPhotoAttached ? AppColors.primary : AppColors.textMutedLight,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _hasPhotoAttached ? '1 Diagnostic Photo Attached' : 'Attach Photo / Error Screen Snapshot',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _hasPhotoAttached ? AppColors.primaryDark : AppColors.textMainLight,
                            ),
                          ),
                          Text(
                            _hasPhotoAttached ? 'device_error_capture.jpg (Ready to upload)' : 'Tap to simulate capturing camera photo',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMutedLight),
                          ),
                        ],
                      ),
                    ),
                    if (_hasPhotoAttached)
                      const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _handleSubmit,
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('Submit Report to BioMed Team'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption({
    required ComplaintType type,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedType == type;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedType = type),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.12) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppColors.borderLight,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : AppColors.textMutedLight, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? color : AppColors.textMainLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';

class CreateNurseDialog extends StatefulWidget {
  final AppState appState;

  const CreateNurseDialog({super.key, required this.appState});

  static Future<void> show(BuildContext context, AppState appState) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CreateNurseDialog(appState: appState),
    );
  }

  @override
  State<CreateNurseDialog> createState() => _CreateNurseDialogState();
}

class _CreateNurseDialogState extends State<CreateNurseDialog> {
  final _nameController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _roleTitleController = TextEditingController(text: 'Staff Nurse, RN');
  final _pinController = TextEditingController(text: '1234');
  
  String _selectedDepartment = 'ICU - Intensive Care';
  String _selectedShift = 'Morning (07:00 - 15:00)';
  String? _errorMessage;

  final List<String> _departments = [
    'ICU - Intensive Care',
    'Emergency Room (ER)',
    'Pediatric Care Unit',
    'Cardiology & Cath Lab',
    'General Ward - East',
    'Surgical & Recovery',
    'Nephrology & Dialysis',
    'Maternity & Neonatal',
  ];

  final List<String> _shifts = [
    'Morning (07:00 - 15:00)',
    'Evening (15:00 - 23:00)',
    'Night (23:00 - 07:00)',
    'General Shift (08:00 - 17:00)',
  ];

  @override
  void initState() {
    super.initState();
    // Auto-generate sample ID
    final nextNum = 1000 + (widget.appState.nurses.length * 100) + 12;
    _employeeIdController.text = 'NUR-$nextNum';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _employeeIdController.dispose();
    _emailController.dispose();
    _roleTitleController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _handleCreate() {
    setState(() => _errorMessage = null);

    final name = _nameController.text.trim();
    final empId = _employeeIdController.text.trim().toUpperCase();
    final email = _emailController.text.trim();
    final roleTitle = _roleTitleController.text.trim();
    final pin = _pinController.text.trim();

    if (name.isEmpty || empId.isEmpty) {
      setState(() => _errorMessage = 'Please enter Nurse Name and Employee ID');
      return;
    }

    final createdNurse = widget.appState.createNurse(
      employeeId: empId,
      name: name,
      email: email.isNotEmpty ? email : '${name.toLowerCase().replaceAll(' ', '.')}@stjude-hospital.org',
      department: _selectedDepartment,
      roleTitle: roleTitle.isNotEmpty ? roleTitle : 'Registered Nurse',
      shift: _selectedShift,
      pin: pin.isNotEmpty ? pin : '1234',
    );

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Nurse account created for ${createdNurse.name} (${createdNurse.employeeId})'),
        backgroundColor: AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.person_add_rounded, color: AppColors.primary, size: 24),
                      SizedBox(width: 10),
                      Text(
                        'Register New Nurse',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textMainLight,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Create nurse credentials. Nurses do not self-register.',
                style: TextStyle(fontSize: 12, color: AppColors.textMutedLight),
              ),
              const SizedBox(height: 16),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.statusMissingBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.statusMissing, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],

              // Form fields
              _buildFieldLabel('Full Name & Title'),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'e.g. Maya Patel, RN'),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Employee ID'),
                        TextField(
                          controller: _employeeIdController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(hintText: 'NUR-5012'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Login PIN'),
                        TextField(
                          controller: _pinController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: '4-digit PIN'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildFieldLabel('Department / Ward'),
              DropdownButtonFormField<String>(
                initialValue: _selectedDepartment,
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                items: _departments.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (v) => setState(() => _selectedDepartment = v!),
              ),
              const SizedBox(height: 12),

              _buildFieldLabel('Assigned Shift'),
              DropdownButtonFormField<String>(
                initialValue: _selectedShift,
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                items: _shifts.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (v) => setState(() => _selectedShift = v!),
              ),
              const SizedBox(height: 20),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _handleCreate,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Create Account'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textMainLight),
      ),
    );
  }
}

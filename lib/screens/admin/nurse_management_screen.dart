// nurse_management_screen.dart — DEPRECATED (Admin-only screen).
// Compilation stub only. Will be removed in Stage 13.
// Staff management is handled by the Admin web portal, not this Flutter app.

import 'package:flutter/material.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';
import 'create_nurse_dialog.dart';

class NurseManagementScreen extends StatefulWidget {
  final AppState appState;

  const NurseManagementScreen({super.key, required this.appState});

  @override
  State<NurseManagementScreen> createState() => _NurseManagementScreenState();
}

class _NurseManagementScreenState extends State<NurseManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staff Management')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.admin_panel_settings_rounded,
                size: 48, color: AppColors.textLight),
            const SizedBox(height: 16),
            const Text(
              'Staff management is available\non the Admin web portal.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMutedLight, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: const Text('Add New User'),
              onPressed: () => CreateNurseDialog.show(context, widget.appState),
            ),
          ],
        ),
      ),
    );
  }
}

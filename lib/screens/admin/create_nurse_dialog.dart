// create_nurse_dialog.dart — DEPRECATED (Admin-only screen).
// This file is a compilation stub only. It will be removed in Stage 13.
// User registration is done by the Admin via the web frontend, not this Flutter app.

import 'package:flutter/material.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';

class CreateNurseDialog extends StatefulWidget {
  final AppState appState;

  const CreateNurseDialog({super.key, required this.appState});

  static Future<void> show(BuildContext context, AppState appState) {
    return showDialog(
      context: context,
      builder: (_) => CreateNurseDialog(appState: appState),
    );
  }

  @override
  State<CreateNurseDialog> createState() => _CreateNurseDialogState();
}

class _CreateNurseDialogState extends State<CreateNurseDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Admin Feature'),
      content: const Text(
        'User registration is handled by the Admin web portal.',
        style: TextStyle(color: AppColors.textMutedLight),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

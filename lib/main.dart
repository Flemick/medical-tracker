import 'package:flutter/material.dart';
import 'services/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/nurse_home_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MedicalTrackingApp());
}

class MedicalTrackingApp extends StatefulWidget {
  const MedicalTrackingApp({super.key});

  @override
  State<MedicalTrackingApp> createState() => _MedicalTrackingAppState();
}

class _MedicalTrackingAppState extends State<MedicalTrackingApp> {
  final AppState _appState = AppState();

  @override
  void initState() {
    super.initState();
    _appState.addListener(_onStateChange);
  }

  @override
  void dispose() {
    _appState.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'St. Jude Medical Equipment & Tracking',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _getInitialScreen(),
    );
  }

  Widget _getInitialScreen() {
    if (!_appState.isLoggedIn) {
      return LoginScreen(appState: _appState);
    }
    if (_appState.isAdmin) {
      return AdminDashboardScreen(appState: _appState);
    }
    return NurseHomeScreen(appState: _appState);
  }
}

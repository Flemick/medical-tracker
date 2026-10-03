import 'package:flutter/material.dart';
import 'services/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/user_home_screen.dart';

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

  void _onStateChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediPulse — Equipment Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    // Show a splash/loading screen while we validate any stored token.
    if (_appState.isInitializing) {
      return const _SplashScreen();
    }
    // If logged in → USER home; otherwise → Login.
    if (_appState.isLoggedIn) {
      return UserHomeScreen(appState: _appState);
    }
    return LoginScreen(appState: _appState);
  }
}

/// Shown only during the brief startup session-check (< 1 second normally).
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.medical_services_rounded,
                size: 56, color: AppColors.primary),
            SizedBox(height: 16),
            CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2.5,
            ),
          ],
        ),
      ),
    );
  }
}

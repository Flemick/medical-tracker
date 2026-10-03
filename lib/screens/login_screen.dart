// LoginScreen — EMAIL + PASSWORD login for USER role (Nurse/Staff).
// Calls AppState.login() which forwards to Flask /api/auth/login.
// No passwords stored in Flutter. No mock credentials.
// On success → UserHomeScreen. On failure → shows the error from the API.

import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'user_home_screen.dart';

class LoginScreen extends StatefulWidget {
  final AppState appState;

  const LoginScreen({super.key, required this.appState});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email address and password.');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      await widget.appState.login(email, password);
      if (!mounted) return;
      // AppState sets isLoggedIn; navigate to UserHomeScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => UserHomeScreen(appState: widget.appState)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _showServerConfigDialog(BuildContext context) {
    final controller = TextEditingController(text: ApiService().baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.dns_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Server Address', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your Flask backend URL (IP address & port):',
              style: TextStyle(fontSize: 12.5, color: AppColors.textMutedLight),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'http://10.111.176.58:5000',
                labelText: 'Server Base URL',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                widget.appState.setApiBaseUrl(newUrl);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Server URL set to: $newUrl')),
                );
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              children: [
                // ── Logo / Header ─────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.18),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.medical_services_rounded,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'MediPulse',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMainLight,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Medical Equipment Tracking System',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textMutedLight),
                ),
                const SizedBox(height: 32),

                // ── Login Card ───────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Staff Login',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMainLight,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings_ethernet_rounded,
                                size: 20, color: AppColors.primary),
                            tooltip: 'Configure Server IP',
                            onPressed: () => _showServerConfigDialog(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Enter your hospital email and password to continue.',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textMutedLight),
                      ),
                      const SizedBox(height: 20),

                      // ── Info notice ──────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.25)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded,
                                color: AppColors.primaryDark, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Accounts are created by the System Administrator. '
                                'Contact your admin if you cannot log in.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Error message ────────────────────────────────
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.statusMissingBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppColors.statusMissing
                                    .withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: AppColors.statusMissing, size: 18),
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

                      // ── Email field ──────────────────────────────────
                      const Text(
                        'Email Address',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMainLight,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _emailController,
                        textCapitalization: TextCapitalization.none,
                        autocorrect: false,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email_outlined,
                              color: AppColors.primary, size: 20),
                          hintText: 'you@hospital.org',
                          hintStyle: TextStyle(
                            color: AppColors.textLight.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Password field ───────────────────────────────
                      const Text(
                        'Password',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMainLight,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        keyboardType: TextInputType.visiblePassword,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline_rounded,
                              color: AppColors.primary, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.textMutedLight,
                              size: 18,
                            ),
                            onPressed: () {
                              setState(
                                  () => _obscurePassword = !_obscurePassword);
                            },
                          ),
                          hintText: 'Enter your password',
                          hintStyle: TextStyle(
                            color: AppColors.textLight.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                        onSubmitted: (_) => _handleLogin(),
                      ),
                      const SizedBox(height: 24),

                      // ── Submit button ────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Access Workspace'),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward_rounded, size: 18),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'MediPulse v1.0 · Secure Staff Portal',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.textLight),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

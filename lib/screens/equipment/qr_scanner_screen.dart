import 'package:flutter/material.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';
import 'equipment_detail_screen.dart';

class QrScannerScreen extends StatefulWidget {
  final AppState appState;

  const QrScannerScreen({super.key, required this.appState});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  final _manualCodeController = TextEditingController();
  bool _isTorchOn = false;
  String? _scanError;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  void _onCodeScanned(String code) {
    setState(() => _scanError = null);
    final eq = widget.appState.getEquipmentByQrOrCode(code);
    if (eq != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EquipmentDetailScreen(
            equipmentId: eq.id,
            appState: widget.appState,
          ),
        ),
      );
    } else {
      setState(() {
        _scanError = 'No equipment matched QR tag "$code"';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark clinical viewfinder background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Equipment QR Scanner',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _isTorchOn ? const Color(0xFFFBBF24) : Colors.white,
            ),
            tooltip: 'Toggle Flashlight',
            onPressed: () {
              setState(() => _isTorchOn = !_isTorchOn);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              const Text(
                'Point camera at the QR code on the medical device',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
              const SizedBox(height: 20),

              // Viewfinder Box with Laser Animation
              Center(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.primaryLight.withValues(alpha: 0.8),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryLight.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Viewfinder corner marks
                      const Positioned(
                        top: 16,
                        left: 16,
                        child: Icon(Icons.crop_free_rounded, color: AppColors.primaryLight, size: 36),
                      ),
                      const Positioned(
                        top: 16,
                        right: 16,
                        child: RotatedBox(
                          quarterTurns: 1,
                          child: Icon(Icons.crop_free_rounded, color: AppColors.primaryLight, size: 36),
                        ),
                      ),
                      const Positioned(
                        bottom: 16,
                        left: 16,
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: Icon(Icons.crop_free_rounded, color: AppColors.primaryLight, size: 36),
                        ),
                      ),
                      const Positioned(
                        bottom: 16,
                        right: 16,
                        child: RotatedBox(
                          quarterTurns: 2,
                          child: Icon(Icons.crop_free_rounded, color: AppColors.primaryLight, size: 36),
                        ),
                      ),

                      // Animated Laser Line
                      AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          return Positioned(
                            top: 40 + (_animation.value * 180),
                            left: 30,
                            right: 30,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: const Color(0xFF22D3EE),
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF22D3EE).withValues(alpha: 0.8),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      // Center QR Icon
                      Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 64,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ],
                  ),
                ),
              ),

              if (_scanError != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.statusMissingBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.statusMissing, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _scanError!,
                          style: const TextStyle(
                            color: AppColors.statusMissing,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Quick Test Scan Chips (Interactive Demo)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.touch_app_rounded, color: Color(0xFF38BDF8), size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Test Scan Available Hospital QR Tags:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.appState.equipments.take(6).map((eq) {
                        return ActionChip(
                          avatar: const Icon(Icons.qr_code_2_rounded, size: 16, color: Color(0xFF0F172A)),
                          label: Text(
                            eq.qrCode,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          backgroundColor: const Color(0xFFE2E8F0),
                          onPressed: () => _onCodeScanned(eq.qrCode),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Manual Code Entry
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Or Enter Equipment / Serial Code Manually',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _manualCodeController,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              hintText: 'e.g. EQ-VENT-101',
                              hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                              filled: true,
                              fillColor: const Color(0xFF0F172A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFF475569)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            onSubmitted: (val) => _onCodeScanned(val),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _onCodeScanned(_manualCodeController.text),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          ),
                          child: const Text('Open'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

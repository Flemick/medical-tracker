import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isTorchOn = false;
  bool _isScanned = false;
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
    _scannerController.dispose();
    super.dispose();
  }

  void _onCodeScanned(String rawCode) {
    if (_isScanned) return;
    final code = rawCode.trim();
    if (code.isEmpty) return;

    // Handle full URLs (e.g. http://127.0.0.1:5000/equipment/EQ-VENT-01)
    String cleanCode = code;
    if (code.contains('/equipment/')) {
      cleanCode = code.split('/equipment/').last.split('?').first;
    }

    final eq = widget.appState.getEquipmentByQrOrCode(cleanCode) ??
        widget.appState.getEquipmentByQrOrCode(code);

    if (eq != null) {
      setState(() {
        _isScanned = true;
        _scanError = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Matched ${eq.name} (${eq.qrCode})'),
              ),
            ],
          ),
          backgroundColor: AppColors.statusAvailable,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1200),
        ),
      );

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
        _scanError = 'No equipment matched QR tag "$cleanCode"';
      });
    }
  }

  void _toggleTorch() async {
    await _scannerController.toggleTorch();
    setState(() => _isTorchOn = !_isTorchOn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
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
            onPressed: _toggleTorch,
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
            tooltip: 'Switch Camera',
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              const Text(
                'Point camera at the QR code tag on the medical device',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
              const SizedBox(height: 20),

              // Live Camera Viewfinder Box with Laser Overlay
              Center(
                child: Container(
                  width: 270,
                  height: 270,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.primaryLight.withValues(alpha: 0.8),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryLight.withValues(alpha: 0.3),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(21),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Live Camera Scanner Stream
                        MobileScanner(
                          controller: _scannerController,
                          onDetect: (capture) {
                            final barcodes = capture.barcodes;
                            for (final barcode in barcodes) {
                              final val = barcode.rawValue;
                              if (val != null && val.trim().isNotEmpty) {
                                _onCodeScanned(val);
                                break;
                              }
                            }
                          },
                          errorBuilder: (context, error, child) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.videocam_off_rounded,
                                      color: Colors.white.withValues(alpha: 0.5),
                                      size: 40,
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Camera Offline / Simulator Mode',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Use manual entry or demo tags below',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.white38, fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        // Viewfinder corner marks
                        const Positioned(
                          top: 14,
                          left: 14,
                          child: Icon(Icons.crop_free_rounded, color: AppColors.primaryLight, size: 38),
                        ),
                        const Positioned(
                          top: 14,
                          right: 14,
                          child: RotatedBox(
                            quarterTurns: 1,
                            child: Icon(Icons.crop_free_rounded, color: AppColors.primaryLight, size: 38),
                          ),
                        ),
                        const Positioned(
                          bottom: 14,
                          left: 14,
                          child: RotatedBox(
                            quarterTurns: 3,
                            child: Icon(Icons.crop_free_rounded, color: AppColors.primaryLight, size: 38),
                          ),
                        ),
                        const Positioned(
                          bottom: 14,
                          right: 14,
                          child: RotatedBox(
                            quarterTurns: 2,
                            child: Icon(Icons.crop_free_rounded, color: AppColors.primaryLight, size: 38),
                          ),
                        ),

                        // Animated Laser Line
                        AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            return Positioned(
                              top: 35 + (_animation.value * 195),
                              left: 24,
                              right: 24,
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      AppColors.primaryLight,
                                      Colors.white,
                                      AppColors.primaryLight,
                                      Colors.transparent,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryLight.withValues(alpha: 0.8),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (_scanError != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.statusMissing.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.statusMissing.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded, color: AppColors.statusMissing, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _scanError!,
                          style: const TextStyle(color: Color(0xFFFDA4AF), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // Manual Code Input Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.keyboard_outlined, color: AppColors.primaryLight, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Manual Tag / Serial Lookup',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _manualCodeController,
                            textCapitalization: TextCapitalization.characters,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'e.g. EQ-VENT-01, EQ-INF-03',
                              hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                              filled: true,
                              fillColor: const Color(0xFF0F172A),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF334155)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF334155)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primaryLight),
                              ),
                            ),
                            onSubmitted: _onCodeScanned,
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () => _onCodeScanned(_manualCodeController.text),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Find Device', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Quick Test QR Tags
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF334155).withValues(alpha: 0.6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Test QR Codes:',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.appState.equipments.take(6).map((eq) {
                        return ActionChip(
                          backgroundColor: const Color(0xFF0F172A),
                          side: const BorderSide(color: Color(0xFF334155)),
                          avatar: const Icon(Icons.qr_code_2_rounded, color: AppColors.primaryLight, size: 16),
                          label: Text(
                            '${eq.name.split(' ').first} (#${eq.qrCode})',
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                          onPressed: () => _onCodeScanned(eq.qrCode),
                        );
                      }).toList(),
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

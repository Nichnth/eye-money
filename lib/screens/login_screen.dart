import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import '../services/haptic_service.dart';
import '../theme/app_theme.dart';
import '../utils/voice.dart';
import 'register_screen.dart';
import 'read_count_screen.dart';

enum LoginState {
  welcome,    // Log in - 1: Selamat datang kembali (tidak ada kontainer foto)
  scanning1,  // Log in - 2: Memindai... (ada kontainer foto + teks + icon scan)
  scanning2,  // Log in - 3: Sedikit lagi...
  success,    // Log in - 4: Berhasil
  failure,    // Log in - 5: Gagal
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  LoginState _state = LoginState.welcome;
  Timer? _stateTimer;
  Timer? _timeoutTimer;
  
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  late AnimationController _scannerController;
  late Animation<double> _scannerAnimation;

  @override
  void initState() {
    super.initState();
    
    // Set up scanning line animation
    _scannerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _scannerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scannerController, curve: Curves.easeInOut),
    );

    // Warm up the camera eagerly during the welcome screen
    _initializeCamera();

    // Start state machine flow
    _startFlow();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      // Select the front camera for face verification
      final frontCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("Camera initialization failed: $e");
    }
  }

  @override
  void dispose() {
    _stateTimer?.cancel();
    _timeoutTimer?.cancel();
    _scannerController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  void _startFlow() {
    _stateTimer?.cancel();
    _timeoutTimer?.cancel();
    
    setState(() {
      _state = LoginState.welcome;
    });

    voiceFeedback(context, "Selamat datang kembali.");
    HapticService.instance.selection();

    // After 3 seconds in Welcome back screen, automatically start scanning
    _stateTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) _transitionToScanning1();
    });
  }

  void _transitionToScanning1() {
    setState(() {
      _state = LoginState.scanning1;
    });
    
    voiceFeedback(context, "Memindai wajah.");
    HapticService.instance.press();

    // Start global timeout: if no tap within 4 seconds of starting scanning, it fails
    _timeoutTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) _transitionToFailure();
    });

    // After 1.5 seconds, transition to scanning phase 2 (Sedikit lagi...)
    _stateTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted && _state == LoginState.scanning1) {
        _transitionToScanning2();
      }
    });
  }

  void _transitionToScanning2() {
    setState(() {
      _state = LoginState.scanning2;
    });
    
    voiceFeedback(context, "Sedikit lagi.");
    HapticService.instance.selection();
  }

  void _transitionToSuccess() {
    _stateTimer?.cancel();
    _timeoutTimer?.cancel(); // Cancel scanning phase timeout
    
    setState(() {
      _state = LoginState.success;
    });
    
    voiceFeedback(context, "Berhasil.");
    HapticService.instance.success();

    // After 2 seconds, transition to read count
    _stateTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ReadCountScreen()),
        );
      }
    });
  }

  void _transitionToFailure() {
    _stateTimer?.cancel();
    _timeoutTimer?.cancel();
    
    setState(() {
      _state = LoginState.failure;
    });
    
    voiceFeedback(context, "Gagal.");
    HapticService.instance.warning();

    // Stay on failure screen for 3 seconds, then restart the whole flow
    _stateTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) _startFlow();
    });
  }

  // GestureDetector Actions
  void _onSingleTap() {
    HapticService.instance.press();
    
    if (_state == LoginState.scanning1 || _state == LoginState.scanning2) {
      _transitionToSuccess();
    }
  }

  void _onDoubleTap() {
    HapticService.instance.press();
    _stateTimer?.cancel();
    _timeoutTimer?.cancel();
    
    voiceFeedback(context, "Masuk ke halaman pendaftaran.");
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool showPhotoContainer = _state != LoginState.welcome;

    return Scaffold(
      backgroundColor: AppColors.green, // Brand green matching Figma
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onSingleTap,
        onDoubleTap: _onDoubleTap,
        child: SafeArea(
          child: Stack(
            children: [
              // System Info (StatusBar decoration)
              Positioned(
                top: 0,
                left: 16,
                right: 16,
                height: 52,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatCurrentTime(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Row(
                      children: [
                        Icon(Icons.signal_cellular_4_bar, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Icon(Icons.wifi, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Icon(Icons.battery_std, color: Colors.white, size: 16),
                      ],
                    ),
                  ],
                ),
              ),

              // Main content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),

                    // Face/Camera scanning mockup container
                    if (showPhotoContainer) ...[
                      Center(
                        child: Container(
                          width: 320,
                          height: 320,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 15,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Stack(
                            clipBehavior: Clip.antiAlias,
                            children: [
                              // Eager live CameraPreview or fallback silhouette image
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: _isCameraInitialized && _cameraController != null
                                      ? FittedBox(
                                          fit: BoxFit.cover,
                                          child: SizedBox(
                                            width: _cameraController!.value.previewSize?.height ?? 320,
                                            height: _cameraController!.value.previewSize?.width ?? 320,
                                            child: CameraPreview(_cameraController!),
                                          ),
                                        )
                                      : Opacity(
                                          opacity: 0.85,
                                          child: Image.asset(
                                            'assets/images/OIP.jpg',
                                            fit: BoxFit.cover,
                                            errorBuilder: (ctx, err, stack) => const Center(
                                              child: Icon(
                                                Icons.face,
                                                size: 140,
                                                color: Color(0xFFCCCCCC),
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
                              ),

                              // Scanning laser line overlay (active when scanning)
                              if (_state == LoginState.scanning1 || _state == LoginState.scanning2)
                                AnimatedBuilder(
                                  animation: _scannerAnimation,
                                  builder: (context, child) {
                                    return Positioned(
                                      top: _scannerAnimation.value * 314, // height minus laser thickness
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: AppColors.green,
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.green.withValues(alpha: 0.8),
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),

                              // Overlay icons for success/failure
                              if (_state == LoginState.success)
                                const Positioned.fill(
                                  child: ColoredBox(
                                    color: Colors.black45,
                                    child: Center(
                                      child: Icon(
                                        Icons.check_circle_outline,
                                        color: AppColors.green,
                                        size: 80,
                                      ),
                                    ),
                                  ),
                                ),

                              if (_state == LoginState.failure)
                                const Positioned.fill(
                                  child: ColoredBox(
                                    color: Colors.black45,
                                    child: Center(
                                      child: Icon(
                                        Icons.cancel_outlined,
                                        color: Colors.redAccent,
                                        size: 80,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],

                    // State texts
                    if (_state == LoginState.welcome) ...[
                      const Text(
                        "Selamat datang kembali!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Ketuk dua kali untuk memindai wajah",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 22,
                          height: 1.4,
                        ),
                      ),
                    ] else ...[
                      // Texts below the white scan container, matching Figma
                      Column(
                        children: [
                          Text(
                            _getTitleText(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Icon(
                            _getStateIcon(),
                            color: Colors.white,
                            size: 48,
                          ),
                        ],
                      ),
                    ],

                    const Spacer(),

                    // Action prompt helper decoration
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _state == LoginState.failure
                              ? "Mengulang pemindaian dalam beberapa detik..."
                              : "Ketuk 1x untuk Lanjut • Ketuk 2x untuk Daftar",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getStateIcon() {
    switch (_state) {
      case LoginState.success:
        return Icons.check_circle_outline;
      case LoginState.failure:
        return Icons.cancel_outlined;
      default:
        return Icons.portrait_rounded;
    }
  }

  String _getTitleText() {
    switch (_state) {
      case LoginState.welcome:
        return "Selamat datang kembali!";
      case LoginState.scanning1:
        return "Memindai...";
      case LoginState.scanning2:
        return "Sedikit lagi...";
      case LoginState.success:
        return "Berhasil";
      case LoginState.failure:
        return "Gagal";
    }
  }

  String _formatCurrentTime() {
    final now = DateTime.now();
    return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import '../services/haptic_service.dart';
import '../services/money_detector.dart';
import '../state/pocket_store.dart';
import '../utils/a11y.dart';
import '../utils/format.dart';
import '../utils/voice.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/circle_action_button.dart';
import '../widgets/notification_banner.dart';
import 'history_screen.dart';

/// "Read and Count Nominal" — point the camera at money, tap the mic to scan.
/// Detection is mocked; the accessible voice + haptic feedback is the point.
class ReadCountScreen extends StatefulWidget {
  const ReadCountScreen({super.key});

  @override
  State<ReadCountScreen> createState() => _ReadCountScreenState();
}

class _ReadMsg {
  final bool isUser;
  final String plain; // used for the screen-reader label
  final List<InlineSpan>? rich; // emphasised detection text (AI only)
  final DateTime time;
  _ReadMsg({required this.isUser, required this.plain, this.rich, required this.time});
}

class _ReadCountScreenState extends State<ReadCountScreen> {
  final MoneyDetector _detector = MockMoneyDetector();
  final ScrollController _scroll = ScrollController();
  final List<_ReadMsg> _messages = [];

  bool _scanning = false;
  DetectionResult? _pending; // counted but not yet saved; the next mic tap saves it.
  ({String title, String message})? _banner;
  Timer? _bannerTimer;

  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      // Select the rear camera for money detection
      final rearCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        rearCamera,
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
    _bannerTimer?.cancel();
    _scroll.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  /// Shows the top banner and auto-hides it so it never lingers over the camera.
  void _showBanner(String title, String message) {
    _bannerTimer?.cancel();
    setState(() => _banner = (title: title, message: message));
    _bannerTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _banner = null);
    });
  }

  void _dismissBanner() {
    _bannerTimer?.cancel();
    if (_banner != null) setState(() => _banner = null);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// The mic carries both voice commands. With no unsaved result it runs
  /// "Berapa uangnya?" (scan + count); once a result is on screen the next tap
  /// runs "Simpan uang" (save into the pocket).
  Future<void> _onMic() async {
    if (_scanning) return;
    if (_pending != null) {
      await _savePending();
      return;
    }
    await _countMoney();
  }

  Future<void> _countMoney() async {
    HapticService.instance.press();
    _bannerTimer?.cancel();
    setState(() {
      _messages.add(_ReadMsg(isUser: true, plain: 'Berapa uangnya?', time: DateTime.now()));
      _scanning = true;
      _banner = null;
    });
    _scrollToBottom();

    // Actually use the camera: capture a frame and hand it to the detector.
    String? shotPath;
    try {
      final cam = _cameraController;
      if (cam != null && cam.value.isInitialized) {
        final shot = await cam.takePicture();
        shotPath = shot.path;
      }
    } catch (e) {
      debugPrint('takePicture failed: $e');
    }

    final result = await _detector.detect(imagePath: shotPath);
    if (!mounted) return;

    setState(() {
      _pending = result;
      _messages.add(_ReadMsg(
        isUser: false,
        plain: result.spoken,
        rich: _detectionSpans(result),
        time: DateTime.now(),
      ));
      _scanning = false;
    });
    _scrollToBottom();
    HapticService.instance.success();
    await voiceFeedback(context,
        '${result.spoken}. Ketuk mikrofon lagi untuk menyimpan uang ke kantong saku.');
  }

  Future<void> _savePending() async {
    final result = _pending;
    if (result == null) return;
    HapticService.instance.press();
    final amount = result.total;
    PocketStore.instance.addMoney(amount);
    setState(() {
      _pending = null;
      _messages.add(_ReadMsg(isUser: true, plain: 'Simpan uang', time: DateTime.now()));
    });
    _showBanner(
      'Nominal berhasil ditambahkan',
      'Nominal sebesar ${formatRupiah(amount)} sudah ditambahkan ke kantong saku.',
    );
    _scrollToBottom();
    HapticService.instance.success();
    await voiceFeedback(context,
        'Nominal berhasil ditambahkan. ${spokenRupiah(amount)} masuk ke kantong saku.');
  }

  /// The wallet button only switches to the pocket view — it performs no action.
  void _onWallet() {
    HapticService.instance.selection();
    voiceFeedback(context, 'Membuka kantong saku.');
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HistoryScreen()),
    );
  }

  /// Builds detection text with the amount words emphasised (bold italic),
  /// e.g. "Satu lembar *seribu* rupiah. Totalnya *seribu* rupiah".
  List<InlineSpan> _detectionSpans(DetectionResult r) {
    const emph = TextStyle(fontWeight: FontWeight.w700, fontStyle: FontStyle.italic);
    String cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
    final spans = <InlineSpan>[];
    for (var i = 0; i < r.items.length; i++) {
      final it = r.items[i];
      final lead = '${terbilang(it.count)} lembar ';
      spans.add(TextSpan(
          text: i == 0
              ? cap(lead)
              : (i == r.items.length - 1 ? ' dan $lead' : ', $lead')));
      spans.add(TextSpan(text: terbilang(it.denom), style: emph));
      spans.add(const TextSpan(text: ' rupiah'));
    }
    spans.add(const TextSpan(text: '. Totalnya '));
    spans.add(TextSpan(text: terbilang(r.total), style: emph));
    spans.add(const TextSpan(text: ' rupiah'));
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Camera viewfinder (live rear camera preview or static asset fallback)
          Positioned.fill(
            child: ExcludeSemantics(
              child: _isCameraInitialized && _cameraController != null
                  ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _cameraController!.value.previewSize?.height ?? MediaQuery.of(context).size.width,
                        height: _cameraController!.value.previewSize?.width ?? MediaQuery.of(context).size.height,
                        child: CameraPreview(_cameraController!),
                      ),
                    )
                  : Image.asset(
                      'assets/images/camera_bg.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const ColoredBox(color: Color(0xFF2A2A2A)),
                    ),
            ),
          ),
          // Top gradient for status-area legibility.
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 140,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xCC1E1E1E), Color(0x001E1E1E)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(child: _buildMessages()),
                _buildControls(),
              ],
            ),
          ),
          if (_banner != null)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              left: 16,
              right: 16,
              child: GestureDetector(
                onTap: _dismissBanner,
                child: NotificationBanner(
                  title: _banner!.title,
                  message: _banner!.message,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    if (_messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Semantics(
            header: true,
            attributedLabel: idLabel(
                'Arahkan kamera ke uang, lalu ketuk tombol mikrofon untuk memindai.'),
            child: ExcludeSemantics(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xCC1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Arahkan kamera ke uang, lalu ketuk tombol mikrofon untuk memindai.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return ListView.separated(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      itemCount: _messages.length,
      separatorBuilder: (_, _) => const SizedBox(height: 9),
      itemBuilder: (_, i) {
        final m = _messages[i];
        if (m.isUser) {
          return Align(
            alignment: Alignment.centerRight,
            child: ChatBubble(
              isAi: false,
              squareBottomRight: true,
              contentAlignEnd: true,
              sender: 'Anda',
              time: formatJam(m.time),
              semanticsLabel: 'Anda berkata: ${m.plain}',
              body: Text(
                m.plain,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          );
        }
        return ChatBubble(
          isAi: true,
          squareBottomRight: true,
          contentAlignEnd: true,
          fullWidth: true,
          liveRegion: i == _messages.length - 1,
          sender: 'AI',
          time: formatJam(m.time),
          semanticsLabel: 'Aplikasi menjawab: ${m.plain}',
          body: Text.rich(
            TextSpan(children: m.rich, style: const TextStyle(fontSize: 16)),
            textAlign: TextAlign.right,
            style: const TextStyle(color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          CircleActionButton(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Kantong saku',
            hint: 'Beralih ke tampilan kantong saku',
            background: Colors.white,
            foreground: const Color(0xFF1E1E1E),
            onPressed: _onWallet,
          ),
          CircleActionButton(
            icon: Icons.mic,
            label: _scanning
                ? 'Sedang memindai uang'
                : (_pending != null ? 'Simpan uang' : 'Pindai uang'),
            hint: _pending != null
                ? 'Ketuk untuk menyimpan uang ke kantong saku'
                : 'Ketuk untuk memindai dan menghitung uang',
            background: Colors.white,
            foreground: const Color(0xFF1E1E1E),
            busy: _scanning,
            onPressed: _onMic,
          ),
        ],
      ),
    );
  }
}

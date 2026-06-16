import 'package:flutter_tts/flutter_tts.dart';

/// Thin wrapper around flutter_tts, configured for Indonesian.
///
/// Degrades gracefully when no TTS engine is available (e.g. desktop),
/// so callers never need to handle platform errors.
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  /// Toggled by settings later; the detection voice is the core feature.
  bool enabled = true;

  Future<void> init() async {
    if (_ready) return;
    try {
      await _tts.setLanguage('id-ID');
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
    } catch (_) {
      // No engine / unsupported platform — speaking becomes a no-op.
    }
    _ready = true;
  }

  Future<void> speak(String text) async {
    if (!enabled || text.trim().isEmpty) return;
    await init();
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}

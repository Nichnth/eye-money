import 'package:flutter/services.dart';

/// Centralised haptic feedback with semantic intent names.
///
/// Uses Flutter's built-in [HapticFeedback]; no extra dependency or
/// permission. No-ops silently on platforms without a vibrator.
class HapticService {
  HapticService._();
  static final HapticService instance = HapticService._();

  bool enabled = true;

  Future<void> selection() async {
    if (enabled) await HapticFeedback.selectionClick();
  }

  Future<void> press() async {
    if (enabled) await HapticFeedback.mediumImpact();
  }

  /// Two-pulse confirmation for a successful action.
  Future<void> success() async {
    if (!enabled) return;
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 90));
    await HapticFeedback.lightImpact();
  }

  Future<void> warning() async {
    if (enabled) await HapticFeedback.heavyImpact();
  }
}

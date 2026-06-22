import 'package:flutter/material.dart';

import '../services/tts_service.dart';

/// Speaks [text] without talking over the OS screen reader.
///
/// When a screen reader (TalkBack/VoiceOver) is active, the spoken content is
/// surfaced through Indonesian-tagged **live regions** (see `idLabel`) so the
/// reader voices it in Indonesian — we deliberately do NOT use
/// `SemanticsService.announce` here, because it can't carry a locale (so it
/// would speak Indonesian text with the reader's default, often English, voice)
/// and is deprecated on Android. When no screen reader is active, the app speaks
/// it itself via `flutter_tts` in `id-ID`. Either way the user hears Indonesian.
Future<void> voiceFeedback(BuildContext context, String text) async {
  final screenReaderOn =
      MediaQuery.maybeOf(context)?.accessibleNavigation ?? false;
  if (screenReaderOn) return; // live regions handle the announcement
  await TtsService.instance.speak(text);
}

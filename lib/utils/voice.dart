import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../services/tts_service.dart';

/// Speaks [text] without talking over the OS screen reader.
///
/// When a screen reader (TalkBack/VoiceOver) is active we route through
/// [SemanticsService.sendAnnouncement] so the reader voices it; otherwise the app
/// speaks it itself via TTS. Either way the user always hears the result.
Future<void> voiceFeedback(BuildContext context, String text) async {
  final screenReaderOn =
      MediaQuery.maybeOf(context)?.accessibleNavigation ?? false;
  if (screenReaderOn) {
    SemanticsService.sendAnnouncement(
      View.of(context),
      text,
      Directionality.of(context),
    );
  } else {
    await TtsService.instance.speak(text);
  }
}

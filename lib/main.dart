import 'package:flutter/material.dart';

import 'screens/read_count_screen.dart';
import 'services/tts_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Warm up the speech engine; safe no-op where unsupported.
  TtsService.instance.init();
  runApp(const EyeMoneyApp());
}

class EyeMoneyApp extends StatelessWidget {
  const EyeMoneyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eye-Money',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const ReadCountScreen(),
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/a11y.dart';

/// Top notification card (e.g. "Nominal berhasil ditambahkan").
///
/// Rendered as a screen-reader live region so it is announced when it
/// appears, in addition to the app's spoken feedback.
class NotificationBanner extends StatelessWidget {
  final String title;
  final String message;

  const NotificationBanner({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      attributedLabel: idLabel('$title. $message'),
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40000000),
                offset: Offset(0, 4),
                blurRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.ink.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

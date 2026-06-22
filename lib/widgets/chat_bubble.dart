import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/a11y.dart';

/// A chat-style message bubble, matching the Eye-Money Figma design.
///
/// AI bubbles are solid green with white text; user ("Anda") bubbles are
/// white with a green outline. One bottom corner is squared to form the
/// "tail". The whole bubble is one screen-reader node via [semanticsLabel].
class ChatBubble extends StatelessWidget {
  final bool isAi;
  final bool squareBottomRight;
  final bool contentAlignEnd;
  final bool fullWidth;
  final String sender;
  final Widget body;
  final String? subtitle;
  final String time;
  final String semanticsLabel;

  /// When true the bubble is announced by the screen reader as soon as it
  /// appears (used for the AI's spoken detection result).
  final bool liveRegion;

  const ChatBubble({
    super.key,
    required this.isAi,
    required this.squareBottomRight,
    required this.contentAlignEnd,
    required this.sender,
    required this.body,
    required this.time,
    required this.semanticsLabel,
    this.subtitle,
    this.fullWidth = false,
    this.liveRegion = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isAi ? AppColors.white : AppColors.ink;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(24),
      topRight: const Radius.circular(24),
      bottomLeft: Radius.circular(squareBottomRight ? 24 : 0),
      bottomRight: Radius.circular(squareBottomRight ? 0 : 24),
    );
    final maxWidth =
        fullWidth ? double.infinity : MediaQuery.sizeOf(context).width * 0.82;

    final contentAlign =
        contentAlignEnd ? Alignment.centerRight : Alignment.centerLeft;

    return Semantics(
      container: true,
      liveRegion: liveRegion,
      attributedLabel: idLabel(semanticsLabel),
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            width: fullWidth ? double.infinity : null,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isAi ? AppColors.green : AppColors.white,
              borderRadius: radius,
              border: isAi
                  ? null
                  : Border.all(color: AppColors.green, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    sender,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: fg.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Align(alignment: contentAlign, child: body),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: contentAlign,
                    child: Text(
                      subtitle!,
                      textAlign: contentAlignEnd ? TextAlign.right : TextAlign.left,
                      style: TextStyle(fontSize: 14, color: fg),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Align(
                  alignment: isAi ? Alignment.centerRight : Alignment.centerLeft,
                  child: Text(
                    time,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: fg.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

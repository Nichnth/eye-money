import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A large (96px) circular action button — the primary control on both
/// screens (camera / wallet / mic). Big tap target, exposed to screen
/// readers as a button with a clear label + hint.
class CircleActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? hint;
  final VoidCallback onPressed;
  final Color background;
  final Color foreground;
  final bool busy;

  const CircleActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.hint,
    required this.onPressed,
    this.background = AppColors.green,
    this.foreground = AppColors.white,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !busy,
      label: label,
      hint: hint,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        child: InkWell(
          onTap: busy ? null : onPressed,
          child: SizedBox(
            width: 96,
            height: 96,
            child: busy
                ? Padding(
                    padding: const EdgeInsets.all(30),
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation(foreground),
                    ),
                  )
                : Icon(icon, size: 40, color: foreground),
          ),
        ),
      ),
    );
  }
}

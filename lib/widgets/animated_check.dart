import 'package:flutter/material.dart';

/// A circular checkbox that pops when toggled.
///
/// The fill colour animates via [AnimatedContainer] and the icon swaps
/// through an [AnimatedSwitcher] with a scale transition, giving a small,
/// satisfying "pop" on completion.
class AnimatedCheck extends StatelessWidget {
  const AnimatedCheck({
    super.key,
    required this.checked,
    required this.onChanged,
    this.size = 28,
  });

  final bool checked;
  final ValueChanged<bool> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      checked: checked,
      button: true,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => onChanged(!checked),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: checked ? scheme.primary : Colors.transparent,
            border: Border.all(
              color: checked ? scheme.primary : scheme.outline,
              width: 2,
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOutBack,
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: checked
                ? Icon(
                    Icons.check_rounded,
                    key: const ValueKey('checked'),
                    size: size * 0.65,
                    color: scheme.onPrimary,
                  )
                : const SizedBox.shrink(key: ValueKey('unchecked')),
          ),
        ),
      ),
    );
  }
}

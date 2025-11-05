import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BottomBarItem {
  final IconData icon;
  final String label;
  const BottomBarItem({required this.icon, required this.label});
}

class BottomBar extends StatelessWidget {
  final int currentIndex;
  final List<BottomBarItem> items;
  final ValueChanged<int> onTap;
  final Widget? rightAction; // settings on the very right

  const BottomBar({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
    this.rightAction,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottomInset = mq.padding.bottom;
    // Base height + safe area inset; tall enough to avoid overflow even with larger text scale
    final base = 20.0;
    final barHeight = base + bottomInset;

    return SafeArea(
      top: false,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: barHeight,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24, width: 0.0),
              borderRadius: BorderRadius.zero,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withOpacity(0.55)
                  : Colors.white.withOpacity(0.55),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Centered cluster of nav items
                Align(
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 280),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (int i = 0; i < items.length; i++)
                          _BottomBarButton(
                            icon: items[i].icon,
                            label: items[i].label,
                            selected: i == currentIndex,
                            onTap: () => onTap(i),
                          ),
                      ],
                    ),
                  ),
                ),
                // Right-aligned action (e.g., settings), vertically centered
                if (rightAction != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: rightAction!,
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

class _BottomBarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BottomBarButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : Colors.white70;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Padding(
        // Slightly tighter vertical padding to avoid overflow at larger text scales
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min, // prevents vertical overflow
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: selected ? 1.12 : 1.0,
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutBack,
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 4),
            // Small text, tight height to keep bar compact
            Text(
              label,
              textScaleFactor:
                  0.95, // avoids blowing up vertically on accessibility text scales
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                height: 1.0,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
            ),
          ],
        ),
      ),
    );
  }
}

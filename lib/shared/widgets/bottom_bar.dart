import 'package:flutter/material.dart';

class BottomBarItem {
  final IconData icon;
  final String label;
  const BottomBarItem({required this.icon, required this.label});
}

class BottomBar extends StatelessWidget {
  final int currentIndex;
  final List<BottomBarItem> items;
  final ValueChanged<int> onTap;
  final Widget? rightAction; // NEW: settings icon on the very right

  const BottomBar({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
    this.rightAction,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white24, width: .5)),
          color: Colors.black,
        ),
        height: 64,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Centered cluster of nav items
            Align(
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
            // Right-aligned action (e.g., settings)
            if (rightAction != null) Positioned(right: 12, child: rightAction!),
          ],
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
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
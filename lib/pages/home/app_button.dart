import 'package:flutter/material.dart';
import '../theme/apptheme.dart';

/// Floating scan button + pill navigation used across the main tabs.
class AppBottomBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final VoidCallback onScan;

  const AppBottomBar({
    super.key,
    required this.index,
    required this.onTap,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            _ScanButton(onTap: onScan),
            const SizedBox(width: 14),
            Expanded(child: _NavPill(index: index, onTap: onTap)),
          ],
        ),
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ScanButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: AppColors.primary,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const SizedBox(
            width: 62,
            height: 62,
            child: Icon(Icons.document_scanner_outlined,
                color: Colors.white, size: 26),
          ),
        ),
      ),
    );
  }
}

class _NavPill extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _NavPill({required this.index, required this.onTap});

  static const _items = [
    (Icons.home_outlined, 'Home'),
    (Icons.auto_awesome_outlined, 'AI'),
    (Icons.person_outline_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(31),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < _items.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: i == index
                        ? AppColors.accentLight
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _items[i].$1,
                        size: 22,
                        color:
                        i == index ? AppColors.primary : AppColors.label,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _items[i].$2,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight:
                          i == index ? FontWeight.w700 : FontWeight.w500,
                          color:
                          i == index ? AppColors.primary : AppColors.label,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
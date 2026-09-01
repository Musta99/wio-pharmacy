import 'package:flutter/material.dart';

const Color _kNavy = Color(0xFF0E1B33);
const Color _kCoral = Color(0xFFFF5A45);
const Color _kMuted = Color(0xFF9AA1B0);

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

const _kNavItems = [
  _NavItem(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
  _NavItem(Icons.inventory_2_outlined, Icons.science, 'Inventory'),
  _NavItem(Icons.local_shipping_outlined, Icons.local_shipping, 'Suppliers'),
  _NavItem(Icons.shopping_cart_outlined, Icons.shopping_cart, 'Sales'),
  _NavItem(Icons.person_outline, Icons.person, 'Profile'),
];

/// A floating bottom bar — icon stacked above label for every item, with
/// the selected item highlighted in coral (both icon and label) against a
/// soft pill background.
class MainBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const MainBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: _kNavy.withOpacity(0.14),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_kNavItems.length, (index) {
              final item = _kNavItems[index];
              final isActive = index == currentIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 3,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isActive
                              ? _kCoral.withOpacity(0.12)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isActive ? item.activeIcon : item.icon,
                          size: 22,
                          color: isActive ? _kCoral : _kMuted,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isActive ? _kCoral : _kMuted,
                            fontSize: 10.5,
                            fontWeight:
                                isActive ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

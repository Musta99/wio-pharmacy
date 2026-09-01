import 'package:flutter/material.dart';
import 'package:wio_pharmacy/view/screens/alert/alert_screen.dart';
import 'package:wio_pharmacy/view/screens/analytics/analytics_screen.dart';
import 'package:wio_pharmacy/view/screens/settings/settings_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, this.pharmacyName, this.pharmacyLogoUrl});

  final String? pharmacyName;
  final String? pharmacyLogoUrl;

  static const navy = Color(0xFF0E1B33);
  static const coral = Color(0xFFFF5A45);
  static const mint = Color(0xFF17A673);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF7F9FC),
      width: MediaQuery.of(context).size.width * 0.78,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(context),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(
                'INTELLIGENCE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.black38,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            _drawerTile(
              context,
              icon: Icons.shield_outlined,
              label: 'Alerts',
              subtitle: 'Stock, expiry & reorder signals',
              color: coral,
              onTap: () => _navigate(context, const AlertScreen()),
            ),
            _drawerTile(
              context,
              icon: Icons.bar_chart_rounded,
              label: 'Analytics',
              subtitle: 'Wallet, sales & settlements',
              color: mint,
              onTap: () => _navigate(context, const AnalyticsScreen()),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Divider(height: 1),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Text(
                'MANAGEMENT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.black38,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            _drawerTile(
              context,
              icon: Icons.tune_rounded,
              label: 'Settings',
              subtitle: 'Staff, invoicing & protocols',
              color: navy,
              onTap: () => _navigate(context, const SettingsScreen()),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Icon(
                    Icons.local_pharmacy_outlined,
                    size: 14,
                    color: Colors.black26,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'WioCare Pharmacy Suite',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.black26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [navy, navy.withOpacity(0.85), mint.withOpacity(0.55)],
        ),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1.2,
              ),
            ),
            child:
                pharmacyLogoUrl != null && pharmacyLogoUrl!.isNotEmpty
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        pharmacyLogoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => const Icon(
                              Icons.local_pharmacy_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                      ),
                    )
                    : const Icon(
                      Icons.local_pharmacy_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
          ),
          const SizedBox(height: 16),
          Text(
            pharmacyName?.isNotEmpty == true
                ? pharmacyName!
                : 'WioCare Pharmacy',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Partner Portal',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0E1B33),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Colors.black26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, Widget screen) {
    Navigator.pop(context); // close drawer first
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wio_pharmacy/main_bottom_nav_bar.dart';
import 'package:wio_pharmacy/view/screens/dashboard/dashboard_screen.dart';
import 'package:wio_pharmacy/view/screens/inventory/inventory_screen.dart';
import 'package:wio_pharmacy/view/screens/profile/profile_screen.dart';
import 'package:wio_pharmacy/view/screens/sales/sales_screen.dart';
import 'package:wio_pharmacy/view/screens/suppliers/suppliers_screen.dart';
import 'package:wio_pharmacy/view/widgets/double_back_to_exit.dart';
import 'package:wio_pharmacy/viewmodel/navigation_view_model.dart';

class MainContainerScreen extends StatelessWidget {
  const MainContainerScreen({super.key});
  static const List<Widget> _screens = [
    DashboardScreen(),
    InventoryScreen(),
    SuppliersScreen(),
    SalesScreen(),
    ProfileScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationViewModel>(
      builder: (context, navVM, _) {
        return DoubleBackToExit(
          child: Scaffold(
            body: IndexedStack(index: navVM.selectedIndex, children: _screens),
            bottomNavigationBar: MainBottomNavBar(
              currentIndex: navVM.selectedIndex,
              onTap: (index) {
                navVM.navigateTo(index);
              },
            ),
          ),
        );
      },
    );
  }
}

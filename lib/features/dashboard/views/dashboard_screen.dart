import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:quick_plate/features/dashboard/dashboard_tab_controller.dart';
import '../../scan/views/scan_screen.dart';
import '../../menu/views/menu_screen.dart';
import '../../cart/views/cart_screen.dart';
import '../../profile/views/profile_screen.dart';
import '../../../core/app_exports.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardTabController _tabController = DashboardTabController();

  static const _labels = ['Menu', 'Scan', 'Cart', 'Profile'];
  static const _icons = [
    Icons.restaurant_menu_rounded,
    Icons.qr_code_scanner_rounded,
    Icons.shopping_bag_outlined,
    Icons.person_outline_rounded,
  ];
  static const _iconsActive = [
    Icons.restaurant_menu_rounded,
    Icons.qr_code_scanner_rounded,
    Icons.shopping_bag_rounded,
    Icons.person_rounded,
  ];

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      MenuScreen(onCartTap: () => _tabController.switchTo(2)),
      const ScanScreen(),
      const CartScreen(),
      const ProfileScreen(),
    ];
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _tabController.index;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(index: selectedIndex, children: _screens),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_labels.length, (index) {
                  final selected = selectedIndex == index;
                  return _NavItem(
                    label: _labels[index],
                    icon: selected ? _iconsActive[index] : _icons[index],
                    selected: selected,
                    onTap: () => _tabController.switchTo(index),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textTertiary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryTint : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

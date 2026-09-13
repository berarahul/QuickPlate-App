import 'package:flutter/services.dart';
import 'package:quick_plate/features/dashboard/dashboard_tab_controller.dart';
import '../../scan/provider/scan_provider.dart';
import '../../table_reservation/views/live_table_view_screen.dart';
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

  static const _labels = ['Menu', 'Live View', 'Scan', 'Cart', 'Profile'];
  static const _icons = [
    Icons.restaurant_menu_rounded,
    Icons.table_restaurant_outlined,
    Icons.qr_code_scanner_rounded,
    Icons.shopping_bag_outlined,
    Icons.person_outline_rounded,
  ];
  static const _iconsActive = [
    Icons.restaurant_menu_rounded,
    Icons.table_restaurant_rounded,
    Icons.qr_code_scanner_rounded,
    Icons.shopping_bag_rounded,
    Icons.person_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!mounted) return;
    setState(() {});
    // Whenever the user switches to the Menu tab (0), refresh the active
    // session so the 5-min timer card / green card renders correctly.
    if (_tabController.index == 0) {
      context.read<ScanProvider>().refreshSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final selectedIndex = _tabController.index;

    final screens = [
      MenuScreen(
        onCartTap: () => _tabController.switchTo(3),
        onScanTap: () => _tabController.switchTo(2),
      ),
      const LiveTableViewScreen(),
      ScanScreen(
        isActive: selectedIndex == 2,
        onSessionStarted: () => _tabController.switchTo(1),
      ),
      const CartScreen(),
      const ProfileScreen(),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: AppColors.isDarkMode
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: AppColors.isDarkMode
            ? Brightness.dark
            : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        extendBody: true,
        body: IndexedStack(index: selectedIndex, children: screens),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: AppColors.isDarkMode ? 0.92 : 0.96),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.6),
                  width: 1,
                ),
                boxShadow: AppColors.cardShadow,
              ),
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
      borderRadius: BorderRadius.circular(16),
      splashColor: AppColors.primaryTint,
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 14 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryTint : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            if (selected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import '../provider/menu_provider.dart';
import '../model/menu_response.dart';
import '../../cart/provider/cart_provider.dart';
import '../../scan/provider/scan_provider.dart';
import '../../../core/app_exports.dart';
import '../../../core/widgets/canteen_flow_guide_card.dart';
import 'widgets/food_item_card.dart';

class MenuScreen extends StatefulWidget {
  final VoidCallback? onCartTap;
  final VoidCallback? onScanTap;

  const MenuScreen({super.key, this.onCartTap, this.onScanTap});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch menu data + refresh active session so the 5-min timer card shows
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MenuProvider>(context, listen: false).fetchMenu();
      Provider.of<CartProvider>(context, listen: false).fetchCart();
      // Refresh session state so CanteenFlowGuideCard shows the correct timer/status
      Provider.of<ScanProvider>(context, listen: false).refreshSession();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (!mounted) return;
            final menuProv = Provider.of<MenuProvider>(context, listen: false);
            final cartProv = Provider.of<CartProvider>(context, listen: false);
            final scanProv = Provider.of<ScanProvider>(context, listen: false);
            await Future.wait([
              menuProv.fetchMenu(),
              cartProv.fetchCart(),
              scanProv.refreshSession(),
            ]);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Browse', style: AppTextStyles.labelSmall),
                          const SizedBox(height: 4),
                          Text(
                            'Today\'s Menu',
                            style: AppTextStyles.displayLarge,
                          ),
                        ],
                      ),
                      const Spacer(),
                      AppBounceable(
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.tableReservationScreen);
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryTint,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.table_restaurant_rounded,
                            size: 22,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      Consumer<CartProvider>(
                        builder: (context, cart, child) {
                          return GestureDetector(
                            onTap: widget.onCartTap,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 1,
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    Icons.shopping_bag_outlined,
                                    size: 22,
                                    color: AppColors.textPrimary,
                                  ),
                                  if (cart.itemCount > 0)
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 16,
                                          minHeight: 16,
                                        ),
                                        child: Text(
                                          cart.itemCount.toString(),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: AppColors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: CanteenFlowGuideCard(onScanTap: widget.onScanTap),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: AppColors.textPrimary),
                    onChanged: (value) {
                      if (_debounce?.isActive ?? false) _debounce?.cancel();
                      _debounce = Timer(const Duration(milliseconds: 500), () {
                        if (mounted) {
                          Provider.of<MenuProvider>(
                            context,
                            listen: false,
                          ).fetchMenu(search: value);
                        }
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search dishes...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      filled: true,
                      fillColor: AppColors.surface,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.border, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.border, width: 1),
                      ),
                    ),
                  ),
                ),
              ),
              Consumer<MenuProvider>(
                builder: (context, menuProvider, child) {
                  if (menuProvider.isLoading) {
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (menuProvider.errorMessage != null) {
                    return SliverFillRemaining(
                      child: StateView(
                        icon: Icons.error_outline_rounded,
                        iconColor: AppColors.error,
                        iconBg: AppColors.errorTint,
                        title: 'Couldn\'t load menu',
                        message: menuProvider.errorMessage,
                        actionLabel: 'Retry',
                        onAction: () => menuProvider.retryFetchMenu(),
                      ),
                    );
                  }

                  if (menuProvider.menuItems.isEmpty) {
                    return const SliverFillRemaining(
                      child: StateView(
                        icon: Icons.restaurant_menu_rounded,
                        title: 'No items available',
                        message: 'The canteen hasn\'t listed any dishes yet.',
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    sliver: SliverList.separated(
                      itemCount: menuProvider.menuItems.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final MenuItem item = menuProvider.menuItems[index];
                        return AppFadeInSlide(
                          delay: Duration(milliseconds: index * 40),
                          child: FoodItemCard(item: item),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:provider/provider.dart';
import '../provider/menu_provider.dart';
import '../model/menu_response.dart';
import '../../cart/provider/cart_provider.dart';
import '../../../core/app_exports.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch menu data when screen is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MenuProvider>(context, listen: false).fetchMenu();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
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
                        Text('Today\'s Menu', style: AppTextStyles.displayLarge),
                      ],
                    ),
                    const Spacer(),
                    Consumer<CartProvider>(
                      builder: (context, cart, child) {
                        return GestureDetector(
                          onTap: () {},
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: AppColors.border, width: 1),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(Icons.shopping_bag_outlined,
                                    size: 22, color: AppColors.textPrimary),
                                if (cart.itemCount > 0)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search dishes...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    filled: true,
                    fillColor: AppColors.surface,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: AppColors.border, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: AppColors.border, width: 1),
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
                      return _MenuItemCard(item: item);
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final MenuItem item;
  const _MenuItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final unavailable = item.isAvailable == false;
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 88,
              height: 88,
              color: AppColors.surfaceAlt,
              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.textTertiary),
                    )
                  : const Icon(Icons.lunch_dining_outlined,
                      size: 32, color: AppColors.textTertiary),
            ),
          ),
          const SizedBox(width: 14),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name ?? 'Unknown Item',
                        style: AppTextStyles.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (unavailable)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.errorTint,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Unavailable',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.description ?? '',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '₹${item.price ?? 0}',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                      ),
                    ),
                    if (!unavailable)
                      Consumer<CartProvider>(
                        builder: (context, cart, child) {
                          final cartItem = cart.items[item.id];
                          if (cartItem != null) {
                            return Container(
                              decoration: BoxDecoration(
                                color: AppColors.primaryTint,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: () => cart.removeSingleItem(item.id!),
                                    icon: const Icon(Icons.remove_rounded,
                                        size: 18, color: AppColors.primary),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                        minWidth: 32, minHeight: 32),
                                  ),
                                  Text(
                                    cartItem.quantity.toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => cart.addItem(item),
                                    icon: const Icon(Icons.add_rounded,
                                        size: 18, color: AppColors.primary),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                        minWidth: 32, minHeight: 32),
                                  ),
                                ],
                              ),
                            );
                          }
                          return SizedBox(
                            height: 34,
                            child: ElevatedButton(
                              onPressed: () => cart.addItem(item),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16),
                                minimumSize: Size.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Add',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

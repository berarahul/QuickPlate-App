import '../../model/menu_response.dart';
import '../../../cart/provider/cart_provider.dart';
import '../../../../core/app_exports.dart';

class FoodDetailSheet {
  static void show(BuildContext context, MenuItem item) {
    final unavailable = item.isAvailable == false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          expand: false,
          builder: (sheetContext, scrollController) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Scaffold(
                backgroundColor: AppColors.surface,
                body: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: EdgeInsets.zero,
                        children: [
                          // Image Header
                          Stack(
                            children: [
                              Container(
                                height: 220,
                                width: double.infinity,
                                color: AppColors.surfaceAlt,
                                child: item.imageUrl != null &&
                                        item.imageUrl!.isNotEmpty
                                    ? Image.network(
                                        item.imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Container(
                                          color: AppColors.surfaceAlt,
                                          child: Icon(
                                            Icons.restaurant_rounded,
                                            size: 56,
                                            color: AppColors.textTertiary,
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        Icons.restaurant_rounded,
                                        size: 56,
                                        color: AppColors.textTertiary,
                                      ),
                              ),
                              // Top Drag Indicator Overlay
                              Positioned(
                                top: 10,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    width: 40,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                              // Close Button
                              Positioned(
                                top: 16,
                                right: 16,
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(ctx),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                              // Category Tag on Image
                              if (item.category != null &&
                                  item.category!.isNotEmpty)
                                Positioned(
                                  bottom: 16,
                                  left: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      item.category!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          // Content Body
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title & Availability
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.name ?? 'Dish Details',
                                        style: AppTextStyles.titleLarge.copyWith(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    if (unavailable)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.errorTint,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Currently Unavailable',
                                          style: TextStyle(
                                            color: AppColors.error,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Price and Prep Time row
                                Row(
                                  children: [
                                    Text(
                                      '₹${item.price ?? 0}',
                                      style: AppTextStyles.displayLarge.copyWith(
                                        color: AppColors.primary,
                                        fontSize: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    if (item.preparationTimeInMinutes != null &&
                                        item.preparationTimeInMinutes! > 0) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceAlt,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.timer_outlined,
                                              size: 15,
                                              color: AppColors.textSecondary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${item.preparationTimeInMinutes} mins prep',
                                              style: AppTextStyles.bodySmall
                                                  .copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 20),
                                const Divider(),
                                const SizedBox(height: 16),

                                // Description Header & Body
                                Text(
                                  'About this dish',
                                  style: AppTextStyles.titleSmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  (item.description != null &&
                                          item.description!.trim().isNotEmpty)
                                      ? item.description!
                                      : 'Freshly prepared and made to order in our campus kitchen.',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.55,
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bottom Action Bar
                    if (!unavailable)
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border(
                            top: BorderSide(color: AppColors.border, width: 1),
                          ),
                        ),
                        child: Consumer<CartProvider>(
                          builder: (context, cart, child) {
                            final cartItem = cart.items[item.id];
                            final count = cartItem?.quantity ?? 0;

                            if (count > 0) {
                              return Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceAlt,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          onPressed: () =>
                                              cart.removeSingleItem(item.id!),
                                          icon: Icon(
                                            Icons.remove_rounded,
                                            size: 20,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        Text(
                                          '$count',
                                          style: AppTextStyles.titleSmall
                                              .copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => cart.addItem(item),
                                          icon: Icon(
                                            Icons.add_rounded,
                                            size: 20,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: CustomElevatedButton(
                                      text:
                                          'In Cart • ₹${((item.price ?? 0) * count)}',
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }

                            return CustomElevatedButton(
                              text: 'Add to Cart • ₹${item.price ?? 0}',
                              leading: const Icon(
                                Icons.shopping_bag_outlined,
                                size: 20,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                cart.addItem(item);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle_rounded,
                                          size: 20,
                                          color: AppColors.success,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            '${item.name} added to cart!',
                                            style: TextStyle(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: AppColors.surfaceAlt,
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: AppColors.border,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

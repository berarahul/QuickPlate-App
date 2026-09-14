import '../../model/menu_response.dart';
import '../../../cart/provider/cart_provider.dart';
import '../../../../core/app_exports.dart';
import 'food_detail_sheet.dart';

class FoodItemCard extends StatelessWidget {
  final MenuItem item;

  const FoodItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final unavailable = item.isAvailable == false;
    return GestureDetector(
      onTap: () => FoodDetailSheet.show(context, item),
      child: AppCard(
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
                        errorBuilder: (_, _, _) => Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.textTertiary,
                        ),
                      )
                    : Icon(
                        Icons.lunch_dining_outlined,
                        size: 32,
                        color: AppColors.textTertiary,
                      ),
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
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.errorTint,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
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
                                      onPressed: () =>
                                          cart.removeSingleItem(item.id!),
                                      icon: Icon(
                                        Icons.remove_rounded,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                    ),
                                    Text(
                                      cartItem.quantity.toString(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => cart.addItem(item),
                                      icon: Icon(
                                        Icons.add_rounded,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
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
                                    horizontal: 16,
                                  ),
                                  minimumSize: Size.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Add',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
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
      ),
    );
  }
}

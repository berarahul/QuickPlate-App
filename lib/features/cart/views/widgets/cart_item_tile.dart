import '../../../../core/app_exports.dart';
import '../../provider/cart_provider.dart';

class CartItemTile extends StatelessWidget {
  final CartItem item;

  const CartItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 60,
                height: 60,
                color: AppColors.surfaceAlt,
                child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                    ? Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: AppColors.surfaceAlt,
                          child: Icon(
                            Icons.restaurant_rounded,
                            color: AppColors.textTertiary,
                            size: 24,
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.surfaceAlt,
                        child: Icon(
                          Icons.restaurant_rounded,
                          color: AppColors.textTertiary,
                          size: 24,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${item.price.toStringAsFixed(1)} each',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_rounded, size: 18),
                    color: AppColors.textSecondary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () => cart.removeSingleItem(item.foodId),
                  ),
                  Text(
                    '${item.quantity}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_rounded, size: 18),
                    color: AppColors.primary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () => cart.incrementItem(item.foodId),
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

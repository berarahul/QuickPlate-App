import '../../../../core/app_exports.dart';
import '../../models/table_availability_model.dart';

class ReservationCostBreakdownCard extends StatelessWidget {
  final CostBreakdown breakdown;
  final int count;

  const ReservationCostBreakdownCard({
    super.key,
    required this.breakdown,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final seatCount = count > 0 ? count : 1;
    final totalDeposit =
        breakdown.ratePerChair * seatCount * breakdown.durationMultiplier;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text('Deposit Breakdown', style: AppTextStyles.titleSmall),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Rate per Chair', style: AppTextStyles.bodySmall),
              Text(
                '₹${breakdown.ratePerChair.toStringAsFixed(0)}',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Selected Chairs', style: AppTextStyles.bodySmall),
              Text('$count seats', style: AppTextStyles.bodySmall),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Duration Multiplier', style: AppTextStyles.bodySmall),
              Text(
                '${breakdown.durationMultiplier}x',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Deposit Payable', style: AppTextStyles.titleSmall),
              Text(
                '₹${totalDeposit.toStringAsFixed(0)}',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryTint.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Deposit is 100% credited to your cart order when you order food at your table!',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

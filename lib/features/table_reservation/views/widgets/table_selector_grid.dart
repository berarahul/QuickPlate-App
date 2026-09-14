import '../../../../core/app_exports.dart';
import '../../models/table_availability_model.dart';
import '../../provider/table_reservation_provider.dart';

class TableSelectorGrid extends StatelessWidget {
  final TableAvailabilityResponse availabilityResponse;
  final TableReservationProvider provider;

  const TableSelectorGrid({
    super.key,
    required this.availabilityResponse,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Select Table', style: AppTextStyles.titleMedium),
            Text(
              '${availabilityResponse.tables.length} Tables Total',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Table Selector GridView
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.7,
          ),
          itemCount: availabilityResponse.tables.length,
          itemBuilder: (context, index) {
            final table = availabilityResponse.tables[index];
            final isSelected = table.tableId == provider.selectedTableId;
            final freeSeats = table.availableSeats.length;
            final isFull = freeSeats == 0;

            return AppBounceable(
              onTap: () => provider.selectTable(table.tableId),
              scaleFactor: 0.95,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryTint
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.border.withValues(alpha: 0.8),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.table_restaurant_rounded,
                          size: 16,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Table ${table.tableId}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : isFull
                            ? AppColors.errorTint
                            : AppColors.successTint,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$freeSeats/${table.maxCapacity} free',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.primary
                              : isFull
                              ? AppColors.error
                              : AppColors.success,
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
    );
  }
}

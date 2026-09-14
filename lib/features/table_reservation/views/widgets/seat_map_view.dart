import '../../../../core/app_exports.dart';
import '../../models/table_availability_model.dart';
import '../../provider/table_reservation_provider.dart';

class SeatMapView extends StatelessWidget {
  final AvailableTable selectedTable;
  final TableReservationProvider provider;
  final Set<int> mySeatNumbersOnThisTable;

  const SeatMapView({
    super.key,
    required this.selectedTable,
    required this.provider,
    required this.mySeatNumbersOnThisTable,
  });

  Widget _buildLegend(Color color, String label, [IconData? icon]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ] else ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Seat Map Header & Legend
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Interactive Seat Map', style: AppTextStyles.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildLegend(AppColors.primary, 'Selected', Icons.check_circle_rounded),
                _buildLegend(AppColors.success, 'Available', Icons.event_seat_rounded),
                _buildLegend(Colors.indigo.shade400, 'Your Seat', Icons.bookmark_rounded),
                _buildLegend(Colors.grey.shade500, 'Occupied', Icons.lock_rounded),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Interactive Seat Layout Visual
        Center(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Sleek Table Top Illustration
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.table_bar_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TABLE ${selectedTable.tableId}',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 1.1,
                            ),
                          ),
                          Text(
                            'Cap: ${selectedTable.maxCapacity} Guests',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Seats Grid
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  alignment: WrapAlignment.center,
                  children: List.generate(selectedTable.maxCapacity, (idx) {
                    final seatNum = idx + 1;
                    final isMySeat = mySeatNumbersOnThisTable.contains(seatNum);
                    final isReserved = selectedTable.reservedSeatNumbers
                        .contains(seatNum);
                    final isSessionRunning = selectedTable
                        .sessionRunningSeatNumbers
                        .contains(seatNum);
                    final isSelected = provider.selectedSeats.contains(
                      seatNum,
                    );
                    final isOccupiedByOther = (isReserved || isSessionRunning) && !isMySeat;

                    final cardColor = isSelected
                        ? AppColors.primary
                        : isMySeat
                        ? Colors.indigo.shade900.withValues(alpha: 0.7)
                        : isOccupiedByOther
                        ? AppColors.surfaceAlt
                        : AppColors.surfaceAlt;

                    final borderColor = isSelected
                        ? AppColors.primary
                        : isMySeat
                        ? Colors.indigo.shade400
                        : isOccupiedByOther
                        ? AppColors.border
                        : AppColors.success.withValues(alpha: 0.6);

                    final iconData = isSelected
                        ? Icons.check_circle_rounded
                        : isMySeat
                        ? Icons.bookmark_rounded
                        : isOccupiedByOther
                        ? Icons.lock_rounded
                        : Icons.event_seat_rounded;

                    final iconColor = isSelected
                        ? Colors.black
                        : isMySeat
                        ? Colors.indigo.shade300
                        : isOccupiedByOther
                        ? AppColors.textSecondary
                        : AppColors.success;

                    final textColor = isSelected
                        ? Colors.black
                        : isMySeat
                        ? Colors.indigo.shade200
                        : isOccupiedByOther
                        ? AppColors.textSecondary
                        : AppColors.textPrimary;

                    return AppBounceable(
                      onTap: (isOccupiedByOther || isMySeat)
                          ? null
                          : () => provider.toggleSeatSelection(seatNum),
                      scaleFactor: 0.92,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: borderColor,
                            width: isSelected ? 2 : 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : isMySeat
                              ? [
                                  BoxShadow(
                                    color: Colors.indigo.withValues(alpha: 0.3),
                                    blurRadius: 6,
                                  ),
                                ]
                              : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(iconData, size: 20, color: iconColor),
                            const SizedBox(height: 3),
                            Text(
                              isMySeat ? 'Mine' : 'S-$seatNum',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

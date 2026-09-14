import '../../../../core/app_exports.dart';
import '../../provider/table_reservation_provider.dart';

class ReservationTimeFilterBar extends StatelessWidget {
  final TableReservationProvider provider;
  final VoidCallback onSelectStartTime;
  final VoidCallback onSelectEndTime;

  const ReservationTimeFilterBar({
    super.key,
    required this.provider,
    required this.onSelectStartTime,
    required this.onSelectEndTime,
  });

  String _format12Hour(String time24) {
    try {
      final parts = time24.split(':').map(int.parse).toList();
      final hour = parts[0];
      final min = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      final h12 = hour % 12 == 0 ? 12 : hour % 12;
      final minStr = min.toString().padLeft(2, '0');
      return '${h12.toString().padLeft(2, '0')}:$minStr $period';
    } catch (_) {
      return time24;
    }
  }

  @override
  Widget build(BuildContext context) {
    final durationHours = (provider.selectedDuration / 60.0)
        .toStringAsFixed(1)
        .replaceAll('.0', '');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text('Custom Time Range', style: AppTextStyles.titleSmall),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.store_rounded,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Hours: ${provider.availabilityResponse?.openingTime ?? "09:00"} - ${provider.availabilityResponse?.closingTime ?? "17:00"}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Custom Range Selector Cards
          Row(
            children: [
              // From Start Time Button
              Expanded(
                child: InkWell(
                  onTap: onSelectStartTime,
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryTint,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.access_time_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'FROM',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _format12Hour(provider.selectedStartTime),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

              // To End Time Button
              Expanded(
                child: InkWell(
                  onTap: onSelectEndTime,
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryTint,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.access_time_filled_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TO',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _format12Hour(provider.selectedEndTime),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Duration Badge Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryTint.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timelapse_rounded,
                  size: 15,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Booked Slot: $durationHours Hr(s)  •  ${_format12Hour(provider.selectedStartTime)} to ${_format12Hour(provider.selectedEndTime)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
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

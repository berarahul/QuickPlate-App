import '../../../../core/app_exports.dart';
import '../../models/table_reservation_model.dart';
import '../my_reservations_screen.dart';

class ReservationSuccessDialog extends StatelessWidget {
  final TableReservation reservation;

  const ReservationSuccessDialog({
    super.key,
    required this.reservation,
  });

  static void show(BuildContext context, TableReservation reservation) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ReservationSuccessDialog(reservation: reservation),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        children: [
          AppPopScale(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.successTint,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 48,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Table Reserved!',
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Table ${reservation.tableId} • Seats ${reservation.seatNumbers.join(", ")}',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Date: ${DateTimeFormatter.formatDate(reservation.reservationDate)} (${DateTimeFormatter.formatTimeRange(reservation.startTime, reservation.endTime)})',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.stars_rounded, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '₹${reservation.depositPaidAmount.toStringAsFixed(0)} deposit paid! This will automatically discount your food order.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyReservationsScreen()),
            );
          },
          child: const Text(
            'View My Reservations',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

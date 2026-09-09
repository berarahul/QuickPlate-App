import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/app_exports.dart';
import '../provider/table_reservation_provider.dart';
import '../models/table_reservation_model.dart';
import 'live_reservation_countdown.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TableReservationProvider>().fetchMyReservations();
    });
  }

  void _showQrDialog(BuildContext context, TableReservation reservation) {
    final qrData = reservation.qrCodeData ?? reservation.id;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Center(
          child: Text(
            'Table ${reservation.tableId} Check-In QR',
            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppPopScale(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Show this QR code at the canteen table scanner to check-in!',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleCancelReservation(BuildContext context, TableReservation reservation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Reservation?'),
        content: Text('Are you sure you want to cancel your reservation for Table ${reservation.tableId}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final provider = context.read<TableReservationProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final success = await provider.cancelReservation(reservation.id);

    if (context.mounted) {
      if (success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Reservation for Table ${reservation.tableId} cancelled successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to cancel reservation.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TableReservationProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('My Table Reservations', style: AppTextStyles.titleLarge),
      ),
      body: SafeArea(
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.myReservations.isEmpty
                ? const StateView(
                    icon: Icons.bookmark_border_rounded,
                    title: 'No Reservations Found',
                    message: 'You have not reserved any tables yet.',
                  )
                : RefreshIndicator(
                    onRefresh: () => provider.fetchMyReservations(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.myReservations.length,
                      itemBuilder: (context, index) {
                        final res = provider.myReservations[index];
                        final isBooked = res.reservationStatus == 'booked';
                        final isCheckedIn = res.reservationStatus == 'checked_in';

                        return AppFadeInSlide(
                          delay: Duration(milliseconds: index * 50),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isBooked
                                    ? AppColors.primary
                                    : isCheckedIn
                                        ? AppColors.success
                                        : AppColors.border,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryTint,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(Icons.table_restaurant_rounded, color: AppColors.primary, size: 20),
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Table ${res.tableId}',
                                              style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              'Seats: ${res.seatNumbers.join(", ")}',
                                              style: AppTextStyles.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isCheckedIn
                                            ? AppColors.successTint
                                            : isBooked
                                                ? AppColors.primaryTint
                                                : Colors.grey.shade800,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        res.reservationStatus.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isCheckedIn
                                              ? AppColors.success
                                              : isBooked
                                                  ? AppColors.primary
                                                  : Colors.grey.shade400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textSecondary),
                                        const SizedBox(width: 6),
                                        Text(DateTimeFormatter.formatDate(res.reservationDate), style: AppTextStyles.bodySmall),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
                                        const SizedBox(width: 6),
                                        Text(DateTimeFormatter.formatTimeRange(res.startTime, res.endTime), style: AppTextStyles.bodySmall),
                                      ],
                                    ),
                                  ],
                                ),
                                if (isBooked || isCheckedIn) ...[
                                  const SizedBox(height: 10),
                                  LiveReservationCountdown(
                                    startTime: res.startTime,
                                    endTime: res.endTime,
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Deposit Paid: ₹${res.depositPaidAmount.toStringAsFixed(0)}',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (isBooked || isCheckedIn)
                                      Row(
                                        children: [
                                          OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: AppColors.error,
                                              side: BorderSide(color: AppColors.error),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            ),
                                            icon: const Icon(Icons.cancel_outlined, size: 15),
                                            label: const Text('Cancel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                            onPressed: () => _handleCancelReservation(context, res),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primary,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            ),
                                            icon: const Icon(Icons.qr_code_rounded, size: 16, color: Colors.black),
                                            label: const Text('Show QR', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                                            onPressed: () => _showQrDialog(context, res),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}


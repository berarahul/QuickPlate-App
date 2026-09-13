import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/app_exports.dart';
import '../provider/table_reservation_provider.dart';
import '../models/table_reservation_model.dart';
import 'live_reservation_countdown.dart';
import '../../scan/provider/scan_provider.dart';

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

  DateTime _parseDateTime(dynamic input) {
    if (input is DateTime) return input;
    if (input is String) {
      final parsed = DateTime.tryParse(input);
      if (parsed != null) return parsed;

      final parts = input.split(':');
      if (parts.length >= 2) {
        final now = DateTime.now();
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        return DateTime(now.year, now.month, now.day, hour, minute);
      }
    }
    return DateTime.now();
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

  int _selectedTabIndex = 0; // 0 = Active, 1 = History

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TableReservationProvider>();

    final activeReservations = provider.myReservations.where((r) => r.isActiveSlot).toList();
    final pastReservations = provider.myReservations.where((r) => !r.isActiveSlot).toList();

    final displayedList = _selectedTabIndex == 0 ? activeReservations : pastReservations;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('My Table Reservations', style: AppTextStyles.titleLarge),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Segmented Tab Filter (Active vs History)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTabIndex = 0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 0 ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bookmark_rounded,
                              size: 16,
                              color: _selectedTabIndex == 0 ? Colors.white : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Active (${activeReservations.length})',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _selectedTabIndex == 0 ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTabIndex = 1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 1 ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history_rounded,
                              size: 16,
                              color: _selectedTabIndex == 1 ? Colors.white : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'History (${pastReservations.length})',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _selectedTabIndex == 1 ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : displayedList.isEmpty
                      ? StateView(
                          icon: _selectedTabIndex == 0 ? Icons.bookmark_border_rounded : Icons.history_rounded,
                          title: _selectedTabIndex == 0 ? 'No Active Bookings' : 'No Booking History',
                          message: _selectedTabIndex == 0
                              ? 'You currently have no active or checked-in reservations.'
                              : 'Your past completed or cancelled reservations will appear here.',
                        )
                      : RefreshIndicator(
                          onRefresh: () => provider.fetchMyReservations(),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: displayedList.length,
                            itemBuilder: (context, index) {
                              final res = displayedList[index];
                              final isBooked = res.reservationStatus == 'booked' || res.reservationStatus == 'reserved';
                              final isCheckedIn = res.reservationStatus == 'checked_in';

                              return AppFadeInSlide(
                                delay: Duration(milliseconds: index * 50),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: AppColors.cardShadow,
                                    border: Border.all(
                                      color: isCheckedIn
                                          ? AppColors.success.withValues(alpha: 0.6)
                                          : isBooked
                                              ? AppColors.primary.withValues(alpha: 0.6)
                                              : AppColors.border,
                                      width: (isBooked || isCheckedIn) ? 1.5 : 1.0,
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
                                                  color: isCheckedIn ? AppColors.successTint : AppColors.primaryTint,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Icon(
                                                  Icons.table_restaurant_rounded,
                                                  color: isCheckedIn ? AppColors.success : AppColors.primary,
                                                  size: 20,
                                                ),
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
                                           onTimerTick: () {
                                             if (mounted) setState(() {});
                                           },
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
                                           if (isCheckedIn) ...[
                                             Row(
                                               children: [
                                                 IconButton(
                                                   icon: const Icon(Icons.qr_code_rounded, size: 18),
                                                   tooltip: 'Show QR Code',
                                                   onPressed: () => _showQrDialog(context, res),
                                                 ),
                                                 const SizedBox(width: 4),
                                                 ElevatedButton.icon(
                                                   style: ElevatedButton.styleFrom(
                                                     backgroundColor: AppColors.success,
                                                     foregroundColor: Colors.white,
                                                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                   ),
                                                   icon: const Icon(Icons.restaurant_menu_rounded, size: 14),
                                                   label: const Text('Order Food', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                   onPressed: () {
                                                     Navigator.popUntil(context, (route) => route.isFirst);
                                                   },
                                                 ),
                                                 const SizedBox(width: 4),
                                                 OutlinedButton.icon(
                                                   style: OutlinedButton.styleFrom(
                                                     foregroundColor: AppColors.error,
                                                     side: BorderSide(color: AppColors.error),
                                                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                   ),
                                                   icon: const Icon(Icons.exit_to_app_rounded, size: 14),
                                                   label: const Text('End Session', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                   onPressed: () async {
                                                     final scanProvider = context.read<ScanProvider>();
                                                     final result = await scanProvider.leaveTableSession();
                                                     if (context.mounted) {
                                                       ScaffoldMessenger.of(context).showSnackBar(
                                                         SnackBar(
                                                           content: Text(result.message),
                                                           backgroundColor: result.success ? AppColors.success : AppColors.error,
                                                         ),
                                                       );
                                                       context.read<TableReservationProvider>().fetchMyReservations();
                                                       context.read<TableReservationProvider>().fetchLiveTablesOverview();
                                                     }
                                                   },
                                                 ),
                                               ],
                                             ),
                                           ] else if (isBooked) ...[
                                             Row(
                                               children: [
                                                 IconButton(
                                                   icon: const Icon(Icons.qr_code_rounded, size: 18),
                                                   tooltip: 'Show QR Code',
                                                   onPressed: () => _showQrDialog(context, res),
                                                 ),
                                                 const SizedBox(width: 4),
                                                 ElevatedButton.icon(
                                                   style: ElevatedButton.styleFrom(
                                                     backgroundColor: AppColors.primary,
                                                     foregroundColor: Colors.white,
                                                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                   ),
                                                   icon: const Icon(Icons.qr_code_scanner_rounded, size: 14),
                                                   label: const Text('Scan Table QR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                   onPressed: () {
                                                     final now = DateTime.now();
                                                     final start = _parseDateTime(res.startTime);

                                                     if (now.isBefore(start)) {
                                                       final startTimeFormatted = DateTimeFormatter.formatTime(res.startTime);
                                                       ScaffoldMessenger.of(context).showSnackBar(
                                                         SnackBar(
                                                           content: Text(
                                                             'Your reservation slot for Table ${res.tableId} starts at $startTimeFormatted. Please scan table QR during your slot to start session.',
                                                           ),
                                                           backgroundColor: AppColors.primary,
                                                           duration: const Duration(seconds: 4),
                                                         ),
                                                       );
                                                       return;
                                                     }

                                                     // Open QR Scanner screen
                                                     Navigator.pushNamed(context, AppRoutes.scanScreen);
                                                   },
                                                 ),
                                                 const SizedBox(width: 4),
                                                 OutlinedButton.icon(
                                                   style: OutlinedButton.styleFrom(
                                                     foregroundColor: AppColors.error,
                                                     side: BorderSide(color: AppColors.error),
                                                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                   ),
                                                   icon: const Icon(Icons.cancel_outlined, size: 14),
                                                   label: const Text('Cancel', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                   onPressed: () => _handleCancelReservation(context, res),
                                                 ),
                                               ],
                                             ),
                                           ],
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
          ],
        ),
      ),
    );
  }
}


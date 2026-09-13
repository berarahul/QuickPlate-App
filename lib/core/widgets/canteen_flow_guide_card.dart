import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/table_reservation/provider/table_reservation_provider.dart';
import '../../features/table_reservation/models/table_reservation_model.dart';
import '../../features/scan/provider/scan_provider.dart';
import '../../features/scan/model/table_session_response.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../routes/app_routes.dart';

class CanteenFlowGuideCard extends StatelessWidget {
  final VoidCallback? onScanTap;
  final VoidCallback? onReserveTap;

  const CanteenFlowGuideCard({super.key, this.onScanTap, this.onReserveTap});

  @override
  Widget build(BuildContext context) {
    return Consumer2<TableReservationProvider, ScanProvider>(
      builder: (context, resProvider, scanProvider, child) {
        final liveSession = scanProvider.sessionResponse?.data?.session;
        final isSessionActive =
            liveSession != null && liveSession.isActive == true;

        if (isSessionActive) {
          return _buildActiveWalkInSessionCard(
            context,
            scanProvider,
            liveSession,
          );
        }

        TableReservation? activeRes;
        for (final r in resProvider.myReservations) {
          final status = r.reservationStatus.toLowerCase();
          if (status == 'booked' ||
              status == 'reserved' ||
              status == 'checked_in') {
            activeRes = r;
            break;
          }
        }

        final status = activeRes?.reservationStatus.toLowerCase() ?? 'none';

        if (status == 'checked_in') {
          return _buildCheckedInCard(context, activeRes!, scanProvider);
        } else if (status == 'booked' || status == 'reserved') {
          return _buildReservedCard(context, activeRes!);
        } else {
          return _NoBookingFlowGuideCard(
            onScanTap: onScanTap,
            onReserveTap: onReserveTap,
          );
        }
      },
    );
  }

  Widget _buildActiveWalkInSessionCard(
    BuildContext context,
    ScanProvider scanProvider,
    TableSession session,
  ) {
    final hasOrder = session.hasOrder == true;
    final chairs = session.chairIds?.isNotEmpty == true
        ? session.chairIds!.join(', ')
        : 'Assigned Seat';

    DateTime expiresAt;
    try {
      expiresAt = DateTime.parse(session.expiresAt!).toLocal();
    } catch (_) {
      expiresAt = DateTime.now().add(const Duration(minutes: 5));
    }

    final cardBgColor = hasOrder ? Colors.green.shade50 : Colors.amber.shade50;
    final cardBorderColor =
        hasOrder ? Colors.green.shade600 : Colors.amber.shade700;
    final cardHeaderIcon =
        hasOrder ? Icons.verified_rounded : Icons.timer_outlined;
    final cardHeaderIconBg =
        hasOrder ? Colors.green.shade100 : Colors.amber.shade100;
    final cardHeaderIconColor =
        hasOrder ? Colors.green.shade800 : Colors.amber.shade900;
    final badgeBgColor =
        hasOrder ? Colors.green.shade200 : Colors.amber.shade200;
    final badgeTextColor =
        hasOrder ? Colors.green.shade900 : Colors.amber.shade900;
    final badgeText = hasOrder
        ? '🟢 WALK-IN SESSION • SESSION EXTENDED'
        : '⚡ WALK-IN SESSION • ORDER FOOD TIMER';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: (hasOrder ? Colors.green : Colors.amber).withValues(
              alpha: 0.1,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cardHeaderIconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  cardHeaderIcon,
                  color: cardHeaderIconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBgColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: badgeTextColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Table ${session.tableId} • $chairs',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: hasOrder
                            ? Colors.green.shade900
                            : Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildStepItem(1, 'Entered', 'Done', true, Colors.green),
              _buildStepConnector(true),
              _buildStepItem(2, 'QR Scanned', 'Done', true, Colors.green),
              _buildStepConnector(true),
              _buildStepItem(
                3,
                'Order Food',
                hasOrder ? 'Done' : 'Grace Timer',
                true,
                hasOrder ? Colors.green : Colors.amber.shade800,
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (!hasOrder) ...[
            _FiveMinTimerWidget(
              expiresAt: expiresAt,
              onExpired: () async {
                final res = await scanProvider.leaveTableSession();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Initial order grace period ended. ${res.message}',
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 10),
            Text(
              '⚠️ Order food before the timer expires or your session will automatically end & release all chairs!',
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.amber.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade400),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green.shade800,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Your session is extended!',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '🎉 Food order placed! Your session has been extended and chairs are locked for dining.',
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.green.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 14),

          if (hasOrder) ...[
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final res = await scanProvider.leaveTableSession();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(res.message),
                        backgroundColor: res.success
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: const Text(
                  'Finish Meal & Free Table',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showExtendSessionDialog(
                      context,
                      scanProvider,
                      session.extensionCount ?? 0,
                    ),
                    icon: const Icon(Icons.more_time_rounded, size: 15),
                    label: Text(
                      (session.extensionCount ?? 0) < 1
                          ? 'Extend (+15m Free)'
                          : 'Extend (+15m ₹30)',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green.shade800,
                      side: BorderSide(color: Colors.green.shade600),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    icon: const Icon(Icons.restaurant_menu_rounded, size: 15),
                    label: const Text(
                      'Order More Food',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green.shade800,
                      side: BorderSide(color: Colors.green.shade600),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    icon: const Icon(Icons.restaurant_menu_rounded, size: 16),
                    label: const Text('Order Food Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade900,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    final res = await scanProvider.leaveTableSession();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res.message),
                          backgroundColor: res.success
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.exit_to_app_rounded, size: 16),
                  label: const Text('End'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReservedCard(BuildContext context, TableReservation res) {
    final seatsStr = res.seatNumbers.isNotEmpty
        ? '(${res.seatNumbers.join(", ")})'
        : '';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade700, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.amber.shade900,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'STEP 2: SCAN TABLE QR CODE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Table ${res.tableId} Reserved $seatsStr',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              _buildStepItem(1, 'Reserved', 'Done', true, Colors.green),
              _buildStepConnector(true),
              _buildStepItem(
                2,
                'Scan QR',
                'REQUIRED NOW',
                true,
                Colors.amber.shade800,
              ),
              _buildStepConnector(false),
              _buildStepItem(
                3,
                'Order Food',
                'Grace Timer',
                false,
                Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            '📌 Arrive at Table ${res.tableId} & scan its QR code to check in. Order food before the grace timer expires to lock your seats!',
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.amber.shade900,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  onScanTap ??
                  () => Navigator.pushNamed(context, AppRoutes.scanScreen),
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
              label: Text('Scan Table ${res.tableId} QR Code Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade900,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckedInCard(
    BuildContext context,
    TableReservation res,
    ScanProvider scanProvider,
  ) {
    final liveSession = scanProvider.sessionResponse?.data?.session;
    final hasOrder = liveSession?.hasOrder == true;
    final seatsStr = res.seatNumbers.isNotEmpty
        ? '(${res.seatNumbers.join(", ")})'
        : '';

    DateTime checkedInExpiresAt;
    try {
      checkedInExpiresAt = DateTime.parse(liveSession!.expiresAt!).toLocal();
    } catch (_) {
      checkedInExpiresAt = DateTime.now().add(const Duration(minutes: 5));
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade600, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  hasOrder ? Icons.verified_rounded : Icons.check_circle_rounded,
                  color: Colors.green.shade800,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        hasOrder
                            ? '🟢 CHECKED-IN • SESSION EXTENDED'
                            : '🟢 CHECKED-IN • ORDER FOOD BEFORE TIMER EXPIRES',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Checked-In at Table ${res.tableId} $seatsStr',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              _buildStepItem(1, 'Reserved', 'Done', true, Colors.green),
              _buildStepConnector(true),
              _buildStepItem(2, 'Checked In', 'Done', true, Colors.green),
              _buildStepConnector(true),
              _buildStepItem(
                3,
                'Order Food',
                hasOrder ? 'Done' : 'Grace Timer',
                true,
                hasOrder ? Colors.green : Colors.amber.shade800,
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (!hasOrder) ...[
            _FiveMinTimerWidget(
              expiresAt: checkedInExpiresAt,
              onExpired: () async {
                final result = await scanProvider.leaveTableSession();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Initial order grace period ended. ${result.message}',
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 8),
            Text(
              '🎉 You are checked in! Browse the menu & order food before the grace timer expires or your session ends and seats are released.',
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.green.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade400),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green.shade800,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Your session is extended!',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '🎉 Food order placed! Your session has been extended and your reserved seats are locked.',
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.green.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 12),

          if (hasOrder) ...[
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await scanProvider.leaveTableSession();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result.message),
                        backgroundColor: result.success
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: const Text(
                  'Finish Meal & Free Table',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final liveSession =
                          scanProvider.sessionResponse?.data?.session;
                      _showExtendSessionDialog(
                        context,
                        scanProvider,
                        liveSession?.extensionCount ?? 0,
                      );
                    },
                    icon: const Icon(Icons.more_time_rounded, size: 15),
                    label: Text(
                      ((scanProvider.sessionResponse?.data?.session?.extensionCount ?? 0) < 1)
                          ? 'Extend (+15m Free)'
                          : 'Extend (+15m ₹30)',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green.shade800,
                      side: BorderSide(color: Colors.green.shade600),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    icon: const Icon(Icons.restaurant_menu_rounded, size: 15),
                    label: const Text(
                      'Order More Food',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green.shade800,
                      side: BorderSide(color: Colors.green.shade600),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    icon: const Icon(Icons.restaurant_menu_rounded, size: 16),
                    label: const Text('Order Food Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await scanProvider.leaveTableSession();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result.message),
                          backgroundColor: result.success
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.exit_to_app_rounded, size: 16),
                  label: const Text('End'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static Widget _buildStepItem(
    int stepNum,
    String title,
    String subtitle,
    bool isActive,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: isActive ? color : Colors.grey.shade300,
            child: Text(
              stepNum.toString(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: isActive ? color : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9,
              color: isActive
                  ? color.withValues(alpha: 0.8)
                  : Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static Widget _buildStepConnector(bool isActive) {
    return Container(
      width: 20,
      height: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: isActive ? Colors.green.shade600 : Colors.grey.shade300,
    );
  }

  static void _showExtendSessionDialog(
    BuildContext context,
    ScanProvider scanProvider,
    int extensionCount,
  ) {
    final isFree = extensionCount < 1;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.more_time_rounded, color: Colors.green.shade800),
            const SizedBox(width: 8),
            const Text(
              'Extend Meal Session',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isFree ? Colors.green.shade100 : Colors.amber.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isFree
                    ? '🎉 1st Extension: FREE (+15 Mins)'
                    : '💳 Extension Fee: ₹30 (+15 Mins)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isFree ? Colors.green.shade900 : Colors.amber.shade900,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isFree
                  ? 'Your first 15-minute meal extension is completely free! Would you like to extend your session now?'
                  : 'You have already used your free extension. Extending your session by 15 minutes will charge ₹30 to your order bill. Proceed?',
              style: const TextStyle(fontSize: 13.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (isFree) {
                final res = await scanProvider.extendTableSession();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res.message),
                      backgroundColor:
                          res.success ? AppColors.success : AppColors.error,
                    ),
                  );
                }
              } else {
                _showExtensionPaymentSheet(context, scanProvider, 30.0);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(isFree ? 'Extend Now (Free)' : 'Pay ₹30 via Payment Gateway'),
          ),
        ],
      ),
    );
  }

  static void _showExtensionPaymentSheet(
    BuildContext context,
    ScanProvider scanProvider,
    double fee,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade700,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade900,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.payment_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Payment Gateway',
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade900,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'RAZORPAY SECURE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '100% Encrypted & Verified Payment',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Summary Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Session Extension (+15 Mins)',
                          style: AppTextStyles.bodyMedium,
                        ),
                        Text(
                          '₹${fee.toStringAsFixed(0)}',
                          style: AppTextStyles.titleLarge.copyWith(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.more_time_rounded,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Paid Extension Fee',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Text('Select Payment Method', style: AppTextStyles.titleSmall),
              const SizedBox(height: 10),

              // UPI Option
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.qr_code_2_rounded,
                      color: AppColors.primary,
                      size: 26,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'UPI Apps / Razorpay Online',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                          ),
                          Text(
                            'Google Pay, PhonePe, Paytm, Cards & NetBanking',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 22,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Pay via Gateway Button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    scanProvider.initiatePaidSessionExtension(
                      fee: fee,
                      onCompleted: (success, message) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(message),
                            backgroundColor:
                                success ? AppColors.success : AppColors.error,
                          ),
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.lock_outline_rounded, size: 18),
                  label: Text(
                    'Pay ₹${fee.toStringAsFixed(0)} via Payment Gateway',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FiveMinTimerWidget extends StatefulWidget {
  final DateTime expiresAt;
  final VoidCallback onExpired;

  const _FiveMinTimerWidget({required this.expiresAt, required this.onExpired});

  @override
  State<_FiveMinTimerWidget> createState() => _FiveMinTimerWidgetState();
}

class _FiveMinTimerWidgetState extends State<_FiveMinTimerWidget> {
  Timer? _timer;
  bool _expiredHandled = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final now = DateTime.now();
      if (now.isAfter(widget.expiresAt) && !_expiredHandled) {
        _expiredHandled = true;
        widget.onExpired();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diff = widget.expiresAt.difference(now);

    if (diff.isNegative) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.shade400),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 16,
              color: Colors.red.shade900,
            ),
            const SizedBox(width: 6),
            Text(
              '5-Min Grace Period Ended — Releasing Chairs...',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade900,
              ),
            ),
          ],
        ),
      );
    }

    final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade600),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hourglass_top_rounded,
            size: 18,
            color: Colors.amber.shade900,
          ),
          const SizedBox(width: 8),
          Text(
            'Order Food Timer: $minutes:$seconds remaining',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade900,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoBookingFlowGuideCard extends StatefulWidget {
  final VoidCallback? onScanTap;
  final VoidCallback? onReserveTap;

  const _NoBookingFlowGuideCard({this.onScanTap, this.onReserveTap});

  @override
  State<_NoBookingFlowGuideCard> createState() =>
      _NoBookingFlowGuideCardState();
}

class _NoBookingFlowGuideCardState extends State<_NoBookingFlowGuideCard> {
  int _selectedFlow = 0; // 0 = Advance Booking, 1 = Walk-In QR Scan

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Segmented Minimal Toggle (Advance Booking vs Walk-In Scan)
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFlow = 0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedFlow == 0
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_month_rounded,
                            size: 14,
                            color: _selectedFlow == 0
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Advance Booking',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: _selectedFlow == 0
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFlow = 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedFlow == 1
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code_scanner_rounded,
                            size: 14,
                            color: _selectedFlow == 1
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Walk-In QR Scan',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: _selectedFlow == 1
                                  ? Colors.white
                                  : AppColors.textSecondary,
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
          const SizedBox(height: 14),

          if (_selectedFlow == 0) ...[
            // Advance Booking Flow
            Text(
              'Advance Booking Flow (3 Steps)',
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Book in advance ➔ Scan QR at table ➔ Order food before grace timer expires',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                CanteenFlowGuideCard._buildStepItem(
                  1,
                  'Reserve Seat',
                  'Book table',
                  true,
                  Colors.orange,
                ),
                CanteenFlowGuideCard._buildStepConnector(false),
                CanteenFlowGuideCard._buildStepItem(
                  2,
                  'Scan QR',
                  'Check-in',
                  false,
                  Colors.grey,
                ),
                CanteenFlowGuideCard._buildStepConnector(false),
                CanteenFlowGuideCard._buildStepItem(
                  3,
                  'Order Food',
                  'Grace Timer',
                  false,
                  Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    widget.onReserveTap ??
                    () => Navigator.pushNamed(
                      context,
                      AppRoutes.tableReservationScreen,
                    ),
                icon: const Icon(Icons.table_restaurant_rounded, size: 18),
                label: const Text('Book Table & Chair Seat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ] else ...[
            // Walk-In QR Flow
            Text(
              'Walk-In QR Flow (3 Steps)',
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Physically in canteen? Scan QR ➔ Pick chair ➔ Order food before grace timer expires',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                CanteenFlowGuideCard._buildStepItem(
                  1,
                  'Enter Canteen',
                  'Find free table',
                  true,
                  Colors.orange,
                ),
                CanteenFlowGuideCard._buildStepConnector(false),
                CanteenFlowGuideCard._buildStepItem(
                  2,
                  'Scan Table QR',
                  'Free seat pick',
                  false,
                  Colors.grey,
                ),
                CanteenFlowGuideCard._buildStepConnector(false),
                CanteenFlowGuideCard._buildStepItem(
                  3,
                  'Order Food',
                  'Grace Timer',
                  false,
                  Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    widget.onScanTap ??
                    () => Navigator.pushNamed(context, AppRoutes.scanScreen),
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                label: const Text('Scan Table QR Code Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

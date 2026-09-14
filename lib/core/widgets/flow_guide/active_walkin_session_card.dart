import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/table_reservation/provider/table_reservation_provider.dart';
import '../../../features/scan/provider/scan_provider.dart';
import '../../../features/scan/model/table_session_response.dart';
import '../../theme/app_colors.dart';
import 'canteen_flow_step_card.dart';

class ActiveWalkInSessionCard extends StatelessWidget {
  final TableSession session;

  const ActiveWalkInSessionCard({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final scanProvider = Provider.of<ScanProvider>(context);
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
              const StepItemWidget(stepNum: 1, title: 'Entered', subtitle: 'Done', isActive: true, color: Colors.green),
              const StepConnectorWidget(isActive: true),
              const StepItemWidget(stepNum: 2, title: 'QR Scanned', subtitle: 'Done', isActive: true, color: Colors.green),
              const StepConnectorWidget(isActive: true),
              StepItemWidget(
                stepNum: 3,
                title: 'Order Food',
                subtitle: hasOrder ? 'Done' : 'Grace Timer',
                isActive: true,
                color: hasOrder ? Colors.green : Colors.amber.shade800,
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (!hasOrder) ...[
            FiveMinTimerWidget(
              expiresAt: expiresAt,
              onExpired: () async {
                final res = await scanProvider.leaveTableSession();
                if (context.mounted) {
                  final reservationProvider = context.read<TableReservationProvider>();
                  await reservationProvider.fetchMyReservations();
                  await reservationProvider.fetchLiveTablesOverview();
                  if (!context.mounted) return;
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
                    final reservationProvider = context.read<TableReservationProvider>();
                    await reservationProvider.fetchMyReservations();
                    await reservationProvider.fetchLiveTablesOverview();
                    if (!context.mounted) return;
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
                    onPressed: () => ExtendSessionHelper.showExtendSessionDialog(
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
                      final reservationProvider = context.read<TableReservationProvider>();
                      await reservationProvider.fetchMyReservations();
                      await reservationProvider.fetchLiveTablesOverview();
                      if (!context.mounted) return;
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
}

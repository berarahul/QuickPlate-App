import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/table_reservation/provider/table_reservation_provider.dart';
import '../../features/table_reservation/models/table_reservation_model.dart';
import '../../features/scan/provider/scan_provider.dart';
import 'flow_guide/active_walkin_session_card.dart';
import 'flow_guide/reserved_flow_guide_card.dart';
import 'flow_guide/checked_in_flow_guide_card.dart';
import 'flow_guide/no_booking_flow_guide_card.dart';

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
          return ActiveWalkInSessionCard(session: liveSession);
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
          return CheckedInFlowGuideCard(reservation: activeRes!);
        } else if (status == 'booked' || status == 'reserved') {
          return ReservedFlowGuideCard(
            reservation: activeRes!,
            onScanTap: onScanTap,
          );
        } else {
          return NoBookingFlowGuideCard(
            onScanTap: onScanTap,
            onReserveTap: onReserveTap,
          );
        }
      },
    );
  }
}

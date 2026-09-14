import 'package:flutter/material.dart';
import '../../../features/table_reservation/models/table_reservation_model.dart';
import '../../routes/app_routes.dart';
import 'canteen_flow_step_card.dart';

class ReservedFlowGuideCard extends StatelessWidget {
  final TableReservation reservation;
  final VoidCallback? onScanTap;

  const ReservedFlowGuideCard({
    super.key,
    required this.reservation,
    this.onScanTap,
  });

  @override
  Widget build(BuildContext context) {
    final seatsStr = reservation.seatNumbers.isNotEmpty
        ? '(${reservation.seatNumbers.join(", ")})'
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
                      'Table ${reservation.tableId} Reserved $seatsStr',
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
              const StepItemWidget(
                stepNum: 1,
                title: 'Reserved',
                subtitle: 'Done',
                isActive: true,
                color: Colors.green,
              ),
              const StepConnectorWidget(isActive: true),
              StepItemWidget(
                stepNum: 2,
                title: 'Scan QR',
                subtitle: 'REQUIRED NOW',
                isActive: true,
                color: Colors.amber.shade800,
              ),
              const StepConnectorWidget(isActive: false),
              const StepItemWidget(
                stepNum: 3,
                title: 'Order Food',
                subtitle: 'Grace Timer',
                isActive: false,
                color: Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            '📌 Arrive at Table ${reservation.tableId} & scan its QR code to check in. Order food before the grace timer expires to lock your seats!',
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
              label: Text('Scan Table ${reservation.tableId} QR Code Now'),
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
}

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../routes/app_routes.dart';
import 'canteen_flow_step_card.dart';

class NoBookingFlowGuideCard extends StatefulWidget {
  final VoidCallback? onScanTap;
  final VoidCallback? onReserveTap;

  const NoBookingFlowGuideCard({super.key, this.onScanTap, this.onReserveTap});

  @override
  State<NoBookingFlowGuideCard> createState() => _NoBookingFlowGuideCardState();
}

class _NoBookingFlowGuideCardState extends State<NoBookingFlowGuideCard> {
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
            const Row(
              children: [
                StepItemWidget(
                  stepNum: 1,
                  title: 'Reserve Seat',
                  subtitle: 'Book table',
                  isActive: true,
                  color: Colors.orange,
                ),
                StepConnectorWidget(isActive: false),
                StepItemWidget(
                  stepNum: 2,
                  title: 'Scan QR',
                  subtitle: 'Check-in',
                  isActive: false,
                  color: Colors.grey,
                ),
                StepConnectorWidget(isActive: false),
                StepItemWidget(
                  stepNum: 3,
                  title: 'Order Food',
                  subtitle: 'Grace Timer',
                  isActive: false,
                  color: Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onReserveTap ??
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
            const Row(
              children: [
                StepItemWidget(
                  stepNum: 1,
                  title: 'Enter Canteen',
                  subtitle: 'Find free table',
                  isActive: true,
                  color: Colors.orange,
                ),
                StepConnectorWidget(isActive: false),
                StepItemWidget(
                  stepNum: 2,
                  title: 'Scan Table QR',
                  subtitle: 'Free seat pick',
                  isActive: false,
                  color: Colors.grey,
                ),
                StepConnectorWidget(isActive: false),
                StepItemWidget(
                  stepNum: 3,
                  title: 'Order Food',
                  subtitle: 'Grace Timer',
                  isActive: false,
                  color: Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onScanTap ??
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

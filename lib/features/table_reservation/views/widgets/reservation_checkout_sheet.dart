import '../../../../core/app_exports.dart';
import '../../provider/table_reservation_provider.dart';
import 'reservation_success_dialog.dart';

class ReservationCheckoutSheet {
  static void showPaymentMethodModal(
    BuildContext context,
    TableReservationProvider provider,
    double depositAmount,
  ) {
    showModalBottomSheet(
      context: context,
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
                      color: AppColors.primaryTint,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.payment_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Payment Method',
                        style: AppTextStyles.titleMedium,
                      ),
                      Text(
                        'Deposit Payable: ₹${depositAmount.toStringAsFixed(0)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 28),

              // Info Banner for Online Only Payment
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
                    Icon(
                      Icons.verified_user_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Advance table & seat booking requires Razorpay Online Payment to lock your slot.',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Option: Razorpay Online Payment
              InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  showRazorpayCheckoutSheet(
                    context,
                    provider,
                    depositAmount,
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.payment_rounded,
                        color: Colors.black,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Pay ₹${depositAmount.toStringAsFixed(0)} via Razorpay',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static void showRazorpayCheckoutSheet(
    BuildContext context,
    TableReservationProvider provider,
    double depositAmount,
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
                              'Razorpay Secure Payment',
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
                                'GATEWAY',
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
                          '100% Encrypted & Verified via Razorpay',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Deposit Amount Summary Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Deposit Payable Amount',
                      style: AppTextStyles.bodyMedium,
                    ),
                    Text(
                      '₹${depositAmount.toStringAsFixed(0)}',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Text('Selected Payment Mode', style: AppTextStyles.titleSmall),
              const SizedBox(height: 10),

              // UPI Option
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
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
                            'UPI Apps (Google Pay / PhonePe / Paytm)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Instant 1-tap checkout via UPI',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Card Option
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.credit_card_rounded,
                      color: AppColors.textSecondary,
                      size: 26,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Credit / Debit Card / NetBanking',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Visa, MasterCard, RuPay, SBI, HDFC',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Pay via Razorpay Button
              CustomElevatedButton(
                text: 'Pay ₹${depositAmount.toStringAsFixed(0)} via Razorpay',
                onPressed: () {
                  Navigator.pop(ctx);
                  _executeReservation(context, provider, depositAmount);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> _executeReservation(
    BuildContext context,
    TableReservationProvider provider,
    double depositAmount,
  ) async {
    await provider.initiateRazorpayReservation(
      depositAmount: depositAmount,
      onCompleted: (reservation, errorMessage) {
        if (!context.mounted) return;
        if (reservation != null) {
          ReservationSuccessDialog.show(context, reservation);
        } else if (errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
    );
  }
}

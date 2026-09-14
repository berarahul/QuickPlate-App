import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../../features/scan/provider/scan_provider.dart';

class StepItemWidget extends StatelessWidget {
  final int stepNum;
  final String title;
  final String subtitle;
  final bool isActive;
  final Color color;

  const StepItemWidget({
    super.key,
    required this.stepNum,
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
}

class StepConnectorWidget extends StatelessWidget {
  final bool isActive;

  const StepConnectorWidget({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: isActive ? Colors.green.shade600 : Colors.grey.shade300,
    );
  }
}

class FiveMinTimerWidget extends StatefulWidget {
  final DateTime expiresAt;
  final VoidCallback onExpired;

  const FiveMinTimerWidget({super.key, required this.expiresAt, required this.onExpired});

  @override
  State<FiveMinTimerWidget> createState() => _FiveMinTimerWidgetState();
}

class _FiveMinTimerWidgetState extends State<FiveMinTimerWidget> {
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

class ExtendSessionHelper {
  static void showExtendSessionDialog(
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
                showExtensionPaymentSheet(context, scanProvider, 30.0);
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

  static void showExtensionPaymentSheet(
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

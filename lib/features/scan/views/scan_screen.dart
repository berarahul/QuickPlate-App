import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../provider/scan_provider.dart';
import '../../../core/app_exports.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first;
      final rawValue = barcode.rawValue;

      if (rawValue != null) {
        setState(() {
          _isProcessing = true;
        });

        // Extract tableId if the QR code is a URL, else assume it's the tableId directly
        String tableId = rawValue;
        if (rawValue.contains('tableId=')) {
          final uri = Uri.tryParse(rawValue);
          if (uri != null && uri.queryParameters.containsKey('tableId')) {
            tableId = uri.queryParameters['tableId']!;
          }
        }

        final scanProvider = context.read<ScanProvider>();
        final success = await scanProvider.startTableSession(tableId);

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  scanProvider.sessionResponse?.message ??
                      'Table session started!',
                ),
              ),
            );
            // Optionally navigate to cart or menu automatically
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  scanProvider.errorMessage ?? 'Failed to start session.',
                ),
                backgroundColor: AppColors.error,
              ),
            );
            setState(() {
              _isProcessing = false; // Allow rescanning
            });
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<ScanProvider>(
          builder: (context, scanProvider, child) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ready to order?',
                            style: AppTextStyles.labelSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Scan Table QR',
                            style: AppTextStyles.displayLarge,
                          ),
                        ],
                      ),
                      const Spacer(),
                      ValueListenableBuilder<MobileScannerState>(
                        valueListenable: _scannerController,
                        builder: (context, state, child) {
                          final on =
                              state.torchState == TorchState.on ||
                              state.torchState == TorchState.auto;
                          return Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                on
                                    ? Icons.flash_on_rounded
                                    : Icons.flash_off_rounded,
                                size: 20,
                              ),
                              onPressed: () => _scannerController.toggleTorch(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: scanProvider.isLoading
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              'Starting table session...',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        )
                      : Stack(
                          children: [
                            MobileScanner(
                              controller: _scannerController,
                              onDetect: _onDetect,
                            ),
                            // Dark vignette with cut-out hole
                            ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                Colors.black.withValues(alpha: 0.55),
                                BlendMode.srcOut,
                              ),
                              child: Stack(
                                children: [
                                  Container(color: Colors.transparent),
                                  Center(
                                    child: Container(
                                      width: 250,
                                      height: 250,
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Scanner frame
                            Center(
                              child: Container(
                                width: 250,
                                height: 250,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.transparent,
                                    width: 0,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Stack(
                                  children: [
                                    // Corner accents
                                    ..._buildCorners(),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 48,
                              left: 24,
                              right: 24,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.qr_code_2_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Align the table QR code within the frame',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Text(
                    'Scanning links your device to your table so the kitchen knows exactly where to bring your order.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildCorners() {
    const size = 36.0;
    const thick = 4.0;
    final color = AppColors.primary;
    return [
      Positioned(
        top: 0,
        left: 0,
        child: Container(width: size, height: thick, color: color),
      ),
      Positioned(
        top: 0,
        left: 0,
        child: Container(width: thick, height: size, color: color),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: Container(width: size, height: thick, color: color),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: Container(width: thick, height: size, color: color),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(width: size, height: thick, color: color),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(width: thick, height: size, color: color),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(width: size, height: thick, color: color),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(width: thick, height: size, color: color),
      ),
    ];
  }
}

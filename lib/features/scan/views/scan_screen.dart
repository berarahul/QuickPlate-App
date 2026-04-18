import 'package:flutter/material.dart';
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
                content: Text(scanProvider.sessionResponse?.message ?? 'Table session started!'),
                backgroundColor: Colors.green,
              ),
            );
            // Optionally navigate to cart or menu automatically
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(scanProvider.errorMessage ?? 'Failed to start session.'),
                backgroundColor: Colors.red,
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
      appBar: AppBar(
        title: const Text('Scan Table QR', style: AppTextStyles.titleLarge),
        actions: [
          IconButton(
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: _scannerController,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.off:
                  case TorchState.unavailable:
                    return const Icon(Icons.flash_off);
                  case TorchState.on:
                  case TorchState.auto:
                    return const Icon(Icons.flash_on);
                }
              },
            ),
            iconSize: 32.0,
            onPressed: () => _scannerController.toggleTorch(),
          ),
        ],
      ),
      body: Consumer<ScanProvider>(
        builder: (context, scanProvider, child) {
          if (scanProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Starting table session...', style: AppTextStyles.bodyLarge),
                ],
              ),
            );
          }

          return Stack(
            children: [
              MobileScanner(controller: _scannerController, onDetect: _onDetect),
              // Scanner overlay (simple target box)
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary, width: 4.0),
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                ),
              ),
              const Positioned(
                bottom: 80,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Align QR code within the frame',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      backgroundColor: Colors.black54,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

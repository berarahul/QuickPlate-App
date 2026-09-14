import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../provider/scan_provider.dart';
import '../../table_reservation/provider/table_reservation_provider.dart';
import '../../../core/app_exports.dart';
import 'widgets/scan_chair_selection_dialog.dart';
import 'widgets/scan_camera_overlay.dart';

class ScanScreen extends StatefulWidget {
  final bool isActive;
  final VoidCallback? onSessionStarted;

  const ScanScreen({
    super.key,
    this.isActive = true,
    this.onSessionStarted,
  });

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    autoStart: false,
  );
  bool _isProcessing = false;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      _startScanner();
    }
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(ScanScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _startScanner();
      } else {
        _stopScanner();
      }
    }
  }

  void _startScanner() {
    try {
      _scannerController.start();
    } catch (e) {
      debugPrint('Error starting scanner: $e');
    }
  }

  void _stopScanner() {
    try {
      _scannerController.stop();
    } catch (e) {
      debugPrint('Error stopping scanner: $e');
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _scanFromGallery() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
        return;
      }

      final BarcodeCapture? capture =
          await _scannerController.analyzeImage(image.path);

      if (capture != null && capture.barcodes.isNotEmpty) {
        final barcode = capture.barcodes.first;
        final rawValue = barcode.rawValue;
        if (rawValue != null && rawValue.isNotEmpty) {
          await _handleScannedRawValue(rawValue);
        } else {
          _showGalleryError('No valid QR code content found in selected image.');
        }
      } else {
        _showGalleryError('No valid QR code found in selected image.');
      }
    } catch (e) {
      _showGalleryError('Error reading image: $e');
    }
  }

  void _showGalleryError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first;
      final rawValue = barcode.rawValue;

      if (rawValue != null && rawValue.isNotEmpty) {
        setState(() {
          _isProcessing = true;
        });

        await _handleScannedRawValue(rawValue);
      }
    }
  }

  Future<void> _handleScannedRawValue(String rawValue) async {
    String tableId = rawValue.trim();
    if (tableId.contains('tableId=')) {
      final uri = Uri.tryParse(tableId);
      if (uri != null &&
          uri.queryParameters.containsKey('tableId') &&
          uri.queryParameters['tableId']!.isNotEmpty) {
        tableId = uri.queryParameters['tableId']!;
      } else {
        final match =
            RegExp(r'tableId=([^&]+)', caseSensitive: false).firstMatch(tableId);
        if (match != null && match.groupCount >= 1) {
          tableId = match.group(1)!;
        }
      }
    }
    tableId = tableId.trim().toUpperCase();

    if (!mounted) return;

    try {
      final scanProvider = context.read<ScanProvider>();
      final reservationProvider = context.read<TableReservationProvider>();
      final messenger = ScaffoldMessenger.of(context);

      await reservationProvider.fetchMyReservations();
      final myReservations = reservationProvider.myReservations;
      final now = DateTime.now();

      final activeSession = scanProvider.sessionResponse?.data?.session;

      final advanceReservation = myReservations.where((r) {
        if (r.reservationStatus == 'cancelled') return false;
        try {
          final end = DateTime.parse(r.endTime);
          return end.isAfter(now);
        } catch (_) {
          return true;
        }
      }).firstOrNull;

      if (activeSession != null &&
          activeSession.isActive == true &&
          activeSession.tableId != tableId) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'You currently have an active session running at Table ${activeSession.tableId}. Please leave Table ${activeSession.tableId} before joining Table $tableId.',
              ),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      final isAlreadyCheckedIn = (activeSession != null &&
              activeSession.isActive == true &&
              activeSession.tableId == tableId) ||
          (advanceReservation != null &&
              advanceReservation.tableId == tableId &&
              advanceReservation.reservationStatus.toLowerCase() ==
                  'checked_in');

      if (isAlreadyCheckedIn) {
        if (!mounted) return;
        final selectedChairs =
            await ScanChairSelectionDialog.showChairSelectionDialog(
          context,
          scanProvider,
          tableId,
        );
        if (selectedChairs == null || selectedChairs.isEmpty) {
          return;
        }

        final success = await scanProvider.startTableSession(
          tableId,
          chairIds: selectedChairs,
        );

        if (mounted) {
          if (success) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  scanProvider.sessionResponse?.message ??
                      'Added ${selectedChairs.join(", ")} to Table $tableId session!',
                ),
                backgroundColor: AppColors.success,
              ),
            );

            if (widget.onSessionStarted != null) {
              widget.onSessionStarted!();
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, AppRoutes.dashboardScreen);
            }
          } else {
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  scanProvider.errorMessage ?? 'Failed to update session.',
                ),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
        return;
      }

      if (advanceReservation != null &&
          advanceReservation.reservationStatus.toLowerCase() != 'checked_in') {
        if (advanceReservation.tableId != tableId) {
          if (mounted) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  'You already have an advance table reservation for Table ${advanceReservation.tableId}. Please scan the QR code at Table ${advanceReservation.tableId}.',
                ),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          return;
        } else {
          try {
            final resStart =
                DateTimeFormatter.parseDateTime(advanceReservation.startTime) ??
                    DateTime.now();
            final resEnd =
                DateTimeFormatter.parseDateTime(advanceReservation.endTime) ??
                    DateTime.now();

            if (now.isBefore(resStart)) {
              if (mounted) {
                final startFormatted = DateTimeFormatter.formatTime(resStart);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Your reserved time slot for Table $tableId starts at $startFormatted. You can only start your session once your reserved time slot begins.',
                    ),
                    backgroundColor: AppColors.error,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
              return;
            }

            if (now.isAfter(resEnd)) {
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content:
                        Text('Your reservation for Table $tableId has expired.'),
                    backgroundColor: AppColors.error,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
              return;
            }
          } catch (_) {}

          if (!mounted) return;
          final confirmed = await ScanChairSelectionDialog
              .showAdvanceCheckInDialog(context, advanceReservation);
          if (!confirmed) return;

          final bookedChairs = advanceReservation.chairIds.isNotEmpty
              ? advanceReservation.chairIds
              : ['Chair 1'];

          final success = await scanProvider.startTableSession(
            tableId,
            chairIds: bookedChairs,
          );

          if (mounted) {
            if (success) {
              await reservationProvider.fetchMyReservations();
              if (!mounted) return;

              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    scanProvider.sessionResponse?.message ??
                        'Checked in to Table $tableId! Session started.',
                  ),
                  backgroundColor: AppColors.success,
                ),
              );

              if (widget.onSessionStarted != null) {
                widget.onSessionStarted!();
              } else if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, AppRoutes.dashboardScreen);
              }
            } else {
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    scanProvider.errorMessage ?? 'Failed to start session.',
                  ),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
          return;
        }
      }

      if (!mounted) return;
      final selectedChairs =
          await ScanChairSelectionDialog.showChairSelectionDialog(
        context,
        scanProvider,
        tableId,
      );
      if (selectedChairs == null || selectedChairs.isEmpty) {
        return;
      }

      final success = await scanProvider.startTableSession(
        tableId,
        chairIds: selectedChairs,
      );

      if (mounted) {
        if (success) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                scanProvider.sessionResponse?.message ??
                    'Table $tableId session updated with ${selectedChairs.join(", ")}!',
              ),
              backgroundColor: AppColors.success,
            ),
          );

          if (widget.onSessionStarted != null) {
            widget.onSessionStarted!();
          } else if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushReplacementNamed(context, AppRoutes.dashboardScreen);
          }
        } else {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                scanProvider.errorMessage ?? 'Failed to update session.',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
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
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              tooltip: 'Scan QR from Gallery',
                              icon: const Icon(
                                Icons.photo_library_rounded,
                                size: 20,
                              ),
                              onPressed: _scanFromGallery,
                            ),
                          ),
                          const SizedBox(width: 8),
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
                                  tooltip: 'Toggle Flash',
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
                      : ScanCameraOverlay(
                          controller: _scannerController,
                          isActive: widget.isActive,
                          onDetect: _onDetect,
                          onScanFromGallery: _scanFromGallery,
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
}

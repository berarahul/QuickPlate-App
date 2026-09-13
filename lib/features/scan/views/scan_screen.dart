import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../provider/scan_provider.dart';
import '../../table_reservation/provider/table_reservation_provider.dart';
import '../../table_reservation/models/table_reservation_model.dart';
import '../../../core/app_exports.dart';

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
    // Extract tableId if the QR code is a URL, else assume it's the tableId directly
    String tableId = rawValue;
    if (rawValue.contains('tableId=')) {
      final uri = Uri.tryParse(rawValue);
      if (uri != null && uri.queryParameters.containsKey('tableId')) {
        tableId = uri.queryParameters['tableId']!;
      }
    }

    if (!mounted) return;

    try {
      final scanProvider = context.read<ScanProvider>();
      final reservationProvider = context.read<TableReservationProvider>();
      final messenger = ScaffoldMessenger.of(context);

      // Strict Validation: disallow QR scan for users who booked a table in advance
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

      if (activeSession != null && activeSession.isActive == true && activeSession.tableId != tableId) {
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

      // Check if session has ALREADY been started / checked-in at this table
      final isAlreadyCheckedIn = (activeSession != null && activeSession.isActive == true && activeSession.tableId == tableId) ||
          (advanceReservation != null && advanceReservation.tableId == tableId && advanceReservation.reservationStatus.toLowerCase() == 'checked_in');

      if (isAlreadyCheckedIn) {
        // Session is already running! Show available chairs so user can add extra chairs to current running session.
        final selectedChairs = await _showChairSelectionDialog(tableId);
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

      if (advanceReservation != null && advanceReservation.reservationStatus.toLowerCase() != 'checked_in') {
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
          // Advance reservation at this table
          try {
            final resStart = DateTimeFormatter.parseDateTime(advanceReservation.startTime) ?? DateTime.now();
            final resEnd = DateTimeFormatter.parseDateTime(advanceReservation.endTime) ?? DateTime.now();

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
                    content: Text('Your reservation for Table $tableId has expired.'),
                    backgroundColor: AppColors.error,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
              return;
            }
          } catch (_) {}

          if (!mounted) return;
          // Show Check-In confirmation modal displaying reserved chairs and slot
          final confirmed = await _showAdvanceCheckInDialog(context, advanceReservation);
          if (!confirmed) return;

          // Inside slot check-in window -> check in using reserved chairs
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

      // Walk-in scan (or adding chairs to existing session at same table) -> open Chair Selection Dialog
      final selectedChairs = await _showChairSelectionDialog(tableId);
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

          // Automatically redirect to the Live Table View section (Tab Index 1)
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

  Future<bool> _showAdvanceCheckInDialog(
    BuildContext context,
    TableReservation reservation,
  ) async {
    final seatText = reservation.seatNumbers.isNotEmpty
        ? reservation.seatNumbers.join(', ')
        : (reservation.chairIds.isNotEmpty
            ? reservation.chairIds.join(', ')
            : '${reservation.seatsBooked} seat(s)');

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            AppPopScale(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  shape: BoxShape.circle,
                  boxShadow: AppColors.softShadow,
                ),
                child: Icon(
                  Icons.table_restaurant_rounded,
                  color: AppColors.primary,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Table ${reservation.tableId} Check-In',
              style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Start table session for $seatText?',
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_seat_rounded, color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Reserved Chairs: $seatText',
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.access_time_rounded, color: AppColors.textSecondary, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        DateTimeFormatter.formatTimeRange(reservation.startTime, reservation.endTime),
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tap "Start Session" to check in with your reserved chairs.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: AppColors.primary.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
            label: const Text(
              'Start Session',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<List<String>?> _showChairSelectionDialog(String tableId) async {
    final scanProvider = context.read<ScanProvider>();
    final details = await scanProvider.fetchOccupiedChairsDetails(tableId);
    final occupied = details.occupiedChairs;

    final myCurrentSession = scanProvider.sessionResponse?.data?.session;
    final myExistingChairs = (myCurrentSession != null && myCurrentSession.tableId == tableId)
        ? (myCurrentSession.chairIds ?? [])
        : <String>[];

    // Other users' occupied chairs (exclude my own currently held chairs so they are not treated as conflicts)
    final occupiedByOthers = occupied.where((c) => !myExistingChairs.contains(c)).toList();

    int totalSeats = details.maxCapacity > 0 ? details.maxCapacity : 4;
    for (final chairStr in occupied) {
      final match = RegExp(r'Chair\s*(\d+)').firstMatch(chairStr);
      if (match != null) {
        final num = int.tryParse(match.group(1) ?? '');
        if (num != null && num > totalSeats) {
          totalSeats = num;
        }
      }
    }

    final allChairs = List.generate(totalSeats, (i) => 'Chair ${i + 1}');
    final availableChairs = allChairs.where((c) => !occupiedByOthers.contains(c) && !myExistingChairs.contains(c)).toList();
    final initialSelection = availableChairs.isNotEmpty ? {availableChairs.first} : <String>{};
    final selected = Set<String>.from(initialSelection);

    if (!mounted) return null;

    return showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final hasExistingChairs = myExistingChairs.isNotEmpty;
            final titleText = hasExistingChairs
                ? 'Add Chair to Table $tableId'
                : 'Table $tableId Scanned';
            final subtitleText = hasExistingChairs
                ? 'Your active seats: ${myExistingChairs.join(", ")}. Select additional chair(s) to add:'
                : 'Select your available chair(s)';

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.event_seat_rounded, color: AppColors.primary, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(titleText, style: AppTextStyles.displayLarge),
                            Text(subtitleText, style: AppTextStyles.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (availableChairs.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade700),
                      ),
                      child: Text(
                        hasExistingChairs
                            ? 'All other chairs on Table $tableId are currently occupied by other users.'
                            : 'All chairs on Table $tableId are currently booked or occupied.',
                        style: TextStyle(color: Colors.red.shade200, fontWeight: FontWeight.w600),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: availableChairs.map((chair) {
                        final isSelected = selected.contains(chair);
                        return FilterChip(
                          label: Text(chair),
                          selected: isSelected,
                          selectedColor: AppColors.primary.withValues(alpha: 0.2),
                          checkmarkColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                          onSelected: (val) {
                            setModalState(() {
                              if (val) {
                                selected.add(chair);
                              } else {
                                if (selected.length > 1) selected.remove(chair);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: selected.isEmpty
                          ? null
                          : () => Navigator.pop(modalCtx, selected.toList()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        selected.isEmpty
                            ? 'No Available Chairs'
                            : (hasExistingChairs
                                ? 'Add ${selected.length} Chair${selected.length > 1 ? "s" : ""} to Active Session'
                                : 'Start Session (${selected.length} Chair${selected.length > 1 ? "s" : ""})'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

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
                      : Stack(
                          children: [
                            if (widget.isActive)
                              MobileScanner(
                                controller: _scannerController,
                                onDetect: _onDetect,
                              )
                            else
                              Container(color: Colors.black),
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
                              bottom: 24,
                              left: 24,
                              right: 24,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
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
                                  const SizedBox(height: 10),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _scanFromGallery,
                                      borderRadius: BorderRadius.circular(14),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.photo_library_rounded,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Scan QR from Gallery',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
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

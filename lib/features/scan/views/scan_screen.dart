import 'dart:async';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../provider/scan_provider.dart';
import '../../../core/app_exports.dart';

class ScanScreen extends StatefulWidget {
  final bool isActive;
  const ScanScreen({super.key, this.isActive = true});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    autoStart: false,
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

        // Show Chair Selection Popup Dialog
        if (mounted) {
          final scanProvider = context.read<ScanProvider>();
          final messenger = ScaffoldMessenger.of(context);

          final selectedChairs = await _showChairSelectionDialog(tableId);
          if (selectedChairs == null || selectedChairs.isEmpty) {
            setState(() {
              _isProcessing = false;
            });
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
                        'Table $tableId session started with ${selectedChairs.join(", ")}!',
                  ),
                ),
              );
            } else {
              messenger.showSnackBar(
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
  }

  Future<List<String>?> _showChairSelectionDialog(String tableId) async {
    final scanProvider = context.read<ScanProvider>();
    final occupied = scanProvider.sessionResponse?.data?.occupiedChairs ?? [];
    final allChairs = ['Chair 1', 'Chair 2', 'Chair 3', 'Chair 4'];
    final availableChairs = allChairs.where((c) => !occupied.contains(c)).toList();
    final initialSelection = availableChairs.isNotEmpty ? {availableChairs.first} : <String>{};
    final selected = Set<String>.from(initialSelection);

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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Table $tableId Scanned', style: AppTextStyles.displayLarge),
                          Text('Select your available chair(s)', style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: allChairs.map((chair) {
                      final isOccupied = occupied.contains(chair);
                      final isSelected = selected.contains(chair);
                      return FilterChip(
                        label: Text(isOccupied ? '$chair (Occupied)' : chair),
                        selected: isSelected,
                        selectedColor: AppColors.primary.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.primary,
                        disabledColor: Colors.grey.shade800,
                        labelStyle: TextStyle(
                          color: isOccupied
                              ? Colors.grey
                              : isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        onSelected: isOccupied
                            ? null
                            : (val) {
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
                            ? 'All Chairs Occupied'
                            : 'Start Session (${selected.length} Chair${selected.length > 1 ? "s" : ""})',
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
                if (scanProvider.sessionResponse?.data?.session != null)
                  _buildActiveSessionCard(context, scanProvider),
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

  String _formatRemainingTime(String? expiresAtStr) {
    if (expiresAtStr == null) return '00:00';
    try {
      final expiresAt = DateTime.parse(expiresAtStr).toLocal();
      final now = DateTime.now();
      final difference = expiresAt.difference(now);
      if (difference.isNegative) {
        return 'Expired';
      }
      final minutes = difference.inMinutes;
      final seconds = difference.inSeconds % 60;
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } catch (e) {
      return '00:00';
    }
  }

  Widget _buildActiveSessionCard(BuildContext context, ScanProvider scanProvider) {
    final data = scanProvider.sessionResponse?.data;
    final session = data?.session;
    final occupied = data?.occupiedChairs ?? [];
    if (session == null) return const SizedBox.shrink();

    final myChairs = (session.chairIds != null && session.chairIds!.isNotEmpty)
        ? session.chairIds!.join(', ')
        : 'Chair 1';

    final bool hasOrder = session.hasOrder ?? false;
    final String remainingTimeStr = _formatRemainingTime(session.expiresAt);
    final bool isExpired = remainingTimeStr == 'Expired';

    final Color badgeColor = hasOrder
        ? AppColors.primary
        : (isExpired ? AppColors.error : Colors.orange.shade800);
    final Color badgeBg = hasOrder
        ? AppColors.primaryTint
        : (isExpired ? Colors.red.shade50 : Colors.orange.shade50);
    final Color borderColor = hasOrder ? AppColors.primary : Colors.orange.shade600;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasOrder ? Icons.check_circle_rounded : Icons.timer_outlined,
                color: hasOrder ? AppColors.success : Colors.orange.shade800,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Table ${session.tableId}',
                  style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  hasOrder ? 'ACTIVE DINING' : '5-MIN GRACE',
                  style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Your Chair(s): $myChairs',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.hourglass_bottom_rounded, size: 14, color: badgeColor),
              const SizedBox(width: 4),
              Text(
                hasOrder
                    ? 'Session expires in: $remainingTimeStr'
                    : 'Order food within $remainingTimeStr to lock seat',
                style: AppTextStyles.bodySmall.copyWith(
                  color: badgeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (!hasOrder && !isExpired)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '⚠️ Order required within 5 mins or your seat will be automatically released.',
                style: TextStyle(fontSize: 11, color: Colors.orange.shade900, fontStyle: FontStyle.italic),
              ),
            ),
          if (occupied.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'All Active Chairs on Table: ${occupied.join(", ")}',
                style: AppTextStyles.bodySmall,
              ),
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: EdgeInsets.zero,
              ),
              icon: const Icon(Icons.exit_to_app_rounded, size: 16),
              label: const Text('End Table Session', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              onPressed: () async {
                final success = await scanProvider.leaveTableSession();
                if (context.mounted && success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Table session ended.')),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

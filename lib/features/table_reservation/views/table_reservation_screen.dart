import '../../../core/app_exports.dart';
import '../provider/table_reservation_provider.dart';
import '../models/table_availability_model.dart';
import '../models/table_reservation_model.dart';
import 'my_reservations_screen.dart';

class TableReservationScreen extends StatefulWidget {
  const TableReservationScreen({super.key});

  @override
  State<TableReservationScreen> createState() => _TableReservationScreenState();
}

class _TableReservationScreenState extends State<TableReservationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TableReservationProvider>().fetchAvailableTables();
    });
  }

  void _showReservationSuccessModal(BuildContext context, TableReservation reservation) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.successTint,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_rounded, color: AppColors.success, size: 48),
            ),
            const SizedBox(height: 12),
            Text(
              'Table Reserved!',
              style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Table ${reservation.tableId} • Seats ${reservation.seatNumbers.join(", ")}',
              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Date: ${DateTimeFormatter.formatDate(reservation.reservationDate)} (${DateTimeFormatter.formatTimeRange(reservation.startTime, reservation.endTime)})',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.stars_rounded, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '₹${reservation.depositPaidAmount.toStringAsFixed(0)} deposit paid! This will automatically discount your food order.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyReservationsScreen()),
              );
            },
            child: const Text('View My Reservations', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TableReservationProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Reserve Table & Seats', style: AppTextStyles.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outline_rounded),
            tooltip: 'My Reservations',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyReservationsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Filters Bar
            _buildFiltersBar(context, provider),

            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                              const SizedBox(height: 12),
                              Text(provider.errorMessage!, style: AppTextStyles.bodyMedium),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () => provider.fetchAvailableTables(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _buildTableSeatSelection(context, provider),
            ),

            if (provider.selectedSeats.isNotEmpty)
              _buildBottomCheckoutBar(context, provider),
          ],
        ),
      ),
    );
  }

  String _format12Hour(String time24) {
    try {
      final parts = time24.split(':').map(int.parse).toList();
      final hour = parts[0];
      final min = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      final h12 = hour % 12 == 0 ? 12 : hour % 12;
      final minStr = min.toString().padLeft(2, '0');
      return '${h12.toString().padLeft(2, '0')}:$minStr $period';
    } catch (_) {
      return time24;
    }
  }

  Future<void> _selectStartTime(BuildContext context, TableReservationProvider provider) async {
    final now = DateTime.now();
    final todayStr = now.toIso8601String().split('T')[0];
    final isToday = provider.selectedDate == todayStr;
    final nowMin = now.hour * 60 + now.minute;

    final response = provider.availabilityResponse;
    final openStr = response?.openingTime ?? '09:00';
    final closeStr = response?.closingTime ?? '17:00';

    final openParts = openStr.split(':').map(int.parse).toList();
    final openMin = openParts[0] * 60 + openParts[1];

    final closeParts = closeStr.split(':').map(int.parse).toList();
    final closeMin = closeParts[0] * 60 + closeParts[1];

    final parts = provider.selectedStartTime.split(':').map(int.parse).toList();
    final initialTime = TimeOfDay(hour: parts[0], minute: parts[1]);
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: 'SELECT START TIME (CANTEEN $openStr - $closeStr)',
    );

    if (picked != null) {
      final startMin = picked.hour * 60 + picked.minute;
      final newStartStr = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';

      // 1. Block past times for today
      if (isToday && startMin < nowMin) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot select past time (${_format12Hour(newStartStr)}). Current time is ${_format12Hour('${now.hour}:${now.minute}')}.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 2. Validate operating hours boundary
      if (startMin < openMin || startMin >= closeMin) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Start time must be within canteen hours ($openStr - $closeStr).'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final endParts = provider.selectedEndTime.split(':').map(int.parse).toList();
      var endMin = endParts[0] * 60 + endParts[1];

      if (endMin <= startMin) {
        endMin = (startMin + 60 > closeMin) ? closeMin : startMin + 60;
      }

      final endH = (endMin ~/ 60).toString().padLeft(2, '0');
      final endM = (endMin % 60).toString().padLeft(2, '0');
      final newEndStr = '$endH:$endM';

      provider.setTimeRange(newStartStr, newEndStr);
      provider.fetchAvailableTables();
    }
  }

  Future<void> _selectEndTime(BuildContext context, TableReservationProvider provider) async {
    final response = provider.availabilityResponse;
    final closeStr = response?.closingTime ?? '17:00';
    final closeParts = closeStr.split(':').map(int.parse).toList();
    final closeMin = closeParts[0] * 60 + closeParts[1];

    final parts = provider.selectedEndTime.split(':').map(int.parse).toList();
    final initialTime = TimeOfDay(hour: parts[0], minute: parts[1]);
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: 'SELECT END TIME (CANTEEN 09:00 - $closeStr)',
    );

    if (picked != null) {
      final startParts = provider.selectedStartTime.split(':').map(int.parse).toList();
      final startMin = startParts[0] * 60 + startParts[1];
      final endMin = picked.hour * 60 + picked.minute;

      if (endMin <= startMin) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('End time must be after start time'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (endMin > closeMin) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('End time cannot exceed canteen closing time ($closeStr).'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final newEndStr = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      provider.setTimeRange(provider.selectedStartTime, newEndStr);
      provider.fetchAvailableTables();
    }
  }

  Widget _buildFiltersBar(BuildContext context, TableReservationProvider provider) {
    final durationHours = (provider.selectedDuration / 60.0).toStringAsFixed(1).replaceAll('.0', '');

    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Select Custom Time Range', style: AppTextStyles.titleSmall),
              Text(
                'Canteen Hours: 09:00 - 17:00',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Custom Range Selector Row (From -> To)
          Row(
            children: [
              // From Start Time Button
              Expanded(
                child: InkWell(
                  onTap: () => _selectStartTime(context, provider),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTint,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('FROM', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                              Text(
                                _format12Hour(provider.selectedStartTime),
                                style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 8),

              // To End Time Button
              Expanded(
                child: InkWell(
                  onTap: () => _selectEndTime(context, provider),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTint,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time_filled_rounded, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('TO', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                              Text(
                                _format12Hour(provider.selectedEndTime),
                                style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Duration Badge Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timelapse_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'Booked Duration: $durationHours Hour(s) (${provider.selectedStartTime} to ${provider.selectedEndTime})',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableSeatSelection(BuildContext context, TableReservationProvider provider) {
    final response = provider.availabilityResponse;
    if (response == null || response.tables.isEmpty) {
      return Center(
        child: Text('No tables available for selected time.', style: AppTextStyles.bodyMedium),
      );
    }

    final selectedTable = response.tables.firstWhere(
      (t) => t.tableId == provider.selectedTableId,
      orElse: () => response.tables.first,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (response.isCanteenOpen == false)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade700),
              ),
              child: Row(
                children: [
                  Icon(Icons.storefront_rounded, color: Colors.amber.shade700, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Canteen is Currently Closed',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade700, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Operating Hours: ${response.openingTime} to ${response.closingTime}. Showing table layout for preview.',
                          style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Text('Select Table', style: AppTextStyles.titleMedium),
          const SizedBox(height: 10),

          // Table Selector GridView (Non-horizontally scrolling)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.8,
            ),
            itemCount: response.tables.length,
            itemBuilder: (context, index) {
              final table = response.tables[index];
              final isSelected = table.tableId == provider.selectedTableId;
              return GestureDetector(
                onTap: () => provider.selectTable(table.tableId),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryTint : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 6, spreadRadius: 1)]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.table_restaurant_rounded,
                            size: 16,
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Table ${table.tableId}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${table.availableSeats.length}/${table.maxCapacity} free',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 10,
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Seat Map Header & Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Select Seats', style: AppTextStyles.titleMedium),
              Row(
                children: [
                  _buildLegend(AppColors.primary, 'Selected'),
                  const SizedBox(width: 8),
                  _buildLegend(AppColors.successTint, 'Available'),
                  const SizedBox(width: 8),
                  _buildLegend(Colors.grey.shade800, 'Reserved'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Interactive Seat Grid Layout
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  // Center Table Graphic
                  Container(
                    width: 140,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                    ),
                    child: Center(
                      child: Text(
                        'TABLE ${selectedTable.tableId}',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Seats Grid
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: List.generate(selectedTable.maxCapacity, (idx) {
                      final seatNum = idx + 1;
                      final isReserved = selectedTable.reservedSeatNumbers.contains(seatNum);
                      final isSelected = provider.selectedSeats.contains(seatNum);

                      const seatIcon = Icons.chair_rounded;

                      return GestureDetector(
                        onTap: isReserved ? null : () => provider.toggleSeatSelection(seatNum),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : isReserved
                                    ? Colors.grey.shade900
                                    : AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : isReserved
                                      ? Colors.grey.shade800
                                      : AppColors.success.withValues(alpha: 0.5),
                              width: 2,
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 1)]
                                : [],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isReserved ? Icons.lock_rounded : seatIcon,
                                size: 20,
                                color: isSelected
                                    ? Colors.black
                                    : isReserved
                                        ? Colors.grey.shade600
                                        : AppColors.success,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'S-$seatNum',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.black
                                      : isReserved
                                          ? Colors.grey.shade600
                                          : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Price & Deposit Breakdown Card
          if (selectedTable.costBreakdown != null)
            _buildCostBreakdownCard(selectedTable.costBreakdown!, provider.selectedSeats.length),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildCostBreakdownCard(CostBreakdown breakdown, int count) {
    final seatCount = count > 0 ? count : 1;
    final totalDeposit = breakdown.ratePerChair * seatCount * breakdown.durationMultiplier;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Deposit Breakdown', style: AppTextStyles.titleSmall),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Rate per Chair', style: AppTextStyles.bodySmall),
              Text('₹${breakdown.ratePerChair.toStringAsFixed(0)}', style: AppTextStyles.bodySmall),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Selected Chairs', style: AppTextStyles.bodySmall),
              Text('$count seats', style: AppTextStyles.bodySmall),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Duration Multiplier', style: AppTextStyles.bodySmall),
              Text('${breakdown.durationMultiplier}x', style: AppTextStyles.bodySmall),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Deposit Payable', style: AppTextStyles.titleSmall),
              Text(
                '₹${totalDeposit.toStringAsFixed(0)}',
                style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryTint.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Deposit is 100% credited to your cart order when you order food at your table!',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentMethodModal(BuildContext context, TableReservationProvider provider, double depositAmount) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                        child: Icon(Icons.payment_rounded, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Select Payment Method', style: AppTextStyles.titleMedium),
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
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Advance table & seat booking requires Razorpay Online Payment to lock your slot.',
                            style: AppTextStyles.bodySmall.copyWith(fontSize: 12, fontWeight: FontWeight.bold),
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
                      _showRazorpayCheckoutSheet(context, provider, depositAmount);
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
                          const Icon(Icons.payment_rounded, color: Colors.black, size: 24),
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
      },
    );
  }

  void _showRazorpayCheckoutSheet(BuildContext context, TableReservationProvider provider, double depositAmount) {
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
                  decoration: BoxDecoration(color: Colors.grey.shade700, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.blue.shade900, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.payment_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Razorpay Secure Payment', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.blue.shade900, borderRadius: BorderRadius.circular(4)),
                              child: const Text('GATEWAY', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        Text('100% Encrypted & Verified via Razorpay', style: AppTextStyles.bodySmall),
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
                    Text('Deposit Payable Amount', style: AppTextStyles.bodyMedium),
                    Text(
                      '₹${depositAmount.toStringAsFixed(0)}',
                      style: AppTextStyles.titleLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
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
                    Icon(Icons.qr_code_2_rounded, color: AppColors.primary, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('UPI Apps (Google Pay / PhonePe / Paytm)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text('Instant 1-tap checkout via UPI', style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
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
                    Icon(Icons.credit_card_rounded, color: AppColors.textSecondary, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Credit / Debit Card / NetBanking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text('Visa, MasterCard, RuPay, SBI, HDFC', style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
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
                  _executeReservation(context, provider, 'razorpay');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _executeReservation(BuildContext context, TableReservationProvider provider, String paymentMethod) async {
    final messenger = ScaffoldMessenger.of(context);
    final reservation = await provider.reserveSeats(paymentMethod: paymentMethod);
    if (!context.mounted) return;
    if (reservation != null) {
      _showReservationSuccessModal(context, reservation);
    } else if (provider.errorMessage != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.errorMessage!), backgroundColor: AppColors.error),
      );
    }
  }

  Widget _buildBottomCheckoutBar(BuildContext context, TableReservationProvider provider) {
    final response = provider.availabilityResponse;
    final selectedTable = response?.tables.firstWhere((t) => t.tableId == provider.selectedTableId);
    final rate = selectedTable?.costBreakdown?.ratePerChair ?? 50.0;
    final multiplier = selectedTable?.costBreakdown?.durationMultiplier ?? 1.0;
    final deposit = rate * provider.selectedSeats.length * multiplier;

    final isOpen = response?.isCanteenOpen ?? true;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${provider.selectedSeats.length} Seat(s) Selected', style: AppTextStyles.bodySmall),
                Text(
                  '₹${deposit.toStringAsFixed(0)} Deposit',
                  style: AppTextStyles.titleLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: CustomElevatedButton(
              text: !isOpen
                  ? 'Not Available Right Now'
                  : provider.isLoading
                      ? 'Reserving...'
                      : 'Confirm & Pay',
              loading: provider.isLoading,
              onPressed: !isOpen
                  ? null
                  : () => _showPaymentMethodModal(context, provider, deposit),
            ),
          ),
        ],
      ),
    );
  }
}

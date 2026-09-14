import '../../../core/app_exports.dart';
import '../provider/table_reservation_provider.dart';
import 'my_reservations_screen.dart';
import 'live_table_view_screen.dart';

// Extracted Sub-widgets
import 'widgets/reservation_time_filter_bar.dart';
import 'widgets/table_selector_grid.dart';
import 'widgets/seat_map_view.dart';
import 'widgets/reservation_cost_breakdown_card.dart';
import 'widgets/reservation_checkout_sheet.dart';

class TableReservationScreen extends StatefulWidget {
  final String? initialTableId;
  const TableReservationScreen({super.key, this.initialTableId});

  @override
  State<TableReservationScreen> createState() => _TableReservationScreenState();
}

class _TableReservationScreenState extends State<TableReservationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<TableReservationProvider>();
      await Future.wait([
        provider.fetchAvailableTables(),
        provider.fetchMyReservations(),
      ]);
      if (widget.initialTableId != null && mounted) {
        provider.selectTable(widget.initialTableId!);
      }
    });
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

  Future<void> _selectStartTime(
    BuildContext context,
    TableReservationProvider provider,
  ) async {
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
      final newStartStr =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';

      if (isToday && startMin < nowMin) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot select past time (${_format12Hour(newStartStr)}). Current time is ${_format12Hour('${now.hour}:${now.minute}')}.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (startMin < openMin || startMin >= closeMin) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Start time must be within canteen hours ($openStr - $closeStr).',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final endParts = provider.selectedEndTime
          .split(':')
          .map(int.parse)
          .toList();
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

  Future<void> _selectEndTime(
    BuildContext context,
    TableReservationProvider provider,
  ) async {
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
      final startParts = provider.selectedStartTime
          .split(':')
          .map(int.parse)
          .toList();
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
            content: Text(
              'End time cannot exceed canteen closing time ($closeStr).',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final newEndStr =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      provider.setTimeRange(provider.selectedStartTime, newEndStr);
      provider.fetchAvailableTables();
    }
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
            icon: const Icon(Icons.grid_view_rounded),
            tooltip: 'Live Table View',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LiveTableViewScreen()),
              );
            },
          ),
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
            // Modular Time Filter Bar
            ReservationTimeFilterBar(
              provider: provider,
              onSelectStartTime: () => _selectStartTime(context, provider),
              onSelectEndTime: () => _selectEndTime(context, provider),
            ),

            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            provider.errorMessage!,
                            style: AppTextStyles.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => provider.fetchAvailableTables(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _buildMainContent(context, provider),
            ),

            if (provider.selectedSeats.isNotEmpty)
              _buildBottomCheckoutBar(context, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    TableReservationProvider provider,
  ) {
    final response = provider.availabilityResponse;
    if (response == null || response.tables.isEmpty) {
      return Center(
        child: Text(
          'No tables available for selected time.',
          style: AppTextStyles.bodyMedium,
        ),
      );
    }

    final selectedTable = response.tables.firstWhere(
      (t) => t.tableId == provider.selectedTableId,
      orElse: () => response.tables.first,
    );

    final myActiveReservationsOnThisTable = provider.myReservations.where((r) {
      return r.tableId == selectedTable.tableId && r.isActiveSlot;
    }).toList();

    final Set<int> mySeatNumbersOnThisTable = {};
    for (var r in myActiveReservationsOnThisTable) {
      mySeatNumbersOnThisTable.addAll(r.seatNumbers);
    }
    final bool isMyActiveTable = mySeatNumbersOnThisTable.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  Icon(
                    Icons.storefront_rounded,
                    color: Colors.amber.shade700,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Canteen is Currently Closed',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade700,
                            fontSize: 13,
                          ),
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

          if (isMyActiveTable)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.indigo.shade400),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.bookmark_rounded,
                    color: Colors.indigo.shade400,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Active Session (Table ${selectedTable.tableId})',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo.shade300,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Seats ${mySeatNumbersOnThisTable.join(", ")} are currently yours. Tap any available seat to add a guest seat!',
                          style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Table Selector Grid Widget
          TableSelectorGrid(
            availabilityResponse: response,
            provider: provider,
          ),
          const SizedBox(height: 24),

          // Seat Map View Widget
          SeatMapView(
            selectedTable: selectedTable,
            provider: provider,
            mySeatNumbersOnThisTable: mySeatNumbersOnThisTable,
          ),
          const SizedBox(height: 24),

          // Cost Breakdown Card Widget
          if (selectedTable.costBreakdown != null)
            ReservationCostBreakdownCard(
              breakdown: selectedTable.costBreakdown!,
              count: provider.selectedSeats.length,
            ),
        ],
      ),
    );
  }

  Widget _buildBottomCheckoutBar(
    BuildContext context,
    TableReservationProvider provider,
  ) {
    final response = provider.availabilityResponse;
    final selectedTable = response?.tables.firstWhere(
      (t) => t.tableId == provider.selectedTableId,
    );
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
                Text(
                  '${provider.selectedSeats.length} Seat(s) Selected',
                  style: AppTextStyles.bodySmall,
                ),
                Text(
                  '₹${deposit.toStringAsFixed(0)} Deposit',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: CustomElevatedButton(
              text: !isOpen
                  ? 'Not Available'
                  : provider.isLoading
                  ? 'Reserving...'
                  : 'Confirm & Pay',
              loading: provider.isLoading,
              onPressed: !isOpen
                  ? null
                  : () => ReservationCheckoutSheet.showPaymentMethodModal(
                        context,
                        provider,
                        deposit,
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

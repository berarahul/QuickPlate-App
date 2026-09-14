import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/live_table_overview_model.dart';
import '../provider/table_reservation_provider.dart';
import 'live_reservation_countdown.dart';
import '../../scan/provider/scan_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_animations.dart';
import '../../../core/widgets/canteen_flow_guide_card.dart';

// Extracted Sub-widgets
import 'widgets/live_table_summary_cards.dart';
import 'widgets/live_table_floor_canvas.dart';
import 'widgets/live_table_seat_details_sheet.dart';

class LiveTableViewScreen extends StatefulWidget {
  const LiveTableViewScreen({super.key});

  @override
  State<LiveTableViewScreen> createState() => _LiveTableViewScreenState();
}

class _LiveTableViewScreenState extends State<LiveTableViewScreen> {
  final String _selectedFilter = 'ALL';
  bool _isFloorView = true;
  String _selectedFloor = 'Canteen - Floor 1';
  LiveTableOverviewModel? _selectedTableForDetail;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchLiveOverview();
      }
    });
  }

  Future<void> _fetchLiveOverview() async {
    if (!mounted) return;
    final provider = context.read<TableReservationProvider>();
    await provider.fetchLiveTablesOverview();
    await provider.fetchMyReservations();
  }

  void _showTableDetailBottomSheet(
      BuildContext context, LiveTableOverviewModel table) {
    setState(() {
      _selectedTableForDetail = table;
    });
    LiveTableSeatDetailsSheet.show(context, table);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            AppPulseAnimation(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.greenAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Live Canteen Tables',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Live Status',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchLiveOverview,
          ),
        ],
      ),
      body: Consumer<TableReservationProvider>(
        builder: (context, provider, child) {
          if (provider.isLiveTablesLoading && provider.liveTables.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final liveTables = provider.liveTables;
          if (liveTables.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.table_restaurant_outlined,
                    size: 64,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tables found in canteen.',
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _fetchLiveOverview,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }

          final int targetFloor = _selectedFloor.contains('2')
              ? 2
              : (_selectedFloor.contains('3') ? 3 : 1);

          final floorTables =
              liveTables.where((t) => t.floorNumber == targetFloor).toList();
          final currentFloorTables = (floorTables.isEmpty && targetFloor == 1)
              ? liveTables
              : floorTables;

          final availableCount =
              currentFloorTables.where((t) => t.status == 'AVAILABLE').length;
          final partialCount = currentFloorTables
              .where((t) => t.status == 'PARTIALLY_OCCUPIED')
              .length;
          final fullCount =
              currentFloorTables.where((t) => t.status == 'FULL').length;
          final blockedCount =
              currentFloorTables.where((t) => t.status == 'BLOCKED').length;

          final filteredTables = currentFloorTables.where((t) {
            if (_selectedFilter == 'AVAILABLE') return t.status == 'AVAILABLE';
            if (_selectedFilter == 'PARTIAL') {
              return t.status == 'PARTIALLY_OCCUPIED';
            }
            if (_selectedFilter == 'FULL') return t.status == 'FULL';
            if (_selectedFilter == 'BLOCKED') return t.status == 'BLOCKED';
            return true;
          }).toList();

          return RefreshIndicator(
            onRefresh: _fetchLiveOverview,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CanteenFlowGuideCard(),

                        // Active Reservation Banner
                        if (provider.myReservations.any((r) => r.isActiveSlot)) ...[
                          _buildActiveReservationBanner(provider),
                          const SizedBox(height: 14),
                        ],

                        // Extracted Top Stat Summary Cards
                        LiveTableSummaryCards(
                          availableCount: availableCount,
                          partialCount: partialCount,
                          fullCount: fullCount,
                          blockedCount: blockedCount,
                        ),
                        const SizedBox(height: 14),

                        // Floor Container Card
                        _buildFloorContainer(filteredTables),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveReservationBanner(TableReservationProvider provider) {
    final activeRes = provider.myReservations.firstWhere(
      (r) => r.isActiveSlot,
    );
    final isCheckedIn =
        activeRes.reservationStatus.toLowerCase() == 'checked_in';
    final isCheckInOpen = activeRes.isSlotActiveNow && !isCheckedIn;
    final titleText = isCheckedIn
        ? 'My Active Table Session: Table ${activeRes.tableId}'
        : (isCheckInOpen
            ? 'Check-In Open: Table ${activeRes.tableId}'
            : 'Upcoming Booking: Table ${activeRes.tableId}');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.bookmark_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleText,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LiveReservationCountdown(
                      startTime: activeRes.startTime,
                      endTime: activeRes.endTime,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              icon: const Icon(Icons.exit_to_app_rounded, size: 16),
              label: const Text(
                'End Table Session & Free Chairs',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                final scanProvider = context.read<ScanProvider>();
                final res = await scanProvider.leaveTableSession();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res.message),
                      backgroundColor:
                          res.success ? AppColors.success : AppColors.error,
                    ),
                  );
                  _fetchLiveOverview();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloorContainer(List<LiveTableOverviewModel> tables) {
    final isDark = AppColors.isDarkMode;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Floor Selector Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedFloor,
                      isDense: true,
                      dropdownColor: AppColors.surface,
                      icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textPrimary),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedFloor = val;
                          });
                        }
                      },
                      items: [
                        DropdownMenuItem(
                          value: 'Canteen - Floor 1',
                          child: Row(
                            children: [
                              Icon(Icons.map_outlined, size: 15, color: AppColors.textPrimary),
                              const SizedBox(width: 6),
                              Text('Canteen - Floor 1', style: TextStyle(color: AppColors.textPrimary)),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Canteen - Floor 2',
                          child: Row(
                            children: [
                              Icon(Icons.map_outlined, size: 15, color: AppColors.textPrimary),
                              const SizedBox(width: 6),
                              Text('Canteen - Floor 2', style: TextStyle(color: AppColors.textPrimary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // View Switcher Pill
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _isFloorView = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isFloorView ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.grid_view_rounded,
                                size: 14,
                                color: _isFloorView ? Colors.white : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Floor View',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _isFloorView ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _isFloorView = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: !_isFloorView ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.format_list_bulleted_rounded,
                                size: 14,
                                color: !_isFloorView ? Colors.white : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'List View',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: !_isFloorView ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, thickness: 1, color: AppColors.border),

          // Modular Floor Canvas Widget
          LiveTableFloorCanvas(
            tables: tables,
            selectedFloor: _selectedFloor,
            isFloorView: _isFloorView,
            selectedTableForDetail: _selectedTableForDetail,
            onTableSelected: (LiveTableOverviewModel t) => _showTableDetailBottomSheet(context, t),
            onRefresh: _fetchLiveOverview,
          ),
        ],
      ),
    );
  }
}

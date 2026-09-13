import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/live_table_overview_model.dart';
import '../provider/table_reservation_provider.dart';
import '../../table_reservation/views/table_reservation_screen.dart';
import 'live_reservation_countdown.dart';
import '../../scan/provider/scan_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_animations.dart';
import '../../../core/widgets/canteen_flow_guide_card.dart';

class LiveTableViewScreen extends StatefulWidget {
  const LiveTableViewScreen({super.key});

  @override
  State<LiveTableViewScreen> createState() => _LiveTableViewScreenState();
}

class _LiveTableViewScreenState extends State<LiveTableViewScreen> {
  String _selectedFilter = 'ALL'; // ALL, AVAILABLE, PARTIAL, FULL, BLOCKED

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

          final availableCount =
              liveTables.where((t) => t.status == 'AVAILABLE').length;
          final partialCount =
              liveTables.where((t) => t.status == 'PARTIALLY_OCCUPIED').length;
          final fullCount =
              liveTables.where((t) => t.status == 'FULL').length;
          final blockedCount =
              liveTables.where((t) => t.status == 'BLOCKED').length;

          final filteredTables = liveTables.where((t) {
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CanteenFlowGuideCard(),
                  // Active Reservation Banner with Live Countdown Timer
                  if (provider.myReservations.any((r) => r.isActiveSlot)) ...[
                    Builder(
                      builder: (context) {
                        final activeRes = provider.myReservations.firstWhere(
                          (r) => r.isActiveSlot,
                        );
                        final isCheckedIn = activeRes.reservationStatus.toLowerCase() == 'checked_in';
                        final isCheckInOpen = activeRes.isSlotActiveNow && !isCheckedIn;
                        final titleText = isCheckedIn
                            ? 'My Active Table Session: Table ${activeRes.tableId}'
                            : (isCheckInOpen
                                ? 'Check-In Open: Table ${activeRes.tableId}'
                                : 'Upcoming Booking: Table ${activeRes.tableId}');

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
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
                                    child: Icon(Icons.bookmark_rounded, color: AppColors.primary, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          titleText,
                                          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
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
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                  icon: const Icon(Icons.exit_to_app_rounded, size: 16),
                                  label: const Text(
                                    'End Table Session & Free Chairs',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: () async {
                                    final scanProvider = context.read<ScanProvider>();
                                    final res = await scanProvider.leaveTableSession();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(res.message),
                                          backgroundColor: res.success ? AppColors.success : AppColors.error,
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
                      },
                    ),
                  ],

                  // Real-time Overview Banner
                  _buildSummaryBanner(
                    total: liveTables.length,
                    available: availableCount,
                    partial: partialCount,
                    full: fullCount,
                    blocked: blockedCount,
                  ),
                  const SizedBox(height: 16),


                  // Filter Chips
                  _buildFilterChips(),
                  const SizedBox(height: 16),

                  // Section Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Canteen Floor Layout (${filteredTables.length})',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.sync_rounded,
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Pull to refresh',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textTertiary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Tables List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredTables.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final table = filteredTables[index];
                      return AppFadeInSlide(
                        delay: Duration(milliseconds: index * 40),
                        child: _TableLiveCard(table: table),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryBanner({
    required int total,
    required int available,
    required int partial,
    required int full,
    required int blocked,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.grid_view_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Live Canteen Status Summary',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$total Tables',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildStatBox('Available', '$available', Colors.green),
              const SizedBox(width: 8),
              _buildStatBox('Partially Free', '$partial', Colors.orange.shade800),
              const SizedBox(width: 8),
              _buildStatBox('Full', '$full', Colors.red.shade700),
              const SizedBox(width: 8),
              _buildStatBox('Blocked', '$blocked', Colors.grey.shade700),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      ('ALL', 'All Tables'),
      ('AVAILABLE', 'Available'),
      ('PARTIAL', 'Partially Occupied'),
      ('FULL', 'Full'),
      ('BLOCKED', 'Blocked'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f.$2),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedFilter = f.$1;
                  });
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TableLiveCard extends StatelessWidget {
  final LiveTableOverviewModel table;

  const _TableLiveCard({required this.table});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (table.status) {
      case 'AVAILABLE':
        statusColor = Colors.green;
        statusText = 'AVAILABLE (${table.availableCount}/${table.maxCapacity} Free)';
        statusIcon = Icons.check_circle_outline_rounded;
        break;
      case 'PARTIALLY_OCCUPIED':
        statusColor = Colors.orange.shade800;
        statusText = 'PARTIALLY OCCUPIED (${table.availableCount}/${table.maxCapacity} Free)';
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case 'FULL':
        statusColor = Colors.red.shade700;
        statusText = 'FULL (0/${table.maxCapacity} Free)';
        statusIcon = Icons.remove_circle_outline_rounded;
        break;
      case 'BLOCKED':
      default:
        statusColor = Colors.grey.shade700;
        statusText = 'BLOCKED / MAINTENANCE';
        statusIcon = Icons.block_rounded;
        break;
    }

    final scanProvider = context.watch<ScanProvider>();
    final activeSession = scanProvider.sessionResponse?.data?.session;
    final isMyActiveSessionTable = activeSession != null &&
        activeSession.isActive == true &&
        activeSession.tableId == table.tableId;

    final isMyReservationTable = context.watch<TableReservationProvider>().myReservations.any(
      (r) => r.isActiveSlot && r.tableId == table.tableId && (r.isSlotActiveNow || r.reservationStatus.toLowerCase() == 'checked_in'),
    );

    final isMyTable = isMyActiveSessionTable || isMyReservationTable;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Table ID & Status Badge & Leave Session Corner Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.table_restaurant_rounded, color: statusColor, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Table ${table.tableId}',
                      style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Capacity: ${table.maxCapacity} Chairs',
                      style: AppTextStyles.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isMyTable) ...[
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: const Size(0, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.exit_to_app_rounded, size: 13),
                      label: const Text('Leave Session', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        final res = await scanProvider.leaveTableSession();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(res.message),
                              backgroundColor: res.success ? AppColors.success : AppColors.error,
                            ),
                          );
                          context.read<TableReservationProvider>().fetchLiveTablesOverview();
                          context.read<TableReservationProvider>().fetchMyReservations();
                        }
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
          const Divider(height: 20),

          // Chair Visualization Row
          Text(
            'Live Chair Occupancy:',
            style: AppTextStyles.labelSmall.copyWith(fontSize: 11),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: table.chairDetails.map((chair) {
              final isOccupied = chair.isOccupied;
              final numMatch = RegExp(r'\d+').firstMatch(chair.chairId)?.group(0);
              final chairNum = numMatch != null ? int.tryParse(numMatch) : null;
              final isMySeat = chairNum != null &&
                  context.read<TableReservationProvider>().myReservations.any((r) =>
                      r.isActiveSlot &&
                      r.tableId == table.tableId &&
                      r.seatNumbers.contains(chairNum));

              final Color cColor = isMySeat
                  ? Colors.indigo.shade800
                  : (isOccupied ? Colors.red.shade700 : Colors.green.shade700);
              final Color cBg = isMySeat
                  ? Colors.indigo.shade50
                  : (isOccupied ? Colors.red.shade50 : Colors.green.shade50);
              final String occUser = (chair.userName != null && chair.userName!.trim().isNotEmpty)
                  ? chair.userName!
                  : 'Occupied';
              final String labelText = isMySeat
                  ? '(Your Seat)'
                  : (isOccupied ? '($occUser)' : '(Free)');
              final IconData iconData = isMySeat
                  ? Icons.bookmark_rounded
                  : (isOccupied ? Icons.person_rounded : Icons.event_seat_rounded);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: cBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: cColor.withValues(alpha: isMySeat ? 0.8 : 0.4), width: isMySeat ? 1.5 : 1.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      iconData,
                      size: 14,
                      color: cColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      chair.chairId,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: cColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      labelText,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: isMySeat ? FontWeight.bold : FontWeight.w500,
                        color: cColor,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Action Button if available
          if (table.status != 'BLOCKED' && table.availableCount > 0)
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => TableReservationScreen(initialTableId: table.tableId),
                    ),
                  );
                },
                icon: const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.white),
                label: Text(
                  'Reserve Table ${table.tableId}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

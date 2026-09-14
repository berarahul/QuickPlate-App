import '../../../../core/app_exports.dart';
import '../../models/live_table_overview_model.dart';
import '../../../scan/provider/scan_provider.dart';
import '../../provider/table_reservation_provider.dart';

class LiveTableFloorCanvas extends StatelessWidget {
  final List<LiveTableOverviewModel> tables;
  final String selectedFloor;
  final bool isFloorView;
  final LiveTableOverviewModel? selectedTableForDetail;
  final Function(LiveTableOverviewModel) onTableSelected;
  final VoidCallback onRefresh;

  const LiveTableFloorCanvas({
    super.key,
    required this.tables,
    required this.selectedFloor,
    required this.isFloorView,
    required this.selectedTableForDetail,
    required this.onTableSelected,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return isFloorView
        ? _buildFloorMapCanvas(context)
        : _buildListViewContainer(context);
  }

  Widget _buildFloorMapCanvas(BuildContext context) {
    final isDark = AppColors.isDarkMode;
    final floorBg = isDark ? const Color(0xFF141210) : const Color(0xFFF4F0E8);
    final borderAccent = isDark ? const Color(0xFF292524) : const Color(0xFFE5DAC7);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: floorBg,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 8,
            child: Container(color: borderAccent),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 8,
            child: Container(color: borderAccent),
          ),
          Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_upward_rounded, size: 16, color: AppColors.textPrimary),
                        const SizedBox(height: 4),
                        RotatedBox(
                          quarterTurns: 3,
                          child: Text(
                            'Entrance',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: tables.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.table_restaurant_outlined,
                                    color: AppColors.textTertiary, size: 32),
                                const SizedBox(height: 8),
                                Text(
                                  'No tables on $selectedFloor',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Admin can add tables for Floor 2 in Admin Panel.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.85,
                            ),
                            itemCount: tables.length,
                            itemBuilder: (context, index) {
                              final table = tables[index];
                              final isSelected =
                                  selectedTableForDetail?.tableId == table.tableId;
                              return _VisualTableWidget(
                                table: table,
                                isSelected: isSelected,
                                onTap: () => onTableSelected(table),
                              );
                            },
                          ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 34,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant_menu_rounded, size: 18, color: AppColors.textPrimary),
                        const SizedBox(height: 4),
                        RotatedBox(
                          quarterTurns: 1,
                          child: Text(
                            'Kitchen',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 2,
            left: 36,
            child: Icon(Icons.park_rounded, color: Colors.green.shade700, size: 16),
          ),
          Positioned(
            top: 2,
            right: 38,
            child: Icon(Icons.park_rounded, color: Colors.green.shade700, size: 16),
          ),
          Positioned(
            bottom: 2,
            left: 36,
            child: Icon(Icons.park_rounded, color: Colors.green.shade700, size: 16),
          ),
          Positioned(
            bottom: 2,
            right: 38,
            child: Icon(Icons.park_rounded, color: Colors.green.shade700, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildListViewContainer(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: tables.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final table = tables[index];
        return _TableLiveCard(
          table: table,
          onTap: () => onTableSelected(table),
          onRefresh: onRefresh,
        );
      },
    );
  }
}

class _VisualTableWidget extends StatelessWidget {
  final LiveTableOverviewModel table;
  final bool isSelected;
  final VoidCallback onTap;

  const _VisualTableWidget({
    required this.table,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode;
    Color statusColor;
    String badgeText;
    Color badgeBgColor;

    switch (table.status) {
      case 'AVAILABLE':
        statusColor = const Color(0xFF28A745);
        badgeText = '${table.availableCount}/${table.maxCapacity} Free';
        badgeBgColor = isDark ? statusColor.withValues(alpha: 0.15) : const Color(0xFFE8F7ED);
        break;
      case 'PARTIALLY_OCCUPIED':
        statusColor = const Color(0xFFFD7E14);
        badgeText = '${table.availableCount}/${table.maxCapacity} Free';
        badgeBgColor = isDark ? statusColor.withValues(alpha: 0.15) : const Color(0xFFFFF4E5);
        break;
      case 'FULL':
        statusColor = const Color(0xFFDC3545);
        badgeText = 'Full';
        badgeBgColor = isDark ? statusColor.withValues(alpha: 0.15) : const Color(0xFFFDE8E8);
        break;
      case 'BLOCKED':
      default:
        statusColor = const Color(0xFF6C757D);
        badgeText = 'Blocked';
        badgeBgColor = isDark ? statusColor.withValues(alpha: 0.15) : const Color(0xFFF3F4F6);
        break;
    }

    final chairs = table.chairDetails;
    Color chair1Color = _getChairColor(table, chairs, 0);
    Color chair2Color = _getChairColor(table, chairs, 1);
    Color chair3Color = _getChairColor(table, chairs, 2);
    Color chair4Color = _getChairColor(table, chairs, 3);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9A774),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFB8824D), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        table.tableId.startsWith('T')
                            ? table.tableId
                            : 'T${table.tableId}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF4A2E12),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    child: _buildVisualChair(chair1Color, isVertical: true),
                  ),
                  Positioned(
                    bottom: 0,
                    child: _buildVisualChair(chair2Color, isVertical: true),
                  ),
                  Positioned(
                    left: 0,
                    child: _buildVisualChair(chair3Color, isVertical: false),
                  ),
                  Positioned(
                    right: 0,
                    child: _buildVisualChair(chair4Color, isVertical: false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeBgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getChairColor(
      LiveTableOverviewModel table, List<LiveChairDetail> chairs, int index) {
    if (table.status == 'BLOCKED') {
      return const Color(0xFF6C757D);
    }
    if (chairs.length > index) {
      return chairs[index].isOccupied
          ? const Color(0xFFFD7E14)
          : const Color(0xFF28A745);
    }
    if (index < table.occupiedCount) {
      return const Color(0xFFFD7E14);
    }
    return const Color(0xFF28A745);
  }

  Widget _buildVisualChair(Color color, {required bool isVertical}) {
    return Container(
      width: isVertical ? 16 : 10,
      height: isVertical ? 10 : 16,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 2,
          ),
        ],
      ),
    );
  }
}

class _TableLiveCard extends StatelessWidget {
  final LiveTableOverviewModel table;
  final VoidCallback onTap;
  final VoidCallback onRefresh;

  const _TableLiveCard({
    required this.table,
    required this.onTap,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (table.status) {
      case 'AVAILABLE':
        statusColor = const Color(0xFF28A745);
        statusText =
            'AVAILABLE (${table.availableCount}/${table.maxCapacity} Free)';
        statusIcon = Icons.check_circle_outline_rounded;
        break;
      case 'PARTIALLY_OCCUPIED':
        statusColor = const Color(0xFFFD7E14);
        statusText =
            'PARTIALLY OCCUPIED (${table.availableCount}/${table.maxCapacity} Free)';
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case 'FULL':
        statusColor = const Color(0xFFDC3545);
        statusText = 'FULL (0/${table.maxCapacity} Free)';
        statusIcon = Icons.remove_circle_outline_rounded;
        break;
      case 'BLOCKED':
      default:
        statusColor = const Color(0xFF6C757D);
        statusText = 'BLOCKED / MAINTENANCE';
        statusIcon = Icons.block_rounded;
        break;
    }

    final scanProvider = context.watch<ScanProvider>();
    final activeSession = scanProvider.sessionResponse?.data?.session;
    final isMyActiveSessionTable = activeSession != null &&
        activeSession.isActive == true &&
        activeSession.tableId == table.tableId;

    final isMyReservationTable =
        context.watch<TableReservationProvider>().myReservations.any(
              (r) =>
                  r.isActiveSlot &&
                  r.tableId == table.tableId &&
                  (r.isSlotActiveNow ||
                      r.reservationStatus.toLowerCase() == 'checked_in'),
            );

    final isMyTable = isMyActiveSessionTable || isMyReservationTable;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: statusColor.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: statusColor.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.table_restaurant_rounded,
                      color: statusColor, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Table ${table.tableId}',
                        style: AppTextStyles.titleMedium
                            .copyWith(fontWeight: FontWeight.bold),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: statusColor.withValues(alpha: 0.3)),
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
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: const Size(0, 28),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.exit_to_app_rounded, size: 13),
                        label: const Text('Leave Session',
                            style: TextStyle(
                                fontSize: 10.5, fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          final res = await scanProvider.leaveTableSession();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(res.message),
                                backgroundColor: res.success
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            );
                            onRefresh();
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

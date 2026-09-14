import '../../../../core/app_exports.dart';
import '../../models/live_table_overview_model.dart';
import '../table_reservation_screen.dart';

class LiveTableSeatDetailsSheet {
  static void show(BuildContext context, LiveTableOverviewModel table) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = AppColors.isDarkMode;
        Color statusColor;
        String statusLabel;
        Color statusBgColor;

        switch (table.status) {
          case 'AVAILABLE':
            statusColor = const Color(0xFF28A745);
            statusLabel = 'Available\n${table.availableCount}/${table.maxCapacity} seats free';
            statusBgColor = isDark ? statusColor.withValues(alpha: 0.15) : const Color(0xFFE8F7ED);
            break;
          case 'PARTIALLY_OCCUPIED':
            statusColor = const Color(0xFFFD7E14);
            statusLabel = 'Partially Free\n${table.availableCount}/${table.maxCapacity} seats free';
            statusBgColor = isDark ? statusColor.withValues(alpha: 0.15) : const Color(0xFFFFF4E5);
            break;
          case 'FULL':
            statusColor = const Color(0xFFDC3545);
            statusLabel = 'Full\n0/${table.maxCapacity} seats free';
            statusBgColor = isDark ? statusColor.withValues(alpha: 0.15) : const Color(0xFFFDE8E8);
            break;
          case 'BLOCKED':
          default:
            statusColor = const Color(0xFF6C757D);
            statusLabel = 'Blocked / Maintenance';
            statusBgColor = isDark ? statusColor.withValues(alpha: 0.15) : const Color(0xFFF3F4F6);
            break;
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: High-Res Visual Table Graphic
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFD9A774),
                              border: Border.all(color: const Color(0xFFB8824D), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 2,
                            child: Container(
                              width: 14,
                              height: 10,
                              decoration: BoxDecoration(
                                color: table.chairDetails.isNotEmpty && table.chairDetails[0].isOccupied
                                    ? const Color(0xFFFD7E14)
                                    : const Color(0xFF28A745),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 2,
                            child: Container(
                              width: 14,
                              height: 10,
                              decoration: BoxDecoration(
                                color: table.chairDetails.length > 1 && table.chairDetails[1].isOccupied
                                    ? const Color(0xFFFD7E14)
                                    : const Color(0xFF28A745),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 2,
                            child: Container(
                              width: 10,
                              height: 14,
                              decoration: BoxDecoration(
                                color: table.chairDetails.length > 2 && table.chairDetails[2].isOccupied
                                    ? const Color(0xFFFD7E14)
                                    : const Color(0xFF28A745),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 2,
                            child: Container(
                              width: 10,
                              height: 14,
                              decoration: BoxDecoration(
                                color: table.chairDetails.length > 3 && table.chairDetails[3].isOccupied
                                    ? const Color(0xFFFD7E14)
                                    : const Color(0xFF28A745),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Middle: Table Title & Capacity & Status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Table ${table.tableId}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.people_alt_outlined, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              'Capacity: ${table.maxCapacity} Chairs',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Status Pill & Close Button
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(sheetContext),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Chairs List Row
              Text(
                'Chairs:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: table.chairDetails.map((chair) {
                  final isOccupied = chair.isOccupied;
                  final Color cColor = isOccupied ? const Color(0xFFFD7E14) : const Color(0xFF28A745);
                  final Color cBg = isDark
                      ? cColor.withValues(alpha: 0.15)
                      : (isOccupied ? const Color(0xFFFFF4E5) : const Color(0xFFE8F7ED));
                  final String chairName = chair.chairId.startsWith('Chair') ? chair.chairId : 'Chair ${chair.chairId}';

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: cColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_seat_rounded, size: 13, color: cColor),
                        const SizedBox(width: 4),
                        Text(
                          '$chairName ${isOccupied ? "Occupied" : "Free"}',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: cColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // Action Reserve Button
              if (table.status != 'BLOCKED' && table.availableCount > 0)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => TableReservationScreen(initialTableId: table.tableId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.calendar_month_rounded, size: 18, color: Colors.white),
                    label: Text(
                      'Reserve Table ${table.tableId}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}

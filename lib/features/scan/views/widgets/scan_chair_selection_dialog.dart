import '../../../../core/app_exports.dart';
import '../../provider/scan_provider.dart';
import '../../../table_reservation/models/table_reservation_model.dart';

class ScanChairSelectionDialog {
  static Future<bool> showAdvanceCheckInDialog(
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

  static Future<List<String>?> showChairSelectionDialog(
    BuildContext context,
    ScanProvider scanProvider,
    String tableId,
  ) async {
    final details = await scanProvider.fetchOccupiedChairsDetails(tableId);
    final occupied = details.occupiedChairs;

    final myCurrentSession = scanProvider.sessionResponse?.data?.session;
    final myExistingChairs = (myCurrentSession != null && myCurrentSession.tableId == tableId)
        ? (myCurrentSession.chairIds ?? [])
        : <String>[];

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

    if (!context.mounted) return null;

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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        hasExistingChairs
                            ? 'Add ${selected.join(", ")} to Table $tableId'
                            : 'Join Table $tableId (${selected.join(", ")})',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
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
}

import '../../../../core/app_exports.dart';

class LiveTableSummaryCards extends StatelessWidget {
  final int availableCount;
  final int partialCount;
  final int fullCount;
  final int blockedCount;

  const LiveTableSummaryCards({
    super.key,
    required this.availableCount,
    required this.partialCount,
    required this.fullCount,
    required this.blockedCount,
  });

  Widget _buildStatCard({
    required int count,
    required String label,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required IconData icon,
  }) {
    final isDark = AppColors.isDarkMode;
    final effectiveBg = isDark ? color.withValues(alpha: 0.12) : bgColor;
    final effectiveBorder = isDark ? color.withValues(alpha: 0.3) : borderColor;
    final effectiveText = isDark ? AppColors.textPrimary : color.withValues(alpha: 0.9);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface : effectiveBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: effectiveBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: effectiveText,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            Icon(icon, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _buildStatCard(
              count: availableCount,
              label: 'Available',
              color: const Color(0xFF28A745),
              bgColor: const Color(0xFFE8F7ED),
              borderColor: const Color(0xFFA3E6B4),
              icon: Icons.table_restaurant_rounded,
            ),
            const SizedBox(width: 8),
            _buildStatCard(
              count: partialCount,
              label: 'Partially Occupied',
              color: const Color(0xFFFD7E14),
              bgColor: const Color(0xFFFFF4E5),
              borderColor: const Color(0xFFFFD8A8),
              icon: Icons.table_restaurant_rounded,
            ),
            const SizedBox(width: 8),
            _buildStatCard(
              count: fullCount,
              label: 'Full',
              color: const Color(0xFFDC3545),
              bgColor: const Color(0xFFFDE8E8),
              borderColor: const Color(0xFFFCA5A5),
              icon: Icons.groups_rounded,
            ),
            const SizedBox(width: 8),
            _buildStatCard(
              count: blockedCount,
              label: 'Blocked',
              color: const Color(0xFF6C757D),
              bgColor: const Color(0xFFF3F4F6),
              borderColor: const Color(0xFFD1D5DB),
              icon: Icons.block_rounded,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem('Free', const Color(0xFF28A745)),
            _buildLegendItem('Occupied (Partial)', const Color(0xFFFD7E14)),
            _buildLegendItem('Full', const Color(0xFFDC3545)),
            _buildLegendItem('Blocked', const Color(0xFF6C757D)),
          ],
        ),
      ],
    );
  }
}

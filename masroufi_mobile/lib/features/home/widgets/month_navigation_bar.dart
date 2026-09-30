import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/state/app_state.dart';

class MonthNavigationBar extends StatelessWidget {
  final bool showAllOption;
  final bool isAllSelected;
  final VoidCallback? onToggleAll;

  const MonthNavigationBar({
    super.key,
    this.showAllOption = false,
    this.isAllSelected = false,
    this.onToggleAll,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).cardColor;
    final borderColor = Theme.of(context).dividerColor;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    final isCurrentMonth = AppState.instance.isCurrentMonth;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          // Previous Month Button (in RTL, Right chevron goes backwards in time)
          IconButton(
            tooltip: 'الشهر السابق',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.chevron_right, size: 22),
            onPressed: isAllSelected ? null : () => AppState.instance.previousMonth(),
          ),

          // Center: Month or All Months Display with FittedBox to prevent any overflow
          Expanded(
            child: GestureDetector(
              onTap: isAllSelected ? null : () => AppState.instance.resetToCurrentMonth(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: !isAllSelected && isCurrentMonth
                      ? AppTheme.primary.withValues(alpha: 0.12)
                      : (isAllSelected
                          ? AppTheme.accentGold.withValues(alpha: 0.12)
                          : Colors.transparent),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAllSelected ? Icons.all_inbox_rounded : Icons.calendar_today_outlined,
                        size: 15,
                        color: isAllSelected
                            ? AppTheme.accentGold
                            : (!isAllSelected && isCurrentMonth ? AppTheme.primary : textSecondary),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isAllSelected ? 'جميع المعاملات (كل الشهور)' : AppState.instance.selectedMonthName,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isAllSelected
                              ? AppTheme.accentGold
                              : (!isAllSelected && isCurrentMonth ? AppTheme.primary : textPrimary),
                        ),
                      ),
                      if (!isAllSelected && isCurrentMonth) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'الحالي',
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Next Month Button or Toggle All
          if (showAllOption && onToggleAll != null)
            IconButton(
              tooltip: isAllSelected ? 'عرض بالشهر' : 'عرض الكل',
              visualDensity: VisualDensity.compact,
              icon: Icon(
                isAllSelected ? Icons.filter_list_off_rounded : Icons.all_inbox_rounded,
                size: 20,
                color: isAllSelected ? AppTheme.accentGold : textSecondary,
              ),
              onPressed: onToggleAll,
            ),
          IconButton(
            tooltip: 'الشهر القادم',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.chevron_left, size: 22),
            onPressed: isAllSelected ? null : () => AppState.instance.nextMonth(),
          ),
        ],
      ),
    );
  }
}

import '../home/widgets/month_navigation_bar.dart';
import '../help/screen_help_sheet.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/state/app_state.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final surfaceColor = Theme.of(context).cardColor;
        final borderColor = Theme.of(context).dividerColor;
        final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
        final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

        final budgets = AppState.instance.getBudgets();
        final categoryBreakdown = AppState.instance.getCategoryBreakdown();

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: SafeArea(
              child: ListView(
                padding: EdgeInsets.only(left: 20, right: 20, top: 14, bottom: MediaQuery.of(context).padding.bottom + 80),
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'التحليلات والميزانية',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.help_outline_rounded, size: 21),
                        color: textSecondary,
                        visualDensity: VisualDensity.compact,
                        tooltip: 'دليل شاشة التحليلات',
                        onPressed: () => ScreenHelpSheet.show(context, ScreenHelpType.analytics),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const MonthNavigationBar(),
                  const SizedBox(height: 14),

                  // Budgets Section Title & Manage Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'متابعة بنود الميزانية',
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      InkWell(
                        onTap: () => _showManageBudgetsSheet(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.tune_rounded, size: 14, color: AppTheme.primary),
                              const SizedBox(width: 4),
                              Text(
                                'تعديل الميزانيات',
                                style: GoogleFonts.cairo(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (budgets.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'لم يتم تحديد أي بنود للميزانية بعد',
                            style: GoogleFonts.cairo(fontSize: 12.5, color: textSecondary),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: () => AppState.instance.resetBudgetsToDefault(),
                            icon: const Icon(Icons.restore_rounded, size: 16),
                            label: Text(
                              'استعادة البنود الافتراضية',
                              style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    ...budgets.map((b) {
                      return InkWell(
                        onTap: () => _showEditSingleBudgetDialog(context, b.name, b.limit),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        b.name,
                                        style: GoogleFonts.cairo(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.bold,
                                          color: textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(Icons.edit_outlined, size: 14, color: textSecondary.withValues(alpha: 0.6)),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: b.statusColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      b.status,
                                      style: GoogleFonts.cairo(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: b.statusColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'المصروف: ${b.spent.toStringAsFixed(3)} د.ل',
                                    style: GoogleFonts.cairo(fontSize: 11.5, color: textSecondary),
                                  ),
                                  Text(
                                    'الحد: ${b.limit.toStringAsFixed(3)} د.ل',
                                    style: GoogleFonts.cairo(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.accentGold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: LinearProgressIndicator(
                                  value: b.ratio,
                                  minHeight: 6,
                                  backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                                  valueColor: AlwaysStoppedAnimation<Color>(b.statusColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 14),

                  // Category Breakdown Section
                  Text(
                    'توزيع الصرف حسب الفئة',
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (categoryBreakdown.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderColor),
                      ),
                      child: Center(
                        child: Text(
                          'لا توجد مصاريف استهلاكية مسجلة لهذا الشهر حتى الآن',
                          style: GoogleFonts.cairo(fontSize: 12, color: textSecondary),
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: categoryBreakdown.map((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item.name,
                                      style: GoogleFonts.cairo(fontSize: 12, color: textPrimary),
                                    ),
                                    Text(
                                      '${item.amount.toStringAsFixed(3)} د.ل (${(item.percentage * 100).round()}%)',
                                      style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: item.percentage,
                                    minHeight: 5,
                                    backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                                    valueColor: AlwaysStoppedAnimation<Color>(item.color),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEditSingleBudgetDialog(BuildContext context, String category, double currentLimit) {
    final controller = TextEditingController(text: currentLimit.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'تعديل ميزانية: $category',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'حدد سقف الميزانية الشهري بالدينار الليبي لهذا البند:',
                style: GoogleFonts.cairo(fontSize: 12.5),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
                decoration: InputDecoration(
                  suffixText: 'د.ل',
                  suffixStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      final val = (double.tryParse(controller.text) ?? currentLimit) - 50;
                      if (val > 0) controller.text = val.toStringAsFixed(0);
                    },
                    child: const Text('-50'),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      final val = (double.tryParse(controller.text) ?? currentLimit) + 50;
                      controller.text = val.toStringAsFixed(0);
                    },
                    child: const Text('+50'),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      final val = (double.tryParse(controller.text) ?? currentLimit) + 100;
                      controller.text = val.toStringAsFixed(0);
                    },
                    child: const Text('+100'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء', style: GoogleFonts.cairo()),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final newLimit = double.tryParse(controller.text);
                if (newLimit != null && newLimit > 0) {
                  AppState.instance.setBudgetLimit(category, newLimit);
                  Navigator.pop(ctx);
                }
              },
              child: Text('حفظ', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showManageBudgetsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return ListenableBuilder(
          listenable: AppState.instance,
          builder: (context, _) {
            final limits = AppState.instance.budgetLimits;
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 18,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'إدارة وتخصيص بنود الميزانية',
                          style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            AppState.instance.resetBudgetsToDefault();
                          },
                          child: Text(
                            'استعادة الافتراضي',
                            style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.accentGold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'يمكنك تعديل ميزانية أي بند أو إنقاصها أو إضافة بنود وحذف ما لا ترغب بمتابعته:',
                      style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.darkTextSecondary),
                    ),
                    const SizedBox(height: 14),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(ctx).size.height * 0.45,
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        children: limits.entries.map((entry) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Theme.of(ctx).cardColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Theme.of(ctx).dividerColor),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.key,
                                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      Text(
                                        'الحد: ${entry.value.toStringAsFixed(0)} د.ل',
                                        style: GoogleFonts.cairo(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Edit button
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primary),
                                  tooltip: 'تعديل السقف',
                                  onPressed: () => _showEditSingleBudgetDialog(context, entry.key, entry.value),
                                ),
                                // Delete button
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.danger),
                                  tooltip: 'حذف هذا البند',
                                  onPressed: () {
                                    AppState.instance.removeBudgetCategory(entry.key);
                                  },
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(
                          'إضافة بند ميزانية جديد',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => _showAddNewBudgetDialog(context),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddNewBudgetDialog(BuildContext context) {
    final availableCategories = [
      'تسوق',
      'مطاعم ومقاهي',
      'بقالة ومواد غذائية',
      'وقود وسيارات',
      'صحة وأدوية',
      'فواتير واتصالات',
      'تعليم ودراسة',
      'ترفيه وألعاب',
      'صيانة ومنزل',
      'أخرى',
    ];

    String selectedCategory = availableCategories.first;
    final limitController = TextEditingController(text: '300');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                'إضافة بند ميزانية جديد',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('اختر الفئة:', style: GoogleFonts.cairo(fontSize: 12.5)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    items: availableCategories.map((c) {
                      return DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.cairo(fontSize: 13)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedCategory = val);
                      }
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('سقف الميزانية الشهري (د.ل):', style: GoogleFonts.cairo(fontSize: 12.5)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: limitController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary),
                    decoration: InputDecoration(
                      suffixText: 'د.ل',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('إلغاء', style: GoogleFonts.cairo()),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    final limit = double.tryParse(limitController.text);
                    if (limit != null && limit > 0) {
                      AppState.instance.setBudgetLimit(selectedCategory, limit);
                      Navigator.pop(ctx);
                    }
                  },
                  child: Text('إضافة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

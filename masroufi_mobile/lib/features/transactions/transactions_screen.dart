import 'widgets/transaction_action_sheet.dart';
import '../home/widgets/month_navigation_bar.dart';
import 'dart:convert';
import '../help/screen_help_sheet.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/state/app_state.dart';
import '../../core/utils/export_helper.dart';
import '../../core/utils/pdf_export_service.dart';
import '../home/widgets/transaction_tile.dart';

class TransactionsScreen extends StatefulWidget {
  final List<TransactionItem>? transactions;

  const TransactionsScreen({super.key, this.transactions});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTimeRange? _selectedDateRange;
  bool _showAllMonths = false;
  String _typeFilter = 'الكل'; // الكل, مصاريف, دخل
  String _sourceFilter = 'الكل'; // الكل, SMS, كاش

  @override@override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'اختر نطاق التاريخ (من - إلى)',
      cancelText: 'إلغاء',
      confirmText: 'تطبيق',
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppTheme.primary,
                    onPrimary: Colors.white,
                    surface: AppTheme.darkSurface,
                    onSurface: AppTheme.darkTextPrimary,
                  )
                : const ColorScheme.light(
                    primary: AppTheme.primary,
                    onPrimary: Colors.white,
                    surface: AppTheme.lightSurface,
                    onSurface: AppTheme.lightTextPrimary,
                  ),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedDateRange = null;
      _typeFilter = 'الكل';
      _sourceFilter = 'الكل';
    });
  }

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

        final allTransactions = widget.transactions ?? AppState.instance.transactions;

        // Filter logic
        final filteredList = allTransactions.where((tx) {
          // 1. Type filter
          if (_typeFilter == 'مصروف' && !tx.isExpense) return false;
          if (_typeFilter == 'دخل' && tx.isExpense) return false;

          // 2. Source filter
          if (_sourceFilter == 'SMS' && tx.sourceBadge != 'SMS') return false;
          if (_sourceFilter == 'كاش' && tx.sourceBadge != 'كاش') return false;

          // 3. Date Range filter & Month Partitioning
          if (_selectedDateRange != null) {
            final start = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
            final end = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day, 23, 59, 59);
            if (tx.timestamp.isBefore(start) || tx.timestamp.isAfter(end)) {
              return false;
            }
          } else if (!_showAllMonths) {
            // By default: partition by the selected month in AppState!
            if (tx.timestamp.year != AppState.instance.selectedMonth.year ||
                tx.timestamp.month != AppState.instance.selectedMonth.month) {
              return false;
            }
          }

          // 4. Text search query
          if (_searchQuery.trim().isNotEmpty) {
            final query = _searchQuery.trim().toLowerCase();
            final title = tx.title.toLowerCase();
            final category = tx.category.toLowerCase();
            final dateStr = tx.date.toLowerCase();
            final amountStr = tx.amount.toString();
            final amountFixed = tx.amount.toStringAsFixed(3);

            final matches = title.contains(query) ||
                category.contains(query) ||
                dateStr.contains(query) ||
                amountStr.contains(query) ||
                amountFixed.contains(query);

            if (!matches) return false;
          }

          return true;
        }).toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

        final hasActiveFilter = _searchQuery.isNotEmpty ||
            _selectedDateRange != null ||
            _typeFilter != 'الكل' ||
            _sourceFilter != 'الكل';

        final totalExpense = filteredList
            .where((tx) => tx.isExpense)
            .fold(0.0, (sum, tx) => sum + tx.amount);
        final totalIncome = filteredList
            .where((tx) => !tx.isExpense)
            .fold(0.0, (sum, tx) => sum + tx.amount);

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'سجل المعاملات',
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.help_outline_rounded, size: 21),
                              color: textSecondary,
                              visualDensity: VisualDensity.compact,
                              tooltip: 'دليل شاشة المعاملات',
                              onPressed: () => ScreenHelpSheet.show(context, ScreenHelpType.transactions),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor),
                              ),
                              child: Text(
                                '${filteredList.length} معاملة',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _showExportSheet(context, filteredList, totalIncome, totalExpense),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.file_download_outlined, size: 15, color: AppTheme.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      'تصدير',
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
                      ],
                    ),
                  ),

                  // Month Navigation Bar (Partitioning by month)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: MonthNavigationBar(
                      showAllOption: true,
                      isAllSelected: _showAllMonths,
                      onToggleAll: () => setState(() => _showAllMonths = !_showAllMonths),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Search Bar & Date Picker Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        // Search Text Field
                        Expanded(
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _searchQuery.isNotEmpty ? AppTheme.primary : borderColor,
                                width: _searchQuery.isNotEmpty ? 1.5 : 1.0,
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) => setState(() => _searchQuery = val),
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                color: textPrimary,
                              ),
                              textInputAction: TextInputAction.search,
                              decoration: InputDecoration(
                                hintText: 'ابحث باسم المحل، التصنيف، المبلغ...',
                                hintStyle: GoogleFonts.cairo(
                                  fontSize: 11.5,
                                  color: textSecondary.withValues(alpha: 0.7),
                                ),
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  size: 20,
                                  color: AppTheme.primary,
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close_rounded, size: 18),
                                        color: textSecondary,
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Date Picker Button
                        Tooltip(
                          message: _selectedDateRange != null ? 'تغيير التاريخ' : 'البحث بالتاريخ',
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _pickDateRange(context),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                height: 46,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: _selectedDateRange != null
                                      ? AppTheme.primary.withValues(alpha: 0.15)
                                      : surfaceColor,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _selectedDateRange != null ? AppTheme.primary : borderColor,
                                    width: _selectedDateRange != null ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.calendar_month_rounded,
                                      size: 20,
                                      color: _selectedDateRange != null ? AppTheme.primary : textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _selectedDateRange != null
                                          ? '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}'
                                          : 'التاريخ',
                                      style: GoogleFonts.cairo(
                                        fontSize: 11.5,
                                        fontWeight: _selectedDateRange != null ? FontWeight.bold : FontWeight.w500,
                                        color: _selectedDateRange != null ? AppTheme.primary : textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Active Date Badge & Clear All (if date or search is active)
                  if (_selectedDateRange != null || hasActiveFilter)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 20, right: 20),
                      child: Row(
                        children: [
                          if (_selectedDateRange != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.event_available_rounded, size: 14, color: AppTheme.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} إلى ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}',
                                    style: GoogleFonts.cairo(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () => setState(() => _selectedDateRange = null),
                                    borderRadius: BorderRadius.circular(10),
                                    child: const Icon(Icons.close_rounded, size: 15, color: AppTheme.primary),
                                  ),
                                ],
                              ),
                            ),
                          const Spacer(),
                          if (hasActiveFilter)
                            GestureDetector(
                              onTap: _clearAllFilters,
                              child: Text(
                                'مسح كل الفلاتر',
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.accentGold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Summary Box: Income vs Expenses
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          // Income Summary
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hasActiveFilter ? 'مداخيل النتائج' : 'إجمالي المداخيل',
                                  style: GoogleFonts.cairo(fontSize: 11, color: textSecondary),
                                ),
                                Text(
                                  '${totalIncome.toStringAsFixed(3)} د.ل',
                                  style: GoogleFonts.cairo(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 32, color: borderColor),
                          const SizedBox(width: 16),
                          // Expense Summary
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hasActiveFilter ? 'مصاريف النتائج' : 'إجمالي المصاريف',
                                  style: GoogleFonts.cairo(fontSize: 11, color: textSecondary),
                                ),
                                Text(
                                  '${totalExpense.toStringAsFixed(3)} د.ل',
                                  style: GoogleFonts.cairo(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.danger,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Filter Tabs (Row 1: الكل / مصروف / دخل)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _buildFilterTab('الكل', _typeFilter, (val) => setState(() => _typeFilter = val)),
                        const SizedBox(width: 8),
                        _buildFilterTab('مصروف', _typeFilter, (val) => setState(() => _typeFilter = val)),
                        const SizedBox(width: 8),
                        _buildFilterTab('دخل', _typeFilter, (val) => setState(() => _typeFilter = val)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Filter Tabs (Row 2: الكل / SMS / كاش)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _buildFilterTab('الكل', _sourceFilter, (val) => setState(() => _sourceFilter = val)),
                        const SizedBox(width: 8),
                        _buildFilterTab('SMS', _sourceFilter, (val) => setState(() => _sourceFilter = val)),
                        const SizedBox(width: 8),
                        _buildFilterTab('كاش', _sourceFilter, (val) => setState(() => _sourceFilter = val)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Transactions List
                  Expanded(
                    child: filteredList.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.search_off_rounded, size: 48, color: AppTheme.darkTextMuted),
                                  const SizedBox(height: 12),
                                  Text(
                                    'لا توجد عمليات مطابقة',
                                    style: GoogleFonts.cairo(
                                      color: textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedDateRange != null
                                        ? 'لم يتم تسجيل أي معاملات في تاريخ ${'${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} إلى ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}'}'
                                        : 'جرّب البحث بكلمة أخرى أو تغيير الفلاتر المحددة',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.cairo(color: textSecondary, fontSize: 12),
                                  ),
                                  if (hasActiveFilter) ...[
                                    const SizedBox(height: 16),
                                    OutlinedButton.icon(
                                      onPressed: _clearAllFilters,
                                      icon: const Icon(Icons.refresh_rounded, size: 16),
                                      label: Text(
                                        'إعادة ضبط وتصفية الكل',
                                        style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.primary,
                                        side: const BorderSide(color: AppTheme.primary),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.only(left: 20, right: 20, top: 4, bottom: MediaQuery.of(context).padding.bottom + 80),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final tx = filteredList[index];
                              return Dismissible(
                                key: ValueKey('${tx.title}_${tx.amount}_${tx.timestamp.millisecondsSinceEpoch}_$index'),
                                direction: DismissDirection.endToStart,
                                confirmDismiss: (direction) async {
                                  return await _confirmDeleteTransaction(context, tx);
                                },
                                onDismissed: (direction) {
                                  _deleteTransactionWithUndo(context, tx);
                                },
                                background: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.danger,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
                                      SizedBox(width: 8),
                                      Text(
                                        'حذف',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                child: GestureDetector(
                                  onTap: () => _showTransactionActions(context, tx),
                                  child: TransactionTile(item: tx),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterTab(String label, String activeValue, Function(String) onSelect) {
    final isSelected = activeValue == label;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppTheme.accentGold.withValues(alpha: 0.2) : AppTheme.accentGold.withValues(alpha: 0.15))
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppTheme.accentGold : Theme.of(context).dividerColor,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppTheme.accentGold : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showExportSheet(
    BuildContext context,
    List<TransactionItem> transactions,
    double totalIncome,
    double totalExpense,
  ) {
    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('لا توجد معاملات لتصديرها وفق الفلاتر الحالية', style: GoogleFonts.cairo()),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).cardColor;
    final borderColor = Theme.of(context).dividerColor;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.file_download_outlined, color: AppTheme.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تصدير كشف المعاملات',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          'سيتم تصدير (${transactions.length}) معاملة وفق الفلترة والبحث الحالي',
                          style: GoogleFonts.cairo(fontSize: 11.5, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Excel / CSV Option
              _buildExportOption(
                icon: Icons.table_chart_rounded,
                iconColor: const Color(0xFF10B981),
                title: 'تصدير كـ ملف Excel (CSV)',
                subtitle: 'جدول بيانات متوافق مع Excel و Google Sheets يدعم اللغة العربية',
                badgeText: 'XLS / CSV',
                onTap: () {
                  Navigator.pop(ctx);
                  _exportToCsv(transactions);
                },
                isDark: isDark,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              const SizedBox(height: 10),

              // PDF Option
              _buildExportOption(
                icon: Icons.picture_as_pdf_rounded,
                iconColor: const Color(0xFFEF4444),
                title: 'تصدير كـ كشف حساب PDF',
                subtitle: 'مستند رسمي منسق مع جدول مالي وشعار مصروفي جاهز للطباعة أو الحفظ',
                badgeText: 'PDF',
                onTap: () {
                  Navigator.pop(ctx);
                  _exportToPdf(transactions, totalIncome, totalExpense);
                },
                isDark: isDark,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badgeText,
    required VoidCallback onTap,
    required bool isDark,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: GoogleFonts.cairo(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: iconColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToCsv(List<TransactionItem> transactions) async {
    try {
      final buffer = StringBuffer();
      // Add UTF-8 BOM so Microsoft Excel recognizes Arabic correctly
      buffer.write('\uFEFF');
      buffer.writeln('التاريخ والوقت,اسم العملية / المحل,التصنيف,نوع المعاملة,المصدر,المبلغ (د.ل)');

      for (final tx in transactions) {
        final type = tx.isExpense ? 'مصروف' : 'دخل';
        final amount = tx.isExpense ? '-${tx.amount.toStringAsFixed(3)}' : '+${tx.amount.toStringAsFixed(3)}';
        final date = tx.date;
        final title = '"${tx.title.replaceAll('"', '""')}"';
        final category = '"${tx.category.replaceAll('"', '""')}"';
        final source = tx.sourceBadge;

        buffer.writeln('$date,$title,$category,$type,$source,$amount');
      }

      final bytes = utf8.encode(buffer.toString());
      final now = DateTime.now();
      final dateSlug = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      await saveAndLaunchFile(bytes, 'masroufi_transactions_$dateSlug.csv');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تصدير ملف الإكسل (CSV) بنجاح', style: GoogleFonts.cairo()),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء التصدير: $e', style: GoogleFonts.cairo()),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Future<void> _exportToPdf(
    List<TransactionItem> transactions,
    double totalIncome,
    double totalExpense,
  ) async {
    try {
      await PdfExportService.exportTransactionsPdf(
        transactions: transactions,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        filterTitle: _selectedDateRange != null
            ? 'تصفية حسب التاريخ: ${'${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} إلى ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}'}'
            : (_searchQuery.isNotEmpty ? 'بحث عن: $_searchQuery' : null),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء إنشاء كشف الـ PDF: $e', style: GoogleFonts.cairo()),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Future<bool> _confirmDeleteTransaction(BuildContext context, TransactionItem tx) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 22),
              ),
              const SizedBox(width: 10),
              Text(
                'حذف المعاملة',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'هل أنت متأكد من رغبتك في حذف هذه المعاملة؟',
                style: GoogleFonts.cairo(fontSize: 13),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(ctx).dividerColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        tx.title,
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${tx.isExpense ? "-" : "+"}${tx.amount.toStringAsFixed(3)} د.ل',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: tx.isExpense ? AppTheme.danger : AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'إلغاء',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600, color: AppTheme.darkTextSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'حذف',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  void _deleteTransactionWithUndo(BuildContext context, TransactionItem tx) {
    AppState.instance.deleteTransaction(tx);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم حذف "${tx.title}" بنجاح',
          style: GoogleFonts.cairo(fontSize: 12.5),
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'تراجع',
          textColor: AppTheme.accentGold,
          onPressed: () {
            AppState.instance.addTransaction(
              title: tx.title,
              amount: tx.amount,
              category: tx.category,
              isExpense: tx.isExpense,
              sourceBadge: tx.sourceBadge,
              timestamp: tx.timestamp,
              icon: tx.icon,
            );
          },
        ),
      ),
    );
  }

  void _showTransactionActions(BuildContext context, TransactionItem tx) {
    showTransactionActionSheet(context, tx);
  }
}

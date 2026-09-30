import '../../core/services/update_service.dart';
import '../transactions/widgets/transaction_action_sheet.dart';
import '../help/screen_help_sheet.dart';
import '../../core/services/sms_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/state/app_state.dart';
import '../transactions/transactions_screen.dart';
import '../analytics/analytics_screen.dart';
import '../settings/settings_screen.dart';
import 'widgets/hero_balance_card.dart';
import 'widgets/mid_cards.dart';
import 'widgets/transaction_tile.dart';
import 'widgets/add_transaction_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentNavIndex = 0;
  bool _isSmsActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkSmsStatus();
    SmsService.instance.syncSmsInbox();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkAndPromptUpdate(context);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSmsStatus();
      SmsService.instance.syncSmsInbox();
    }
  }

  Future<void> _checkSmsStatus() async {
    final hasPerm = await SmsService.instance.checkPermission();
    if (mounted && hasPerm != _isSmsActive) {
      setState(() {
        _isSmsActive = hasPerm;
      });
    }
  }

  void _openAddTransactionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true, // Guarantees no clash with system navigation bar!
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddCashBottomSheet(
        onSave: (title, amount, category, isExpense) {
          AppState.instance.addTransaction(
            title: title,
            amount: amount,
            category: category,
            isExpense: isExpense,
            sourceBadge: 'كاش',
          );
        },
      ),
    );
  }

  void _showRestrictedSettingsGuideDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Theme.of(context).cardColor,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.security_outlined, color: AppTheme.accentGold, size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'تفعيل إذن الرسائل (أندرويد)',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'نظام أندرويد يقيد أذونات التطبيقات المثبتة يدوياً خارج متجر Google Play لحماية أمانك. لتفعيل المزامنة في ثوانٍ:',
                style: GoogleFonts.cairo(
                  fontSize: 12.5,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              _buildStepRow('1', 'اضغط على زر "فتح إعدادات التطبيق" بالأسفل.', isDark),
              const SizedBox(height: 8),
              _buildStepRow('2', 'اضغط على الثلاث نقاط (⋮) في الزاوية العلوية للشاشة.', isDark),
              const SizedBox(height: 8),
              _buildStepRow('3', 'اختر "السماح بالإعدادات المقيّدة" (Allow restricted settings).', isDark),
              const SizedBox(height: 8),
              _buildStepRow('4', 'ادخل إلى "الأذونات" (Permissions) وفعل إذن "الرسائل" (SMS).', isDark),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'إلغاء',
                style: GoogleFonts.cairo(
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.settings, size: 16),
              label: Text(
                'فتح إعدادات التطبيق',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                SmsService.instance.openAppSettings();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepRow(String number, String text, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final List<Widget> screens = [
          _buildDashboardTab(),
          const TransactionsScreen(),
          const AnalyticsScreen(),
          const SettingsScreen(),
        ];

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: IndexedStack(
              index: _currentNavIndex,
              children: screens,
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
            floatingActionButton: Container(
              height: 54,
              width: 54,
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.accentGold, AppTheme.accentGoldLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(27),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentGold.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: _openAddTransactionSheet,
                elevation: 0,
                backgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                child: const Icon(Icons.add, color: AppTheme.primaryDark, size: 28),
              ),
            ),
            bottomNavigationBar: SafeArea(
              top: false,
              bottom: true, // Protection from Android system navigation buttons!
              child: BottomAppBar(
                color: Theme.of(context).cardColor,
                shape: const CircularNotchedRectangle(),
                notchMargin: 8,
                child: SizedBox(
                  height: 60,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(0, Icons.home_outlined, Icons.home, 'الرئيسية'),
                      _buildNavItem(1, Icons.receipt_long_outlined, Icons.receipt_long, 'المعاملات'),
                      const SizedBox(width: 48), // gap for (+)
                      _buildNavItem(2, Icons.pie_chart_outline, Icons.pie_chart, 'التحليلات'),
                      _buildNavItem(3, Icons.settings_outlined, Icons.settings, 'الإعدادات'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDashboardTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    final user = AppState.instance.currentUser;
    final monthTransactions = AppState.instance.currentMonthTransactions;
    final monthNetBalance = AppState.instance.currentMonthNetBalance;
    final monthIncome = AppState.instance.currentMonthIncome;
    final monthExpense = AppState.instance.currentMonthExpense;
    final isCurrentMonth = AppState.instance.isCurrentMonth;

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Right side: Avatar & User Greeting
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.primary, AppTheme.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            user.initial,
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'مرحباً بك،',
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: textSecondary,
                              ),
                            ),
                            Text(
                              user.displayName.isNotEmpty
                                  ? user.displayName
                                  : (user.phoneNumber.isNotEmpty ? user.phoneNumber : 'عزيزي المستخدم'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // Left side: Interactive Live Sync Badge + Help + Dark Mode
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isSmsActive)
                      InkWell(
                        onTap: () async {
                          final count = await SmsService.instance.syncSmsInbox();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  count > 0
                                      ? 'تم سحب $count معاملة جديدة من الرسائل!'
                                      : 'جميع المعاملات المصرفية محدثة بالفعل',
                                  style: GoogleFonts.cairo(),
                                ),
                                backgroundColor: count > 0 ? AppTheme.primary : AppTheme.darkBackground,
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppTheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'مزامنة',
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.help_outline_rounded, size: 20),
                      color: textSecondary,
                      visualDensity: VisualDensity.compact,
                      tooltip: 'دليل الشاشة الرئيسية',
                      onPressed: () => ScreenHelpSheet.show(context, ScreenHelpType.home),
                    ),
                    IconButton(
                      icon: Icon(
                        isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                        size: 20,
                        color: textSecondary,
                      ),
                      visualDensity: VisualDensity.compact,
                      tooltip: isDark ? 'الوضع النهاري' : 'الوضع الليلي',
                      onPressed: () => ThemeController.toggleTheme(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Scrollable Content with Pull-To-Refresh
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: () async {
                final count = await SmsService.instance.syncSmsInbox();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        count > 0
                            ? 'تم سحب $count معاملة جديدة من الرسائل!'
                            : 'جميع المعاملات محدثة',
                        style: GoogleFonts.cairo(),
                      ),
                      backgroundColor: AppTheme.primary,
                    ),
                  );
                }
              },
              child: ListView(
              padding: EdgeInsets.only(left: 20, right: 20, top: 8, bottom: MediaQuery.of(context).padding.bottom + 80),
              children: [
                // Month Selector Bar (Defaults to Current/Latest Month)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        tooltip: 'الشهر السابق',
                        icon: const Icon(Icons.chevron_right, size: 22),
                        onPressed: () => AppState.instance.previousMonth(),
                      ),
                      GestureDetector(
                        onTap: () => AppState.instance.resetToCurrentMonth(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isCurrentMonth
                                ? AppTheme.primary.withValues(alpha: 0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 15,
                                color: isCurrentMonth ? AppTheme.primary : textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppState.instance.selectedMonthName,
                                style: GoogleFonts.cairo(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: isCurrentMonth ? AppTheme.primary : textPrimary,
                                ),
                              ),
                              if (isCurrentMonth) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary,
                                    borderRadius: BorderRadius.circular(8),
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
                      IconButton(
                        tooltip: 'الشهر القادم',
                        icon: const Icon(Icons.chevron_left, size: 22),
                        onPressed: () => AppState.instance.nextMonth(),
                      ),
                    ],
                  ),
                ),

                // Hero Balance Card for Selected Month
                HeroBalanceCard(
                  netBalance: monthNetBalance,
                  totalIncome: monthIncome,
                  totalExpense: monthExpense,
                ),
                const SizedBox(height: 20),

                // SMS Auto-Sync Live Status Card (hidden once activated)
                if (!_isSmsActive) ...[
                  _buildSmsStatusCard(isDark),
                  const SizedBox(height: 20),
                ],

                // Middle Cards (Spendings breakdown & Budgets)
                const DistributionCard(),
                const SizedBox(height: 16),
                const BudgetProgressCard(),
                const SizedBox(height: 24),

                // Recent Transactions Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'معاملات ${AppState.instance.selectedMonthName}',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _currentNavIndex = 1),
                      child: Text(
                        'عرض الكل (${monthTransactions.length})',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.accentGold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Transaction Items or Empty State
                if (monthTransactions.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Center(
                      child: Text(
                        'لا توجد معاملات مسجلة في هذا الشهر',
                        style: GoogleFonts.cairo(fontSize: 13, color: textSecondary),
                      ),
                    ),
                  )
                else
                  ...monthTransactions.take(5).map((tx) => TransactionTile(item: tx, onTap: () => showTransactionActionSheet(context, tx))),

                const SizedBox(height: 80), // spacing for bottom bar
              ],
            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmsStatusCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sms_outlined, color: Color(0xFF0284C7), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المزامنة المباشرة للرسائل المصرفية',
                  style: GoogleFonts.cairo(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  ),
                ),
                Text(
                  'تتبع الرسائل المصرفية الحية فور وصولها',
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final granted = await SmsService.instance.requestPermission();
                if (mounted) {
                  if (granted) {
                    setState(() => _isSmsActive = true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'تم تفعيل التتبع المباشر للرسائل المصرفية بنجاح',
                          style: GoogleFonts.cairo(),
                        ),
                        backgroundColor: AppTheme.primary,
                      ),
                    );
                  } else {
                    _showRestrictedSettingsGuideDialog(context);
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'تفعيل',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData unselectedIcon, IconData selectedIcon, String label) {
    final bool isSelected = _currentNavIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => setState(() => _currentNavIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : unselectedIcon,
              color: isSelected
                  ? AppTheme.accentGold
                  : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? AppTheme.accentGold
                    : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

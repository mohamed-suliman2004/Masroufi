import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

enum ScreenHelpType {
  home,
  transactions,
  analytics,
  settings,
}

class HelpItem {
  final IconData icon;
  final String title;
  final String description;

  const HelpItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class ScreenHelpSheet extends StatelessWidget {
  final ScreenHelpType type;

  const ScreenHelpSheet({super.key, required this.type});

  static void show(BuildContext context, ScreenHelpType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ScreenHelpSheet(type: type),
    );
  }

  String _getTitle() {
    switch (type) {
      case ScreenHelpType.home:
        return 'دليل الشاشة الرئيسية';
      case ScreenHelpType.transactions:
        return 'دليل شاشة المعاملات';
      case ScreenHelpType.analytics:
        return 'دليل شاشة التحليلات والميزانية';
      case ScreenHelpType.settings:
        return 'دليل شاشة الإعدادات والأمان';
    }
  }

  String _getSubtitle() {
    switch (type) {
      case ScreenHelpType.home:
        return 'نظرة عامة على رصيدك الشهري وتتبع المصاريف';
      case ScreenHelpType.transactions:
        return 'البحث، الفلترة، ومراجعة حركاتك المالية';
      case ScreenHelpType.analytics:
        return 'فهم توزيع نفقاتك والتحكم في ميزانيتك';
      case ScreenHelpType.settings:
        return 'تخصيص الأمان، البنوك، والمظهر';
    }
  }

  IconData _getHeaderIcon() {
    switch (type) {
      case ScreenHelpType.home:
        return Icons.home_rounded;
      case ScreenHelpType.transactions:
        return Icons.receipt_long_rounded;
      case ScreenHelpType.analytics:
        return Icons.pie_chart_rounded;
      case ScreenHelpType.settings:
        return Icons.settings_rounded;
    }
  }

  List<HelpItem> _getItems() {
    switch (type) {
      case ScreenHelpType.home:
        return const [
          HelpItem(
            icon: Icons.account_balance_wallet_rounded,
            title: 'بطاقة صافي الشهر',
            description: 'تعرض لك الفارق بين إجمالي المداخيل والمصروفات للشهر المحدد، مع تفصيل كامل لكل منهما.',
          ),
          HelpItem(
            icon: Icons.calendar_month_rounded,
            title: 'التنقل بين الشهور',
            description: 'استخدم الأسهم في الأعلى للرجوع لأي شهر ماضي؛ العداد يصفر كل بداية شهر لتتبع نفقات كل شهر بمفرده.',
          ),
          HelpItem(
            icon: Icons.sync_rounded,
            title: 'المزامنة الحية للرسائل (SMS)',
            description: 'يلتقط التطبيق رسائل ون باي، التجارة والتنمية، والتجاري الوطني فور وصولها ويسجلها تلقائياً بدون إنترنت.',
          ),
          HelpItem(
            icon: Icons.add_circle_outline_rounded,
            title: 'تسجيل الكاش (+)',
            description: 'اضغط على زر الإضافة العائم لتسجيل أي مصروف نقدي (مشتريات، بنزين، مطاعم) وتصنيفه في ثوانٍ.',
          ),
        ];

      case ScreenHelpType.transactions:
        return const [
          HelpItem(
            icon: Icons.search_rounded,
            title: 'البحث السريع',
            description: 'ابحث باسم المحل أو الجهة (مثل: حلواني، صيدلية، تداول، سداد) أو التصنيف أو المبلغ لتصل لأي معاملة فوراً.',
          ),
          HelpItem(
            icon: Icons.calendar_month_rounded,
            title: 'البحث بالتاريخ',
            description: 'اضغط على زر التاريخ لاختيار يوم محدد وعرض جميع المعاملات والمصاريف الخاصة بذلك اليوم بدقة.',
          ),
          HelpItem(
            icon: Icons.filter_alt_rounded,
            title: 'تصفية النتائج',
            description: 'يمكنك الفرز حسب: (الكل، المصروفات، المداخيل) أو حسب المصدر (رسائل SMS المصرفية فقط، أو الكاش اليدوي).',
          ),
          HelpItem(
            icon: Icons.label_important_outline_rounded,
            title: 'شارات المصدر والتاجر',
            description: 'علامة SMS تعني حركة بنكية تم التقاطها تلقائياً، وعلامة كاش تعني معاملة نقدية أضفتها بنفسك.',
          ),
        ];

      case ScreenHelpType.analytics:
        return const [
          HelpItem(
            icon: Icons.donut_large_rounded,
            title: 'مخطط توزيع النفقات',
            description: 'رسم بياني يوضح لك النسبة المئوية لكل فئة (مطاعم، وقود، تسوق، فواتير) لتعرف أين يذهب دخلك.',
          ),
          HelpItem(
            icon: Icons.speed_rounded,
            title: 'مؤشر استهلاك الميزانية',
            description: 'شريط تقدم يوضح لك كم استهلكت من ميزانيتك المقدرة، وينبهك لتجنب نفاد الراتب قبل نهاية الشهر.',
          ),
          HelpItem(
            icon: Icons.insights_rounded,
            title: 'المقارنة مع الشهور السابقة',
            description: 'بإمكانك تغيير الشهر لرؤية كيف تطور نمط إنفاقك من شهر لآخر.',
          ),
        ];

      case ScreenHelpType.settings:
        return const [
          HelpItem(
            icon: Icons.fingerprint_rounded,
            title: 'الأمان بالبصمة (Biometrics)',
            description: 'فعّل الدخول ببصمة الإصبع أو الوجه لضمان حماية خصوصيتك ومنع أي متطفل من فتح حساباتك.',
          ),
          HelpItem(
            icon: Icons.account_balance_rounded,
            title: 'أرقام وعناوين المصارف',
            description: 'قائمة بالمصارف الليبية المدعومة تلقائياً مع إمكانية إضافة أي رقم مصرفي أو خدمة دفع جديدة.',
          ),
          HelpItem(
            icon: Icons.menu_book_rounded,
            title: 'دليل استخدام التطبيق',
            description: 'استعراض جولة الشرح والتعليمات التفاعلية للتطبيق في أي وقت.',
          ),
          HelpItem(
            icon: Icons.dark_mode_rounded,
            title: 'المظهر والوضع الليلي',
            description: 'التبديل بين الوضع الليلي الأنيق المريح للعين والوضع النهاري.',
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).cardColor;
    final borderColor = Theme.of(context).dividerColor;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    final items = _getItems();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 20,
        ),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: borderColor.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header Row with Icon and Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.accentGold],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_getHeaderIcon(), color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTitle(),
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        _getSubtitle(),
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: textSecondary,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: borderColor.withValues(alpha: 0.5), height: 1),
            const SizedBox(height: 14),

            // Help items list
            ...items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon, color: AppTheme.primary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: GoogleFonts.cairo(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.description,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              height: 1.45,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 10),

            // Close / Understood Button
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text(
                'فهمت ذلك',
                style: GoogleFonts.cairo(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

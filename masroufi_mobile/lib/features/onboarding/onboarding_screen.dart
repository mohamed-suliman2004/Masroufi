import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/state/app_state.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final bool isFromSettings;

  const OnboardingScreen({super.key, this.isFromSettings = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'تتبع تلقائي ذكي لرسائل المصارف',
      'subtitle': 'وفر وقتك ولا تكتب شيئاً بيدك',
      'description':
          'يلتقط مصروفي رسائل الخصم والتحويل المصرفية (ون باي، مصرف التجارة والتنمية، المصرف التجاري الوطني، مصرف الجمهورية...) فور وصولها لهاتفك ويحلل المبلغ واسم التاجر تلقائياً وبأمان محلي 100%.',
      'icon': Icons.mark_email_read_rounded,
      'gradient': [Color(0xFF0284C7), Color(0xFF38BDF8)],
      'badge': 'مزامنة حية وبدون إنترنت',
    },
    {
      'title': 'سجّل مصاريف الكاش في ثوانٍ',
      'subtitle': 'كل قرش محسوب بدقة',
      'description':
          'مصاريفك النقدية ومشتريات الشارع؟ بضغطة زر واحدة على علامة (+) سجّل قيمة مشترياتك واختر الفئة (مطاعم، وقود، صيدلية...) لتعرف ميزانيتك الحقيقية في أي وقت.',
      'icon': Icons.payments_rounded,
      'gradient': [Color(0xFF059669), Color(0xFF34D399)],
      'badge': 'تسجيل نقدي فوري',
    },
    {
      'title': 'تقارير شهرية وميزانية واضحة',
      'subtitle': 'اعرف راتبك وين مشى بالضبط',
      'description':
          'تتبع صافي نفقاتك شهراً بشهر مع تصفير ذكي للعدادات في بداية كل شهر، ورسوم بيانية تفاعلية تحسب لك نسبة استهلاكك للراتب ومصادر إنفاقك.',
      'icon': Icons.insights_rounded,
      'gradient': [Color(0xFFD97706), Color(0xFFFBBF24)],
      'badge': 'رسوم بيانية وميزانية شهرية',
    },
    {
      'title': 'أمان وحماية تامة بالبصمة',
      'subtitle': 'بياناتك المالية لك وحدك',
      'description':
          'أموالك وحساباتك محمية ببصمة يدك أو وجهك؛ جميع بياناتك مسجلة ومشفرة محلياً على هاتفك دون مشاركتها مع أي طرف خارجي.',
      'icon': Icons.fingerprint_rounded,
      'gradient': [Color(0xFF7C3AED), Color(0xFFA78BFA)],
      'badge': 'حماية البصمة وتشفير كامل',
    },
  ];

  Future<void> _finishOnboarding() async {
    if (widget.isFromSettings) {
      Navigator.pop(context);
    } else {
      await AppState.instance.setHasSeenOnboarding(true);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              // Top Bar (Skip / Close Button)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Brand mark
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.account_balance_wallet, color: AppTheme.primary, size: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'مصروفي',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),

                    // Skip or Close
                    TextButton(
                      onPressed: _finishOnboarding,
                      child: Text(
                        widget.isFromSettings ? 'إغلاق' : 'تخطي',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Page Content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (idx) => setState(() => _currentPage = idx),
                  itemBuilder: (context, index) {
                    final p = _pages[index];
                    final List<Color> grad = p['gradient'] as List<Color>;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Animated Icon Container
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: grad,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: grad[0].withValues(alpha: 0.35),
                                  blurRadius: 30,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                p['icon'] as IconData,
                                size: 68,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 36),

                          // Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: grad[0].withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: grad[0].withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              p['badge'] as String,
                              style: GoogleFonts.cairo(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: grad[0],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Title
                          Text(
                            p['title'] as String,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Subtitle
                          Text(
                            p['subtitle'] as String,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.accentGold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Description
                          Text(
                            p['description'] as String,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              height: 1.6,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom Area: Indicators & Next Button
              Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 20,
                ),
                child: Column(
                  children: [
                    // Smooth Dots Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 26 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? AppTheme.primary
                                : (isDark ? Colors.white24 : Colors.black12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Next / Finish Button
                    ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        shadowColor: AppTheme.primary.withValues(alpha: 0.4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage == _pages.length - 1
                                ? (widget.isFromSettings ? 'إغلاق الدليل' : 'ابدأ استخدام مصروفي 🚀')
                                : 'التالي',
                            style: GoogleFonts.cairo(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _currentPage == _pages.length - 1
                                ? Icons.check_circle_outline
                                : Icons.arrow_back_rounded,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

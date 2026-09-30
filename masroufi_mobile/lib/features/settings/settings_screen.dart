import '../../core/services/sms_service.dart';
import '../help/screen_help_sheet.dart';
import '../onboarding/onboarding_screen.dart';
import '../../core/services/biometric_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/state/app_state.dart';
import '../../core/models/bank_sender_model.dart';
import '../auth/login_screen.dart';
import 'account_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoSms = true;
  bool _biometrics = true;
  bool _cloudSync = false;
  bool _budgetAlerts = true;

  void _showAddBankSheet() {
    final nameController = TextEditingController();
    final senderController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance, color: AppTheme.accentGold, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'إضافة مصرف أو خدمة رسائل',
                    style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'أدخل اسم المصرف ورقم أو اسم المرسل (Sender ID) الذي تصلك منه الرسائل لتتبعه تلقائياً.',
                style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.darkTextMuted),
              ),
              const SizedBox(height: 18),

              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المصرف / الخدمة',
                  hintText: 'مثلاً: مصرف التجارة والتنمية أو مصرف الأمان',
                  prefixIcon: Icon(Icons.business_outlined, size: 20),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'يرجى إدخال اسم المصرف';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: senderController,
                decoration: const InputDecoration(
                  labelText: 'رقم أو معرّف المرسل (Sender ID)',
                  hintText: 'مثلاً: 18787 أو NCB أو AmanBank',
                  prefixIcon: Icon(Icons.mark_email_read_outlined, size: 20),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'يرجى إدخال رقم أو اسم مرسل الرسائل';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  AppState.instance.addCustomBank(
                    name: nameController.text,
                    senderId: senderController.text,
                  );
                  SmsService.instance.syncSmsInbox();
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تمت إضافة المصرف بنجاح وسيتم تتبع رسائله 👍', style: GoogleFonts.cairo()),
                      backgroundColor: AppTheme.primary,
                    ),
                  );
                },
                child: const Text('حفظ المصرف'),
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _handleDeleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 26),
              const SizedBox(width: 8),
              Text(
                'حذف الحساب نهائياً',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: Text(
            'تحذير: سيتم حذف حسابك وجميع معاملاتك المالية والفواتير المرفقة من السيرفر وجهازك بشكل دائم ولا يمكن التراجع عن هذا الإجراء.\n\nهل تريد تأكيد حذف الحساب نهائياً؟',
            style: GoogleFonts.cairo(fontSize: 13, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء', style: GoogleFonts.cairo(color: AppTheme.darkTextMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator()),
                );

                await AppState.instance.deleteAccountPermanently();

                if (!mounted) return;
                Navigator.of(context).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'تم حذف حسابك وجميع بياناتك بنجاح',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: AppTheme.danger,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'نعم، حذف الحساب',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'تسجيل الخروج',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'هل أنت متأكد من تسجيل الخروج؟ يمكنك تسجيل الدخول بحساب آخر في أي وقت.',
            style: GoogleFonts.cairo(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء', style: GoogleFonts.cairo(color: AppTheme.darkTextMuted)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                AppState.instance.logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: Text(
                'تأكيد الخروج',
                style: GoogleFonts.cairo(color: AppTheme.danger, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
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

        final user = AppState.instance.currentUser;
        final bankSenders = AppState.instance.allBankSenders;

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
                        'الإعدادات والأمان',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // User Profile Card (Clickable to Edit)
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AccountSettingsScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppTheme.primary, AppTheme.accentGold],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                user.initial,
                                style: GoogleFonts.cairo(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        user.displayName.isNotEmpty ? user.displayName : (user.phoneNumber.isNotEmpty ? user.phoneNumber : 'عزيزي المستخدم'),
                                        style: GoogleFonts.cairo(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: textPrimary,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'حساب نشط',
                                        style: GoogleFonts.cairo(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user.phoneNumber.isNotEmpty ? user.phoneNumber : 'بدون هاتف',
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    color: textSecondary,
                                  ),
                                ),
                                if (user.email != null && user.email!.isNotEmpty) ...[
                                  Text(
                                    user.email!,
                                    style: GoogleFonts.cairo(
                                      fontSize: 11,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_back_ios_new, size: 16, color: textSecondary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Live Sync Status Card in Settings
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _autoSms
                          ? AppTheme.primary.withValues(alpha: 0.08)
                          : AppTheme.accentGold.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _autoSms
                            ? AppTheme.primary.withValues(alpha: 0.25)
                            : AppTheme.accentGold.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _autoSms
                                ? AppTheme.primary.withValues(alpha: 0.18)
                                : AppTheme.accentGold.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _autoSms ? Icons.sync_rounded : Icons.sync_disabled_rounded,
                            color: _autoSms ? AppTheme.primary : AppTheme.accentGold,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _autoSms ? 'المزامنة الحية نشطة' : 'المزامنة متوقفة',
                                    style: GoogleFonts.cairo(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: _autoSms ? AppTheme.primary : AppTheme.accentGold,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _autoSms ? AppTheme.primary : AppTheme.accentGold,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                _autoSms
                                    ? 'جاهز لقراءة رسائل ون باي والمصارف تلقائياً وتحديث الرصيد'
                                    : 'تم إيقاف الالتقاط التلقائي للرسائل',
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Switch Settings
                  _buildSwitchCard(
                    title: 'قراءة رسائل المصارف تلقائياً',
                    subtitle: 'محلياً على الجهاز فقط بدون اتصال خارجي',
                    value: _autoSms,
                    onChanged: (val) => setState(() => _autoSms = val),
                  ),
                  _buildSwitchCard(
                    title: 'القفل بالبصمة',
                    subtitle: 'حماية إضافية عند فتح التطبيق وتأكيد العمليات',
                    value: _biometrics,
                    onChanged: (val) async {
                      if (val) {
                        final auth = await BiometricService.authenticate(
                          reason: 'يرجى تأكيد البصمة لتفعيل القفل بالبصمة',
                        );
                        if (!auth) return;
                      }
                      await BiometricService.setBiometricEnabled(val);
                      setState(() => _biometrics = val);
                    },
                  ),
                  _buildSwitchCard(
                    title: 'المزامنة السحابية',
                    subtitle: 'تشفير ومزامنة البيانات عند الاتصال بالإنترنت',
                    value: _cloudSync,
                    onChanged: (val) => setState(() => _cloudSync = val),
                  ),
                  _buildSwitchCard(
                    title: 'تنبيه تجاوز الميزانية',
                    subtitle: 'إشعار فوري عند وصول الصرف إلى 80% و 100%',
                    value: _budgetAlerts,
                    onChanged: (val) => setState(() => _budgetAlerts = val),
                  ),
                  const SizedBox(height: 14),

                                    // Supported Banks Section (With Add Bank Option & Sender Badges)
                  Container(
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
                            Text(
                              'المصارف والخدمات المدعومة',
                              style: GoogleFonts.cairo(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            InkWell(
                              onTap: _showAddBankSheet,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentGold.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.add, size: 14, color: AppTheme.accentGold),
                                    const SizedBox(width: 4),
                                    Text(
                                      'إضافة مصرف',
                                      style: GoogleFonts.cairo(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.accentGold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: bankSenders.map((bank) {
                            return _buildBankChip(bank, isDark, borderColor, textPrimary, textSecondary);
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // App User Guide Card
                  InkWell(
                    onTap: () => _showGuideHub(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.menu_book_rounded, color: AppTheme.primary, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'دليل استخدام التطبيق والإرشادات',
                                  style: GoogleFonts.cairo(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                                Text(
                                  'استعراض شروحات المزامنة، المعاملات، والميزانية',
                                  style: GoogleFonts.cairo(
                                    fontSize: 11,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_left, color: AppTheme.primary, size: 22),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Logout Button
                  OutlinedButton(
                    onPressed: _handleLogout,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.danger, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: Text(
                      'تسجيل الخروج',
                      style: GoogleFonts.cairo(
                        color: AppTheme.danger,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Delete Account Button (Google Play Requirement)
                  Center(
                    child: TextButton.icon(
                      onPressed: _handleDeleteAccount,
                      icon: const Icon(Icons.delete_forever_outlined, color: AppTheme.danger, size: 20),
                      label: Text(
                        'حذف الحساب والبيانات نهائياً',
                        style: GoogleFonts.cairo(
                          color: AppTheme.danger,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: AppTheme.danger,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBankChip(BankSender bank, bool isDark, Color borderColor, Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: bank.isCustom ? AppTheme.accentGold.withValues(alpha: 0.5) : borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            bank.name,
            style: GoogleFonts.cairo(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: bank.senderId == '18787' || bank.senderId == 'NCB'
                  ? AppTheme.primary.withValues(alpha: 0.2)
                  : AppTheme.accentGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              bank.senderId,
              style: GoogleFonts.cairo(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: bank.senderId == '18787' || bank.senderId == 'NCB' ? AppTheme.primary : AppTheme.accentGold,
              ),
            ),
          ),
          if (bank.isCustom) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => AppState.instance.removeCustomBank(bank.senderId),
              child: const Icon(Icons.close, size: 14, color: AppTheme.danger),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSwitchCard({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppTheme.accentGold,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  void _showGuideHub(BuildContext context) {
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
                    child: const Icon(Icons.menu_book_rounded, color: AppTheme.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'دليل استخدام التطبيق والإرشادات',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'اختر الدليل الذي ترغب في مراجعته في أي وقت:',
                style: GoogleFonts.cairo(fontSize: 12, color: textSecondary),
              ),
              const SizedBox(height: 16),
              _buildGuideOption(
                icon: Icons.auto_stories_rounded,
                title: 'الجولة الترحيبية الكاملة',
                subtitle: 'استعراض شرائح الترحيب والمميزات الأساسية',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OnboardingScreen(isFromSettings: true),
                    ),
                  );
                },
                isDark: isDark,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              const SizedBox(height: 8),
              _buildGuideOption(
                icon: Icons.home_rounded,
                title: 'دليل الشاشة الرئيسية ومزامنة الرسائل',
                subtitle: 'كيفية التقاط رسائل المصارف وتسجيل الكاش',
                onTap: () {
                  Navigator.pop(ctx);
                  ScreenHelpSheet.show(context, ScreenHelpType.home);
                },
                isDark: isDark,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              const SizedBox(height: 8),
              _buildGuideOption(
                icon: Icons.receipt_long_rounded,
                title: 'دليل سجل المعاملات والبحث والتاريخ',
                subtitle: 'طريقة البحث السريع والفلترة بتاريخ محدد',
                onTap: () {
                  Navigator.pop(ctx);
                  ScreenHelpSheet.show(context, ScreenHelpType.transactions);
                },
                isDark: isDark,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              const SizedBox(height: 8),
              _buildGuideOption(
                icon: Icons.pie_chart_rounded,
                title: 'دليل التحليلات والميزانية الشهرية',
                subtitle: 'فهم نسب الإنفاق وبنود الميزانية المحددة',
                onTap: () {
                  Navigator.pop(ctx);
                  ScreenHelpSheet.show(context, ScreenHelpType.analytics);
                },
                isDark: isDark,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              const SizedBox(height: 8),
              _buildGuideOption(
                icon: Icons.settings_rounded,
                title: 'دليل الإعدادات وتخصيص المصارف',
                subtitle: 'إضافة أرقام المصارف وأمان البصمة',
                onTap: () {
                  Navigator.pop(ctx);
                  ScreenHelpSheet.show(context, ScreenHelpType.settings);
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

  Widget _buildGuideOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      fontSize: 10.5,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_left, size: 18, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }

}

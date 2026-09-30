import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/country_code_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/home_screen.dart';

class ForgotPasswordSheet extends StatefulWidget {
  final String? initialLogin;
  final CountryCode selectedCountry;

  const ForgotPasswordSheet({
    super.key,
    this.initialLogin,
    required this.selectedCountry,
  });

  @override
  State<ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<ForgotPasswordSheet> {
  final _phoneController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late CountryCode _country;
  bool _isVerified = false;
  bool _isLoading = false;
  bool _isCheckingSaved = true;
  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;
  bool _isManualPhoneEdit = false;
  String? _detectedUserName;

  @override
  void initState() {
    super.initState();
    _country = widget.selectedCountry;
    _initAccountInfo();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _initAccountInfo() async {
    // If initialLogin was passed from login field, use it
    if (widget.initialLogin != null && widget.initialLogin!.trim().isNotEmpty) {
      final val = widget.initialLogin!.trim();
      if (val.startsWith('+218')) {
        _phoneController.text = val.substring(4);
      } else if (val.startsWith('0')) {
        _phoneController.text = val.substring(1);
      } else {
        _phoneController.text = val;
      }
    } else {
      // Check saved user on this device
      try {
        final prefs = await SharedPreferences.getInstance();
        final rawUser = prefs.getString('masroufi_current_user') ?? prefs.getString('masroufi_saved_user');
        if (rawUser != null && rawUser.isNotEmpty) {
          final userMap = jsonDecode(rawUser) as Map<String, dynamic>;
          final phone = (userMap['phone_number'] ?? userMap['phone'] ?? '').toString();
          final name = (userMap['name'] ?? '').toString();
          if (phone.isNotEmpty) {
            if (phone.startsWith('+218')) {
              _phoneController.text = phone.substring(4);
            } else if (phone.startsWith('0')) {
              _phoneController.text = phone.substring(1);
            } else {
              _phoneController.text = phone;
            }
            if (name.isNotEmpty) {
              _detectedUserName = name;
            }
          }
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() => _isCheckingSaved = false);
    }
  }

  String _getFullIdentifier() {
    final text = _phoneController.text.trim().replaceAll(' ', '');
    if (text.contains('@')) return text;
    var phone = text;
    if (phone.startsWith('0')) phone = phone.substring(1);
    return '${_country.code}$phone';
  }

  Future<void> _handleBiometricAuth() async {
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('يرجى كتابة رقم الهاتف أو البريد الإلكتروني أولاً', style: GoogleFonts.cairo()),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await BiometricService.authenticate(
        reason: 'يرجى تأكيد بصمة إصبعك أو رمز قفل الشاشة لتغيير كلمة المرور',
      );

      if (success) {
        if (mounted) {
          setState(() {
            _isVerified = true;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تعذر التحقق من البصمة أو قفل الشاشة، يرجى المحاولة مجدداً',
                style: GoogleFonts.cairo(),
              ),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء فحص البصمة: $e', style: GoogleFonts.cairo()),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Future<void> _handleSaveNewPassword() async {
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('كلمة المرور يجب ألا تقل عن 6 خانات', style: GoogleFonts.cairo()),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('كلمتا المرور غير متطابقتين', style: GoogleFonts.cairo()),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final identifier = _getFullIdentifier();

    try {
      final updatedUser = await AuthService.resetPasswordBiometric(
        login: identifier,
        newPassword: newPass,
      );

      AppState.instance.setUser(updatedUser);

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context); // Close bottom sheet

        // Navigate to Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'تم تغيير كلمة المرور بنجاح وتسجيل الدخول! مرحباً بك.',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', ''), style: GoogleFonts.cairo()),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          top: false,
          bottom: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 14),
              Text(
                'اختر رمز الدولة',
                style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: supportedCountries.length,
                  separatorBuilder: (context, index) => Divider(height: 1, color: Theme.of(context).dividerColor),
                  itemBuilder: (context, index) {
                    final c = supportedCountries[index];
                    final isSelected = c.code == _country.code;
                    return ListTile(
                      onTap: () {
                        setState(() => _country = c);
                        Navigator.pop(ctx);
                      },
                      leading: Text(c.flag, style: const TextStyle(fontSize: 24)),
                      title: Text(c.name, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600)),
                      trailing: Text(
                        c.code,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppTheme.accentGold : AppTheme.darkTextMuted,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final bottomPadding = mediaQuery.padding.bottom;
    // Generous bottom clearance to completely prevent overlapping with Android navigation buttons
    final effectiveBottomPadding = bottomInset > 0
        ? bottomInset + 20.0
        : (bottomPadding > 0 ? bottomPadding + 36.0 : 48.0);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: effectiveBottomPadding,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 25,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle Bar
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Header Badge & Title
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isVerified
                            ? [const Color(0xFF10B981), const Color(0xFF059669)]
                            : [AppTheme.primary, const Color(0xFF34D399)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (_isVerified ? const Color(0xFF10B981) : AppTheme.primary).withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isVerified ? Icons.check_circle_outline_rounded : Icons.fingerprint_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isVerified ? 'تعيين كلمة المرور الجديدة' : 'استعادة عبر بصمة الجهاز',
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _isVerified
                              ? 'تم تأكيد هويتك، أدخل كلمة المرور الجديدة الآن'
                              : 'التحقق الآمن المباشر من صاحب الهاتف',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (_isCheckingSaved)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (!_isVerified) ...[
                // STEP 1: Account Confirmation & Biometric Check
                if (_phoneController.text.isNotEmpty && !_isManualPhoneEdit) ...[
                  // Account Preview Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.accentGold.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.accentGold.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_outline, color: AppTheme.accentGold, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_detectedUserName != null) ...[
                                Text(
                                  _detectedUserName!,
                                  style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ],
                              Text(
                                '${_country.code} ${_phoneController.text}',
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _isManualPhoneEdit = true),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(40, 30),
                          ),
                          child: Text(
                            'تغيير الرقم',
                            style: GoogleFonts.cairo(
                              color: AppTheme.accentGold,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Manual Phone Input Field
                  Row(
                    children: [
                      InkWell(
                        onTap: _showCountryPicker,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_country.flag, style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 6),
                              Text(
                                _country.code,
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.accentGold,
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down, size: 16),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'رقم الهاتف',
                            hintText: _country.hint,
                            prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),

                // Biometric Info Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.18)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: AppTheme.primary, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'يتم التحقق محلياً عبر بصمة إصبعك أو رمز قفل الشاشة المسجل في هاتفك، لضمان أعلى مستويات الأمان والسرعة.',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            height: 1.45,
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Action: Trigger Biometric
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleBiometricAuth,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.fingerprint, size: 24),
                  label: Text(
                    _isLoading ? 'جاري التحقق...' : 'تأكيد البصمة للمتابعة 👆',
                    style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                // STEP 2: New Password Creation
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified, color: Color(0xFF10B981), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'تم التحقق من هويتك بنجاح! أدخل كلمة المرور الجديدة لتطبيقها فوراً.',
                          style: GoogleFonts.cairo(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // New Password Field
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPass,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور الجديدة',
                    hintText: '6 خانات على الأقل',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNewPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureNewPass = !_obscureNewPass),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Confirm Password Field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPass,
                  decoration: InputDecoration(
                    labelText: 'تأكيد كلمة المرور الجديدة',
                    hintText: 'أعد كتابة كلمة المرور',
                    prefixIcon: const Icon(Icons.lock_reset_outlined, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                // Action: Save Password
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleSaveNewPassword,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined, size: 22),
                  label: Text(
                    _isLoading ? 'جاري حفظ كلمة المرور...' : 'حفظ كلمة المرور وتسجيل الدخول 🚀',
                    style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

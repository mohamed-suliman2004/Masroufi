import '../../core/services/update_service.dart';
import 'widgets/forgot_password_sheet.dart';
import '../../core/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../core/services/biometric_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/services/auth_service.dart';
import '../../core/state/app_state.dart';
import '../../core/models/country_code_model.dart';
import 'signup_screen.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  CountryCode _selectedCountry = supportedCountries.first; // Libya (+218)
  bool _loginWithEmail = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkAndPromptUpdate(context);
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String loginIdentifier;
    if (_loginWithEmail) {
      loginIdentifier = _emailController.text.trim();
    } else {
      var phone = _phoneController.text.trim().replaceAll(' ', '');
      // Strip leading zero if typed (e.g. 091... -> 91...)
      if (phone.startsWith('0')) {
        phone = phone.substring(1);
      }
      loginIdentifier = '${_selectedCountry.code}$phone';
    }

    try {
      final user = await AuthService.login(
        login: loginIdentifier,
        password: _passwordController.text,
      );

      AppState.instance.setUser(user);

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
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

  Future<void> _handleBiometricLogin() async {
    final isAvailable = await BiometricService.isBiometricAvailable();
    if (!isAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'مستشعر البصمة غير متوفر أو غير مسجل في إعدادات جهازك',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final savedUserJson = prefs.getString('masroufi_current_user') ?? prefs.getString('masroufi_saved_user');

    if (savedUserJson == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'يرجى تسجيل الدخول برقم هاتفك أولاً لتفعيل الدخول بالبصمة لحسابك',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: AppTheme.accentGold,
          ),
        );
      }
      return;
    }

    final success = await BiometricService.authenticate(
      reason: 'يرجى تأكيد بصمتك للدخول السريع لحسابك في مصروفي',
    );

    if (success) {
      try {
        final user = UserModel.fromJson(jsonDecode(savedUserJson));
        AppState.instance.setUser(user);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تعذر استرجاع بيانات الحساب، يرجى كتابة كلمة المرور', style: GoogleFonts.cairo()),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
        return;
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'فشلت المصادقة بالبصمة، يرجى المحاولة مجدداً',
              style: GoogleFonts.cairo(),
            ),
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
                    final isSelected = c.code == _selectedCountry.code;
                    return ListTile(
                      onTap: () {
                        setState(() => _selectedCountry = c);
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

  void _showForgotPasswordSheet() {
    String? initialPhone;
    if (!_loginWithEmail && _phoneController.text.trim().isNotEmpty) {
      var phone = _phoneController.text.trim().replaceAll(' ', '');
      if (phone.startsWith('0')) {
        phone = phone.substring(1);
      }
      initialPhone = '${_selectedCountry.code}$phone';
    } else if (_loginWithEmail && _emailController.text.trim().isNotEmpty) {
      initialPhone = _emailController.text.trim();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ForgotPasswordSheet(
        initialLogin: initialPhone,
        selectedCountry: _selectedCountry,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 10,
                left: 16,
                child: IconButton(
                  onPressed: () => setState(() => ThemeController.toggleTheme()),
                  tooltip: ThemeController.isDark ? 'الوضع النهاري' : 'الوضع الليلي',
                  icon: Icon(
                    ThemeController.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    color: ThemeController.isDark ? AppTheme.accentGold : AppTheme.primaryDark,
                    size: 22,
                  ),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withValues(alpha: 0.12),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.asset(
                                'assets/images/logo.jpg',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: Theme.of(context).cardColor,
                                  child: const Icon(Icons.account_balance_wallet, color: AppTheme.primary, size: 44),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'مصروفي',
                          style: GoogleFonts.cairo(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'تتبع حساباتك ونشاطاتك التجارية بالدينار الليبي',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),

                        // Form Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Toggle between Phone and Email
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _loginWithEmail ? 'تسجيل الدخول بالبريد' : 'تسجيل الدخول بالهاتف',
                                    style: GoogleFonts.cairo(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.accentGold,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => setState(() => _loginWithEmail = !_loginWithEmail),
                                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                                    child: Text(
                                      _loginWithEmail ? 'استخدم رقم الهاتف' : 'استخدم البريد الإلكتروني',
                                      style: GoogleFonts.cairo(fontSize: 11.5, color: AppTheme.darkTextMuted),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Phone or Email Input
                              if (!_loginWithEmail) ...[
                                Row(
                                  children: [
                                    // Country Code Selector
                                    InkWell(
                                      onTap: _showCountryPicker,
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        height: 52,
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).cardColor,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Theme.of(context).dividerColor),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(_selectedCountry.flag, style: const TextStyle(fontSize: 18)),
                                            const SizedBox(width: 4),
                                            Text(
                                              _selectedCountry.code,
                                              style: GoogleFonts.cairo(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).brightness == Brightness.dark
                                                    ? AppTheme.darkTextPrimary
                                                    : AppTheme.lightTextPrimary,
                                              ),
                                            ),
                                            const Icon(Icons.arrow_drop_down, size: 16, color: AppTheme.darkTextMuted),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Phone Number Input
                                    Expanded(
                                      child: TextFormField(
                                        controller: _phoneController,
                                        keyboardType: TextInputType.phone,
                                        decoration: InputDecoration(
                                          labelText: 'رقم الهاتف',
                                          hintText: _selectedCountry.hint,
                                          prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) {
                                            return 'يرجى إدخال رقم الهاتف';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    labelText: 'البريد الإلكتروني',
                                    hintText: 'name@example.com',
                                    prefixIcon: Icon(Icons.email_outlined, size: 20),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'يرجى إدخال البريد الإلكتروني';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                              const SizedBox(height: 16),

                              // Password Input (Completely empty initially)
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'كلمة المرور',
                                  hintText: '••••••••',
                                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'يرجى إدخال كلمة المرور';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),

                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: _showForgotPasswordSheet,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(50, 30),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'نسيت كلمة السر؟',
                                    style: GoogleFonts.cairo(
                                      color: AppTheme.accentGold,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                      )
                                    : const Text('دخول'),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text('أو', style: GoogleFonts.cairo(color: AppTheme.darkTextMuted, fontSize: 12)),
                                  ),
                                  Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                                ],
                              ),
                              const SizedBox(height: 14),
                              OutlinedButton.icon(
                                onPressed: _handleBiometricLogin,
                                icon: const Icon(Icons.fingerprint, color: AppTheme.primary, size: 22),
                                label: const Text('الدخول السريع / البصمة'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'ليس لديك حساب؟',
                              style: GoogleFonts.cairo(fontSize: 13),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const SignupScreen()),
                                );
                              },
                              child: Text(
                                'إنشاء حساب جديد',
                                style: GoogleFonts.cairo(
                                  color: AppTheme.accentGold,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

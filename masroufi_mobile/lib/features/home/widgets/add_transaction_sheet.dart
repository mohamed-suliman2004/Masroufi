import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';

class AddCashBottomSheet extends StatefulWidget {
  final Function(String title, double amount, String category, bool isExpense) onSave;

  const AddCashBottomSheet({super.key, required this.onSave});

  @override
  State<AddCashBottomSheet> createState() => _AddCashBottomSheetState();
}

class _AddCashBottomSheetState extends State<AddCashBottomSheet> {
  bool _isExpense = true;
  String _amountStr = '0';
  String _selectedCategory = 'تسوق';
  final TextEditingController _customCategoryController = TextEditingController();
  bool _saveToPermanentList = true;

  final List<String> _baseExpenseCategories = [
    'تسوق',
    'مطاعم ومقاهي',
    'وقود وسيارات',
    'صحة وأدوية',
    'فواتير واتصالات',
    'بقالة ومواد غذائية',
  ];

  final List<String> _baseIncomeCategories = [
    'دخل وراتب',
    'تحويلات مالية',
    'تجارة وأعمال',
  ];

  List<String> _customExpenseCategories = [];
  List<String> _customIncomeCategories = [];

  final List<int> _quickIncrements = [5, 10, 20, 50, 100, 500];

  @override
  void initState() {
    super.initState();
    _loadCustomCategories();
  }

  @override
  void dispose() {
    _customCategoryController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomCategories() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _customExpenseCategories = prefs.getStringList('masroufi_custom_cash_expense_cats') ?? [];
      _customIncomeCategories = prefs.getStringList('masroufi_custom_cash_income_cats') ?? [];
    });
  }

  Future<void> _saveCustomCategory(String name, bool isExpense) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    if (isExpense) {
      if (!_customExpenseCategories.contains(trimmed) && !_baseExpenseCategories.contains(trimmed)) {
        setState(() {
          _customExpenseCategories.add(trimmed);
        });
        await prefs.setStringList('masroufi_custom_cash_expense_cats', _customExpenseCategories);
      }
    } else {
      if (!_customIncomeCategories.contains(trimmed) && !_baseIncomeCategories.contains(trimmed)) {
        setState(() {
          _customIncomeCategories.add(trimmed);
        });
        await prefs.setStringList('masroufi_custom_cash_income_cats', _customIncomeCategories);
      }
    }
  }

  List<String> get _currentCategories {
    final baseList = _isExpense ? _baseExpenseCategories : _baseIncomeCategories;
    final customList = _isExpense ? _customExpenseCategories : _customIncomeCategories;
    return [...baseList, ...customList, 'أخرى'];
  }

  void _onKeypadTap(String key) {
    setState(() {
      if (key == 'backspace') {
        if (_amountStr.length > 1) {
          _amountStr = _amountStr.substring(0, _amountStr.length - 1);
        } else {
          _amountStr = '0';
        }
      } else if (key == '.') {
        if (!_amountStr.contains('.')) {
          _amountStr += '.';
        }
      } else {
        if (_amountStr == '0') {
          _amountStr = key;
        } else {
          // Limit to max 3 decimal digits
          if (_amountStr.contains('.')) {
            final parts = _amountStr.split('.');
            if (parts.length > 1 && parts[1].length >= 3) return;
          }
          if (_amountStr.length < 9) {
            _amountStr += key;
          }
        }
      }
    });
  }

  void _onQuickIncrement(int val) {
    setState(() {
      final current = double.tryParse(_amountStr) ?? 0.0;
      final newVal = current + val;
      _amountStr = newVal % 1 == 0 ? newVal.toInt().toString() : newVal.toStringAsFixed(3);
    });
  }

  void _onClear() {
    setState(() {
      _amountStr = '0';
    });
  }

  void _handleSave() {
    final amount = double.tryParse(_amountStr) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'يرجى إدخال مبلغ صحيح أكبر من الصفر',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    String finalCategory = _selectedCategory;
    String finalTitle = _selectedCategory;

    if (_selectedCategory == 'أخرى') {
      final customText = _customCategoryController.text.trim();
      if (customText.isNotEmpty) {
        finalCategory = customText;
        finalTitle = customText;
        if (_saveToPermanentList) {
          _saveCustomCategory(customText, _isExpense);
        }
      } else {
        finalCategory = 'أخرى';
        finalTitle = _isExpense ? 'مصروف كاش' : 'دخل كاش';
      }
    } else {
      finalTitle = _selectedCategory;
    }

    widget.onSave(finalTitle, amount, finalCategory, _isExpense);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).cardColor;
    final borderColor = Theme.of(context).dividerColor;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    final categories = _currentCategories;
    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = categories.first;
    }

    final themeColor = _isExpense ? AppTheme.danger : AppTheme.primary;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        top: false,
        bottom: true,
        child: Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            top: 16,
            left: 20,
            right: 20,
            bottom: 20 + bottomPadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title
              Text(
                'إضافة معاملة كاش',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 14),

              // Type Selector: Expense vs Income
              Container(
                height: 42,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkBackground : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isExpense = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: _isExpense ? AppTheme.danger : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Center(
                            child: Text(
                              'مصروف',
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _isExpense ? Colors.white : textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isExpense = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: !_isExpense ? AppTheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Center(
                            child: Text(
                              'دخل',
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: !_isExpense ? Colors.white : textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Amount Display Card
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkBackground : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Text(
                      _isExpense ? 'المبلغ المصروف' : 'المبلغ المستلم',
                      style: GoogleFonts.cairo(fontSize: 11, color: textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _amountStr,
                          style: GoogleFonts.cairo(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: _amountStr == '0' ? textSecondary : themeColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'د.ل',
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Quick Increments Bar
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildQuickBtn('مسح', isClear: true, onTap: _onClear, isDark: isDark),
                    ..._quickIncrements.map(
                      (val) => _buildQuickBtn('+$val', onTap: () => _onQuickIncrement(val), isDark: isDark),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Category Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkBackground : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    dropdownColor: surfaceColor,
                    isExpanded: true,
                    icon: Icon(Icons.keyboard_arrow_down, color: textSecondary),
                    style: GoogleFonts.cairo(color: textPrimary, fontSize: 13),
                    items: categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Row(
                          children: [
                            Icon(Icons.category_outlined, size: 16, color: textSecondary),
                            const SizedBox(width: 8),
                            Text(cat),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                ),
              ),

              // Custom Category Input Field (When 'أخرى' is selected)
              if (_selectedCategory == 'أخرى') ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkBackground : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _customCategoryController,
                        style: GoogleFonts.cairo(fontSize: 13, color: textPrimary),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'اكتب اسم البند أو التصنيف (مثال: حلاقة، جيم، إيجار...)',
                          hintStyle: GoogleFonts.cairo(
                            fontSize: 11.5,
                            color: textSecondary.withValues(alpha: 0.7),
                          ),
                          prefixIcon: const Icon(Icons.edit_note_rounded, size: 22, color: AppTheme.accentGold),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () => setState(() => _saveToPermanentList = !_saveToPermanentList),
                        borderRadius: BorderRadius.circular(6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _saveToPermanentList ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                              size: 16,
                              color: _saveToPermanentList ? AppTheme.accentGold : textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'حفظ هذا البند دائماً في القائمة للاستخدام لاحقاً',
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: _saveToPermanentList ? AppTheme.accentGold : textSecondary,
                                fontWeight: _saveToPermanentList ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),

              // Built-in Numeric Keypad
              _buildKeypad(isDark, borderColor, textPrimary),
              const SizedBox(height: 16),

              // Save Button (Protected from Navigation Bar)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(
                    'حفظ المعاملة',
                    style: GoogleFonts.cairo(fontSize: 14.5, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickBtn(String text, {required VoidCallback onTap, bool isClear = false, required bool isDark}) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isClear
                ? AppTheme.danger.withValues(alpha: 0.15)
                : (isDark ? AppTheme.darkBackground : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isClear ? AppTheme.danger.withValues(alpha: 0.4) : Theme.of(context).dividerColor,
            ),
          ),
          child: Text(
            text,
            style: GoogleFonts.cairo(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: isClear ? AppTheme.danger : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad(bool isDark, Color borderColor, Color textPrimary) {
    return Column(
      children: [
        _buildKeypadRow(['1', '2', '3'], isDark, borderColor, textPrimary),
        const SizedBox(height: 6),
        _buildKeypadRow(['4', '5', '6'], isDark, borderColor, textPrimary),
        const SizedBox(height: 6),
        _buildKeypadRow(['7', '8', '9'], isDark, borderColor, textPrimary),
        const SizedBox(height: 6),
        _buildKeypadRow(['.', '0', 'backspace'], isDark, borderColor, textPrimary),
      ],
    );
  }

  Widget _buildKeypadRow(List<String> keys, bool isDark, Color borderColor, Color textPrimary) {
    return Row(
      children: keys.map((k) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            height: 44,
            child: ElevatedButton(
              onPressed: () => _onKeypadTap(k),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFF8FAFC),
                foregroundColor: textPrimary,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: borderColor),
                ),
              ),
              child: k == 'backspace'
                  ? const Icon(Icons.backspace_outlined, size: 18)
                  : Text(
                      k,
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

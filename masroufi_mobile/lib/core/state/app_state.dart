import '../services/auth_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/bank_sender_model.dart';
import '../../features/home/widgets/transaction_tile.dart';
import '../services/receipt_service.dart';

class CategorySpending {
  final String name;
  final double amount;
  final double percentage;
  final Color color;

  const CategorySpending({
    required this.name,
    required this.amount,
    required this.percentage,
    required this.color,
  });
}

class BudgetCategory {
  final String name;
  final double spent;
  final double limit;
  final String status;
  final Color statusColor;

  const BudgetCategory({
    required this.name,
    required this.spent,
    required this.limit,
    required this.status,
    required this.statusColor,
  });

  double get ratio => limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
  int get percentageInt => (ratio * 100).toInt();
}

class AppState extends ChangeNotifier {
  static final AppState instance = AppState._internal();
  AppState._internal();

  UserModel? _currentUser;
  final Map<String, List<TransactionItem>> _userTransactionsStore = {};
  final List<BankSender> _customBanks = [];
  bool _isInitialized = false;
  bool _hasSeenOnboarding = false;
  bool get hasSeenOnboarding => _hasSeenOnboarding;

  // Selected Month State for monthly navigation (Defaults to Current/Latest Month)
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  DateTime get selectedMonth => _selectedMonth;

  bool get isCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year && _selectedMonth.month == now.month;
  }

  static const List<String> arabicMonths = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
  ];

  String get selectedMonthName => '${arabicMonths[_selectedMonth.month - 1]} ${_selectedMonth.year}';

  void nextMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    notifyListeners();
  }

  void previousMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    notifyListeners();
  }

  Future<void> setHasSeenOnboarding(bool val) async {
    _hasSeenOnboarding = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('masroufi_has_seen_onboarding', val);
    notifyListeners();
  }

  void resetToCurrentMonth() {
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    notifyListeners();
  }

  void selectMonth(DateTime month) {
    _selectedMonth = DateTime(month.year, month.month);
    notifyListeners();
  }

  static const List<BankSender> defaultBanks = [
    BankSender(name: 'المصرف التجاري الوطني', senderId: 'NCB'),
    BankSender(name: 'ون باي OnePay', senderId: 'OnePay'),
    BankSender(name: 'مصرف التجارة والتنمية', senderId: '18787'),
    BankSender(name: 'مصرف الجمهورية', senderId: 'Jumhouria'),
    BankSender(name: 'مصرف الوحدة', senderId: 'WahdaBank'),
    BankSender(name: 'مصرف الأمان', senderId: 'AmanBank'),
    BankSender(name: 'بنك شمال أفريقيا', senderId: 'NorthAfrica'),
    BankSender(name: 'مصرف الصحارى', senderId: 'SaharaBank'),
    BankSender(name: 'سداد Sadad', senderId: '10040'),
    BankSender(name: 'تداول Tadawul', senderId: '10020'),
    BankSender(name: 'موبي كاش', senderId: '12121'),
    BankSender(name: 'المصرف الإسلامي الليبي', senderId: 'IslamicBank'),
  ];

  List<BankSender> get allBankSenders => [...defaultBanks, ..._customBanks];
  List<BankSender> get customBanks => List.unmodifiable(_customBanks);

  Future<void> init() async {
    if (_isInitialized) return;
    final prefs = await SharedPreferences.getInstance();

    _hasSeenOnboarding = prefs.getBool('masroufi_has_seen_onboarding') ?? false;
    final userJsonStr = prefs.getString('masroufi_current_user');
    if (userJsonStr != null) {
      try {
        final parsedUser = UserModel.fromJson(jsonDecode(userJsonStr));
        if (parsedUser.name.isEmpty || parsedUser.name == 'مستخدم مصروفي') {
          final local = await AuthService.getUserFromLocalRegistry(parsedUser.phoneNumber.isNotEmpty ? parsedUser.phoneNumber : (parsedUser.email ?? ''));
          if (local != null && local.name.isNotEmpty && local.name != 'مستخدم مصروفي') {
            _currentUser = local;
          } else {
            _currentUser = parsedUser;
          }
        } else {
          _currentUser = parsedUser;
        }
      } catch (_) {}
    }

    // Auto-sync offline users to PostgreSQL backend silently
    if (_currentUser != null && _currentUser!.token == 'offline_local_token') {
      AuthService.syncOfflineUserIfNeeded().then((serverUser) {
        if (serverUser != null) {
          _currentUser = serverUser;
          notifyListeners();
        }
      });
    }

    final customBanksJson = prefs.getString('masroufi_custom_banks');
    if (customBanksJson != null) {
      try {
        final List list = jsonDecode(customBanksJson);
        _customBanks.clear();
        for (final item in list) {
          _customBanks.add(BankSender.fromJson(item));
        }
      } catch (_) {}
    }

    final activeKey = _getUserKey(currentUser);
    _loadTransactionsForUser(prefs, activeKey);
    _loadBudgetsForUser(prefs, activeKey);

    cleanDuplicateSettlements();
    _isInitialized = true;
    notifyListeners();
  }

  void _loadTransactionsForUser(SharedPreferences prefs, String userKey) {
    if (_userTransactionsStore.containsKey(userKey)) return;

    final raw = prefs.getString('masroufi_txs_$userKey');
    if (raw != null) {
      try {
        final List list = jsonDecode(raw);
        bool needsSave = false;
        final loaded = <TransactionItem>[];

        for (final item in list) {
          final tx = TransactionItem.fromJson(item);
          final lower = tx.title.toLowerCase();

          // Automatically purge legacy demo/mock transactions
          if (tx.title.contains('حلواني مذاقي') ||
              tx.title.contains('محطة بنزين الأندلس') ||
              (tx.title.contains('مصرف التجارة والتنمية') && tx.title.contains('إيداع') && tx.amount == 3200.0) ||
              (tx.title.contains('تحويل ون باي') && tx.amount == 290.0)) {
            needsSave = true;
            continue;
          }

          // Automatically purge erroneous future reminder / non-transaction messages
          if (lower.contains('سيتم تحصيل') ||
              lower.contains('سيتم خصم') ||
              lower.contains('سوف يتم') ||
              lower.contains('اشتراكك في vip') ||
              lower.contains('اشتراكك في') ||
              lower.contains('تذكير بموعد')) {
            needsSave = true;
            continue;
          }

          var cleanTitle = tx.title.trim();
          cleanTitle = cleanTitle.replaceAll(RegExp(r'^[\\s\\-–—.:•*]+'), '').trim();
          cleanTitle = cleanTitle.replaceAll(RegExp(r'[\\s\\-–—.:•*]+$'), '').trim();
          if (cleanTitle == 'تحويل ون باي - خصم' || cleanTitle == 'تحويل ون باي - إضافة') {
            cleanTitle = 'تحويل ون باي';
          }

          if (cleanTitle != tx.title) {
            needsSave = true;
            loaded.add(TransactionItem(
              title: cleanTitle.isNotEmpty ? cleanTitle : tx.title,
              category: tx.category,
              amount: tx.amount,
              isExpense: tx.isExpense,
              sourceBadge: tx.sourceBadge,
              timestamp: tx.timestamp,
              date: tx.date,
              icon: tx.icon,
              attachments: tx.attachments,
            ));
          } else {
            loaded.add(tx);
          }
        }

        _userTransactionsStore[userKey] = loaded;
        if (needsSave) {
          _saveTransactionsToPrefs(prefs, userKey, loaded);
        }
        return;
      } catch (_) {}
    }

    _userTransactionsStore[userKey] = <TransactionItem>[];
    _saveTransactionsToPrefs(prefs, userKey, <TransactionItem>[]);
  }

  void _saveTransactionsToPrefs(SharedPreferences prefs, String userKey, List<TransactionItem> list) {
    final jsonList = list.map((tx) => tx.toJson()).toList();
    prefs.setString('masroufi_txs_$userKey', jsonEncode(jsonList));
  }

  void _persistCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentUser != null) {
      prefs.setString('masroufi_current_user', jsonEncode(_currentUser!.toJson()));
    } else {
      prefs.remove('masroufi_current_user');
    }
  }

  Future<void> addCustomBank({required String name, required String senderId}) async {
    if (name.trim().isEmpty || senderId.trim().isEmpty) return;
    _customBanks.add(
      BankSender(
        name: name.trim(),
        senderId: senderId.trim(),
        isCustom: true,
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    final list = _customBanks.map((b) => b.toJson()).toList();
    await prefs.setString('masroufi_custom_banks', jsonEncode(list));

    notifyListeners();
  }

  Future<void> removeCustomBank(String senderId) async {
    _customBanks.removeWhere((b) => b.senderId == senderId);
    final prefs = await SharedPreferences.getInstance();
    final list = _customBanks.map((b) => b.toJson()).toList();
    await prefs.setString('masroufi_custom_banks', jsonEncode(list));
    notifyListeners();
  }

  String _getUserKey(UserModel user) {
    if (user.phoneNumber.isNotEmpty) return user.phoneNumber;
    if (user.email != null && user.email!.isNotEmpty) return user.email!;
    return 'default_user';
  }

  UserModel get currentUser => _currentUser ?? const UserModel(
    id: 0,
    name: '',
    phoneNumber: '',
    email: '',
  );

  bool get isLoggedIn => _currentUser != null;

  // All transactions of the active user (sorted newest first)
  List<TransactionItem> get transactions {
    final key = _getUserKey(currentUser);
    final list = _userTransactionsStore[key] ?? [];
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  // Transactions belonging to the currently selected month (sorted newest first)
  List<TransactionItem> get currentMonthTransactions {
    final list = transactions.where((tx) {
      return tx.timestamp.year == _selectedMonth.year && tx.timestamp.month == _selectedMonth.month;
    }).toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  // Monthly totals for selected month
  double get currentMonthIncome => currentMonthTransactions
      .where((tx) => !tx.isExpense)
      .fold(0.0, (sum, tx) => sum + tx.amount);

  double get currentMonthExpense => currentMonthTransactions
      .where((tx) => tx.isExpense)
      .fold(0.0, (sum, tx) => sum + tx.amount);

  double get currentMonthNetBalance => currentMonthIncome - currentMonthExpense;

  // Overall totals
  double get totalIncome =>
      transactions.where((tx) => !tx.isExpense).fold(0.0, (sum, tx) => sum + tx.amount);

  double get totalExpense =>
      transactions.where((tx) => tx.isExpense).fold(0.0, (sum, tx) => sum + tx.amount);

  double get netBalance => totalIncome - totalExpense;

  void setCurrentUser(UserModel user) {
    _currentUser = user;
    _persistCurrentUser();
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('masroufi_saved_user', jsonEncode(user.toJson()));
    });

    final key = _getUserKey(user);
    SharedPreferences.getInstance().then((prefs) {
      _loadTransactionsForUser(prefs, key);
      _loadBudgetsForUser(prefs, key);
      notifyListeners();
    });

    notifyListeners();
  }

  void setUser(UserModel user) => setCurrentUser(user);

  void updateCurrentUser({
    required String name,
    required String phoneNumber,
    String? email,
  }) {
    final oldKey = _getUserKey(currentUser);
    final updatedUser = UserModel(
      id: currentUser.id,
      name: name.trim(),
      phoneNumber: phoneNumber.trim(),
      email: (email != null && email.trim().isNotEmpty) ? email.trim() : null,
      token: currentUser.token,
    );

    final newKey = _getUserKey(updatedUser);
    if (oldKey != newKey && _userTransactionsStore.containsKey(oldKey)) {
      final existingTxs = _userTransactionsStore.remove(oldKey);
      if (existingTxs != null) {
        _userTransactionsStore[newKey] = existingTxs;
      }

      SharedPreferences.getInstance().then((prefs) {
        prefs.remove('masroufi_txs_$oldKey');
        if (existingTxs != null) {
          _saveTransactionsToPrefs(prefs, newKey, existingTxs);
        }
      });
    }

    _currentUser = updatedUser;
    _persistCurrentUser();

    SharedPreferences.getInstance().then((prefs) {
      try {
        final raw = prefs.getString('masroufi_users_registry');
        Map<String, dynamic> registry = {};
        if (raw != null && raw.isNotEmpty) {
          registry = jsonDecode(raw) as Map<String, dynamic>;
        }
        final jsonUser = updatedUser.toJson();
        if (updatedUser.phoneNumber.isNotEmpty) {
          registry[updatedUser.phoneNumber] = jsonUser;
        }
        if (updatedUser.email != null && updatedUser.email!.isNotEmpty) {
          registry[updatedUser.email!] = jsonUser;
        }
        prefs.setString('masroufi_users_registry', jsonEncode(registry));
      } catch (_) {}
    });

    notifyListeners();
  }

  bool hasTransaction({
    required double amount,
    required DateTime timestamp,
    String? title,
  }) {
    final key = _getUserKey(currentUser);
    final list = _userTransactionsStore[key] ?? [];

    for (final tx in list) {
      if ((tx.amount - amount).abs() < 0.001) {
        // 1. If timestamp is within 5 minutes of each other
        if (tx.timestamp.difference(timestamp).inMinutes.abs() <= 5) {
          return true;
        }
        // 2. If title matches exactly on same date
        if (title != null &&
            tx.title == title &&
            tx.timestamp.year == timestamp.year &&
            tx.timestamp.month == timestamp.month &&
            tx.timestamp.day == timestamp.day) {
          return true;
        }
        // 3. Smart Libyan Bank Settlement Matching (e.g. NCB "خدمة يسر" vs Merchant POS)
        // If same amount on the same day:
        if (tx.timestamp.year == timestamp.year &&
            tx.timestamp.month == timestamp.month &&
            tx.timestamp.day == timestamp.day) {
          final isTxGeneric = tx.title.contains('سحب نقدي') ||
              tx.title.contains('خدمة يسر') ||
              tx.title.contains('يسر');
          final isNewGeneric = (title != null) &&
              (title.contains('سحب نقدي') ||
                  title.contains('خدمة يسر') ||
                  title.contains('يسر'));

          // If one is generic settlement and the other is a specific merchant, they are duplicates!
          if (isTxGeneric || isNewGeneric) {
            return true;
          }
        }
      }
    }
    return false;
  }

  bool addTransactionIfNotExists({
    required String title,
    required double amount,
    required String category,
    required bool isExpense,
    String sourceBadge = 'SMS',
    String? bankName,
    DateTime? timestamp,
  }) {
    final effectiveTs = timestamp ?? DateTime.now();
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('سيتم تحصيل') ||
        lowerTitle.contains('سيتم خصم') ||
        lowerTitle.contains('سوف يتم') ||
        lowerTitle.contains('اشتراكك في vip') ||
        lowerTitle.contains('تذكير بموعد')) {
      return false; // Skip future promises and reminders
    }

    final key = _getUserKey(currentUser);
    final list = _userTransactionsStore[key] ?? [];

    // Check if an existing generic transaction on same date can be upgraded to merchant name!
    final isNewGeneric = title.contains('سحب نقدي') ||
        title.contains('خدمة يسر') ||
        title.contains('يسر');

    if (!isNewGeneric) {
      for (int i = 0; i < list.length; i++) {
        final tx = list[i];
        if ((tx.amount - amount).abs() < 0.001 &&
            tx.timestamp.year == effectiveTs.year &&
            tx.timestamp.month == effectiveTs.month &&
            tx.timestamp.day == effectiveTs.day) {
          final isTxGeneric = tx.title.contains('سحب نقدي') ||
              tx.title.contains('خدمة يسر') ||
              tx.title.contains('يسر') ||
              tx.title.startsWith('- ') ||
              tx.title.contains('تحويل ون باي -');
          if (isTxGeneric) {
            // Upgrade the generic transaction with the actual merchant title!
            list[i] = TransactionItem(
              title: title,
              amount: amount,
              category: category,
              isExpense: isExpense,
              sourceBadge: sourceBadge,
              bankName: bankName ?? tx.bankName,
              timestamp: tx.timestamp,
              date: tx.date,
              icon: _getCategoryIcon(category),
              attachments: tx.attachments,
            );
            SharedPreferences.getInstance().then((prefs) {
              _saveTransactionsToPrefs(prefs, key, list);
            });
            notifyListeners();
            return false; // Handled via upgrade, no new entry
          }
        }
      }
    }

    if (isNewGeneric) {
      for (int i = 0; i < list.length; i++) {
        final tx = list[i];
        if ((tx.amount - amount).abs() < 0.001 &&
            tx.timestamp.year == effectiveTs.year &&
            tx.timestamp.month == effectiveTs.month &&
            tx.timestamp.day == effectiveTs.day) {
          final isTxGeneric = tx.title.contains('سحب نقدي') ||
              tx.title.contains('خدمة يسر') ||
              tx.title.contains('يسر') ||
              tx.title.startsWith('- ');
          if (!isTxGeneric) {
            return false; // Already recorded under merchant name, do not duplicate!
          }
        }
      }
    }

    if (hasTransaction(amount: amount, timestamp: effectiveTs, title: title)) {
      return false; // Already exists, do not duplicate!
    }

    addTransaction(
      title: title,
      amount: amount,
      category: category,
      isExpense: isExpense,
      sourceBadge: sourceBadge,
      bankName: bankName,
      timestamp: effectiveTs,
    );
    return true;
  }

  void deleteTransaction(TransactionItem item) {
    // Delete any attached receipt files from storage
    for (final path in item.attachments) {
      ReceiptService.deleteReceiptFile(path);
    }

    final key = _getUserKey(currentUser);
    final list = _userTransactionsStore[key];
    if (list != null) {
      list.removeWhere((tx) =>
          tx.title == item.title &&
          (tx.amount - item.amount).abs() < 0.001 &&
          tx.timestamp == item.timestamp);
      SharedPreferences.getInstance().then((prefs) {
        _saveTransactionsToPrefs(prefs, key, list);
      });
      notifyListeners();
    }
  }


  /// Removes all transactions from previous months if user wants to start completely fresh from current month
  int purgePastMonthsTransactions() {
    final key = _getUserKey(currentUser);
    final list = _userTransactionsStore[key];
    if (list == null || list.isEmpty) return 0;

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final initialCount = list.length;
    list.removeWhere((tx) => tx.timestamp.isBefore(startOfMonth));
    final removedCount = initialCount - list.length;

    if (removedCount > 0) {
      SharedPreferences.getInstance().then((prefs) {
        _saveTransactionsToPrefs(prefs, key, list);
      });
      notifyListeners();
    }
    return removedCount;
  }

  void cleanDuplicateSettlements() {
    final key = _getUserKey(currentUser);
    final list = _userTransactionsStore[key];
    if (list == null || list.isEmpty) return;

    final toRemove = <TransactionItem>[];
    for (int i = 0; i < list.length; i++) {
      final a = list[i];
      for (int j = i + 1; j < list.length; j++) {
        final b = list[j];
        if ((a.amount - b.amount).abs() < 0.001 &&
            a.timestamp.year == b.timestamp.year &&
            a.timestamp.month == b.timestamp.month &&
            a.timestamp.day == b.timestamp.day) {
          final isAGeneric = a.title.contains('سحب نقدي') || a.title.contains('خدمة يسر') || a.title.contains('يسر');
          final isBGeneric = b.title.contains('سحب نقدي') || b.title.contains('خدمة يسر') || b.title.contains('يسر');

          if (isAGeneric && !isBGeneric) {
            toRemove.add(a);
          } else if (!isAGeneric && isBGeneric) {
            toRemove.add(b);
          }
        }
      }
    }

    if (toRemove.isNotEmpty) {
      list.removeWhere((item) => toRemove.contains(item));
      SharedPreferences.getInstance().then((prefs) {
        _saveTransactionsToPrefs(prefs, key, list);
      });
      notifyListeners();
    }
  }

  void addTransaction({
    required String title,
    required double amount,
    required String category,
    required bool isExpense,
    String sourceBadge = 'كاش',
    String? bankName,
    DateTime? timestamp,
    IconData? icon,
    List<String>? attachments,
  }) {
    final key = _getUserKey(currentUser);
    final list = _userTransactionsStore.putIfAbsent(key, () => []);

    IconData finalIcon = icon ??
        (isExpense ? _getCategoryIcon(category) : Icons.account_balance_wallet);

    final effectiveTs = timestamp ?? DateTime.now();
    final dateStr = TransactionItem.formatDisplayDate(effectiveTs);

    list.insert(
      0,
      TransactionItem(
        title: title,
        category: category,
        date: dateStr,
        timestamp: effectiveTs,
        amount: amount,
        isExpense: isExpense,
        sourceBadge: sourceBadge,
        icon: finalIcon,
        attachments: attachments ?? const [],
      ),
    );

    SharedPreferences.getInstance().then((prefs) {
      _saveTransactionsToPrefs(prefs, key, list);
    });

    notifyListeners();
  }


  Future<void> deleteAccountPermanently() async {
    // 1. Call backend API if user is authenticated
    if (_currentUser != null) {
      await AuthService.deleteAccount(currentUser: _currentUser!);
    }

    // 2. Delete all receipts for all transactions
    for (final txList in _userTransactionsStore.values) {
      for (final tx in txList) {
        for (final path in tx.attachments) {
          ReceiptService.deleteReceiptFile(path);
        }
      }
    }

    _userTransactionsStore.clear();
    _currentUser = null;

    // 3. Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('masroufi_current_user');
    await prefs.remove('masroufi_saved_user');
    await prefs.remove('masroufi_users_registry');

    // Remove any user transaction keys
    final keys = prefs.getKeys().where((k) => k.startsWith('masroufi_txs_') || k.startsWith('masroufi_budgets_')).toList();
    for (final k in keys) {
      await prefs.remove(k);
    }

    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _persistCurrentUser();
    notifyListeners();
  }

  List<CategorySpending> getCategoryBreakdown() {
    final expenses = currentMonthTransactions.where((tx) {
      if (!tx.isExpense) return false;
      final cat = tx.category.trim();
      // Exclude pure transfer categories from consumer spending breakdown
      if (cat == 'تحويلات ون باي' ||
          cat == 'تحويلات مالية' ||
          cat == 'تحويل مالي' ||
          cat == 'تحويلات') {
        return false;
      }
      return true;
    }).toList();

    if (expenses.isEmpty) {
      return [];
    }

    final double total = expenses.fold(0.0, (sum, tx) => sum + tx.amount);
    final Map<String, double> categoryMap = {};

    for (final tx in expenses) {
      categoryMap[tx.category] = (categoryMap[tx.category] ?? 0.0) + tx.amount;
    }

    final sortedEntries = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final colors = [
      const Color(0xFF38BDF8),
      const Color(0xFFF59E0B),
      const Color(0xFFA855F7),
      const Color(0xFF10B981),
      const Color(0xFFEC4899),
      const Color(0xFF6366F1),
      const Color(0xFF06B6D4),
      const Color(0xFF84CC16),
    ];

    int colorIdx = 0;
    return sortedEntries.map((e) {
      final pct = total > 0 ? (e.value / total) : 0.0;
      final c = colors[colorIdx % colors.length];
      colorIdx++;
      return CategorySpending(
        name: e.key,
        amount: e.value,
        percentage: pct,
        color: c,
      );
    }).toList();
  }

  List<BudgetCategory> getBudgets() {
    final expenses = currentMonthTransactions.where((tx) => tx.isExpense).toList();

    final Map<String, double> spentMap = {};
    for (final tx in expenses) {
      spentMap[tx.category] = (spentMap[tx.category] ?? 0.0) + tx.amount;
    }

    final userBudgets = budgetLimits;
    final List<BudgetCategory> result = [];

    for (final entry in userBudgets.entries) {
      final cat = entry.key;
      final limit = entry.value;
      final spent = spentMap[cat] ?? 0.0;

      String status;
      Color statusColor;

      if (limit > 0 && spent >= limit) {
        status = 'تجاوزت الحد';
        statusColor = const Color(0xFFEF4444);
      } else if (limit > 0 && spent >= limit * 0.8) {
        status = 'قريب من الحد';
        statusColor = const Color(0xFFF97316);
      } else {
        status = 'في الأمان';
        statusColor = const Color(0xFF10B981);
      }

      result.add(
        BudgetCategory(
          name: cat,
          spent: spent,
          limit: limit,
          status: status,
          statusColor: statusColor,
        ),
      );
    }

    return result;
  }

  // User Customizable Budgets
  static const Map<String, double> defaultBudgetLimits = {
    'تسوق': 300.0,
    'مطاعم ومقاهي': 400.0,
    'بقالة ومواد غذائية': 800.0,
    'وقود وسيارات': 500.0,
    'فواتير واتصالات': 300.0,
    'صحة وأدوية': 200.0,
  };

  final Map<String, Map<String, double>> _userBudgetLimitsStore = {};

  Map<String, double> get budgetLimits {
    final key = _getUserKey(currentUser);
    return Map.unmodifiable(_userBudgetLimitsStore.putIfAbsent(key, () => Map.from(defaultBudgetLimits)));
  }

  void _loadBudgetsForUser(SharedPreferences prefs, String userKey) {
    if (_userBudgetLimitsStore.containsKey(userKey)) return;
    final raw = prefs.getString('masroufi_budgets_');
    if (raw != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(raw);
        final Map<String, double> loaded = {};
        decoded.forEach((k, v) {
          loaded[k] = (v as num).toDouble();
        });
        _userBudgetLimitsStore[userKey] = loaded;
        return;
      } catch (_) {}
    }
    _userBudgetLimitsStore[userKey] = Map.from(defaultBudgetLimits);
  }

  void _saveBudgetsToPrefs(SharedPreferences prefs, String userKey, Map<String, double> map) {
    prefs.setString('masroufi_budgets_', jsonEncode(map));
  }

  void setBudgetLimit(String category, double limit) {
    final key = _getUserKey(currentUser);
    final map = _userBudgetLimitsStore.putIfAbsent(key, () => Map.from(defaultBudgetLimits));
    map[category] = limit;
    SharedPreferences.getInstance().then((prefs) {
      _saveBudgetsToPrefs(prefs, key, map);
    });
    notifyListeners();
  }

  void removeBudgetCategory(String category) {
    final key = _getUserKey(currentUser);
    final map = _userBudgetLimitsStore.putIfAbsent(key, () => Map.from(defaultBudgetLimits));
    map.remove(category);
    SharedPreferences.getInstance().then((prefs) {
      _saveBudgetsToPrefs(prefs, key, map);
    });
    notifyListeners();
  }

  void resetBudgetsToDefault() {
    final key = _getUserKey(currentUser);
    _userBudgetLimitsStore[key] = Map.from(defaultBudgetLimits);
    SharedPreferences.getInstance().then((prefs) {
      _saveBudgetsToPrefs(prefs, key, _userBudgetLimitsStore[key]!);
    });
    notifyListeners();
  }

  void updateTransactionCategory(TransactionItem item, String newCategory) {
    final key = _getUserKey(currentUser);
    final list = _userTransactionsStore[key];
    if (list == null) return;

    final idx = list.indexWhere((tx) =>
        tx.title == item.title &&
        (tx.amount - item.amount).abs() < 0.001 &&
        tx.timestamp == item.timestamp);

    if (idx != -1) {
      final old = list[idx];
      list[idx] = old.copyWith(
        category: newCategory,
        icon: _getCategoryIcon(newCategory),
      );
      SharedPreferences.getInstance().then((prefs) {
        _saveTransactionsToPrefs(prefs, key, list);
      });
      notifyListeners();
    }
  }

  static IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'تسوق':
        return Icons.shopping_bag_outlined;
      case 'مطاعم ومقاهي':
        return Icons.local_cafe_outlined;
      case 'وقود وسيارات':
        return Icons.local_gas_station_outlined;
      case 'صحة وأدوية':
        return Icons.medication_outlined;
      case 'فواتير واتصالات':
        return Icons.wifi;
      case 'بقالة ومواد غذائية':
        return Icons.shopping_cart_outlined;
      case 'تحويلات ون باي':
      case 'تحويلات مالية':
        return Icons.swap_horiz_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  

  TransactionItem? addAttachmentToTransaction(TransactionItem item, String filePath) {
    final key = _getUserKey(currentUser);
    final list = _userTransactionsStore[key];
    if (list == null) return null;

    final idx = list.indexWhere((tx) =>
        tx.title == item.title &&
        (tx.amount - item.amount).abs() < 0.001 &&
        tx.timestamp == item.timestamp);

    if (idx != -1) {
      final old = list[idx];
      final updated = old.copyWith(attachments: [...old.attachments, filePath]);
      list[idx] = updated;
      SharedPreferences.getInstance().then((prefs) {
        _saveTransactionsToPrefs(prefs, key, list);
      });
      notifyListeners();
      return updated;
    }
    return null;
  }

  TransactionItem? removeAttachmentFromTransaction(TransactionItem item, String filePath) {
    // Delete physical file from disk
    ReceiptService.deleteReceiptFile(filePath);

    final key = _getUserKey(currentUser);
    final list = _userTransactionsStore[key];
    if (list == null) return null;

    final idx = list.indexWhere((tx) =>
        tx.title == item.title &&
        (tx.amount - item.amount).abs() < 0.001 &&
        tx.timestamp == item.timestamp);

    if (idx != -1) {
      final old = list[idx];
      final updated = old.copyWith(
        attachments: old.attachments.where((p) => p != filePath).toList(),
      );
      list[idx] = updated;
      SharedPreferences.getInstance().then((prefs) {
        _saveTransactionsToPrefs(prefs, key, list);
      });
      notifyListeners();
      return updated;
    }
    return null;
  }

}

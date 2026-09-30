import 'package:flutter/material.dart';
import '../models/bank_sender_model.dart';
import '../../features/home/widgets/transaction_tile.dart';

class ParsedBankSms {
  final String bankName;
  final String senderId;
  final double amount;
  final bool isExpense;
  final String category;
  final String title;
  final String? merchant;
  final double? balanceAfter;
  final DateTime timestamp;
  final String rawBody;

  const ParsedBankSms({
    required this.bankName,
    required this.senderId,
    required this.amount,
    required this.isExpense,
    required this.category,
    required this.title,
    this.merchant,
    this.balanceAfter,
    required this.timestamp,
    required this.rawBody,
  });

  TransactionItem toTransactionItem() {
    final dateStr = TransactionItem.formatDisplayDate(timestamp);

    return TransactionItem(
      title: title,
      category: category,
      date: dateStr,
      timestamp: timestamp,
      amount: amount,
      isExpense: isExpense,
      sourceBadge: 'SMS',
      bankName: bankName,
      icon: _getCategoryIcon(category, isExpense),
    );
  }

  static IconData _getCategoryIcon(String category, bool isExpense) {
    if (!isExpense) return Icons.account_balance_wallet_outlined;
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
}

class LibyanBankSmsParser {
  /// Converts Eastern Arabic numerals (٠-٩) to Western (0-9)
  static String normalizeDigits(String text) {
    const eastern = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const western = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    var res = text;
    for (int i = 0; i < eastern.length; i++) {
      res = res.replaceAll(eastern[i], western[i]);
    }
    return res;
  }

  /// Matches incoming sender strictly against registered bank / service Sender ID
  static bool matchesSender(String incomingSender, String registeredSenderId) {
    if (incomingSender.isEmpty || registeredSenderId.isEmpty) return false;

    final inClean = incomingSender.trim().toLowerCase();
    final regClean = registeredSenderId.trim().toLowerCase();

    // 1. Exact case-insensitive match
    if (inClean == regClean) return true;

    // 2. Normalize Libyan prefixes (+218, 00218, or leading 0)
    final inNorm = inClean.replaceAll(RegExp(r'^(?:\+218|00218|0)'), '');
    final regNorm = regClean.replaceAll(RegExp(r'^(?:\+218|00218|0)'), '');
    if (inNorm.isNotEmpty && inNorm == regNorm) return true;

    // 3. Substring match for alphanumeric IDs with length >= 3
    if (regClean.length >= 3 && inClean.contains(regClean)) return true;
    if (inClean.length >= 3 && regClean.contains(inClean)) return true;

    // 4. Known Libyan bank aliases when that bank is registered
    final bankAliases = {
      'ncb': ['11100', 'ncb', 'ncbbank', 'onepay'],
      '11100': ['ncb', 'ncbbank', '11100'],
      'onepay': ['onepay', 'ncb', '11100'],
      '18787': ['18787', 'bcd', 'bcdbank', 'commerce', 'تجارة', 'التنمية', 'التجارة والتنمية'],
      'bcd': ['18787', 'bcd', 'bcdbank', 'commerce', 'تجارة', 'التنمية', 'التجارة والتنمية'],
      'jumhouria': ['jumhouria', '11200', 'jumhouriabank'],
      '11200': ['jumhouria', '11200'],
      'wahdabank': ['wahdabank', 'wahda', '11300'],
      '11300': ['wahdabank', 'wahda', '11300'],
      'amanbank': ['amanbank', 'aman', '10010'],
      '10010': ['amanbank', 'aman', '10010'],
      'northafrica': ['northafrica', '16000', 'nab', 'nbd'],
      '16000': ['northafrica', '16000'],
      'saharabank': ['saharabank', 'sahara', '15000'],
      '15000': ['saharabank', 'sahara', '15000'],
      '10040': ['10040', 'sadad'],
      'sadad': ['10040', 'sadad'],
      '10020': ['10020', 'tadawul'],
      'tadawul': ['10020', 'tadawul'],
      '12121': ['12121', 'mobicash'],
      'mobicash': ['12121', 'mobicash'],
    };

    final aliases = bankAliases[regClean];
    if (aliases != null) {
      for (final a in aliases) {
        if (inClean == a || inClean.contains(a) || inNorm == a) {
          return true;
        }
      }
    }

    return false;
  }

  /// Matches an incoming SMS strictly against Libyan Bank Rules and user registered banks
  static ParsedBankSms? parse({
    required String sender,
    required String body,
    required List<BankSender> registeredBanks,
    DateTime? timestamp,
  }) {
    final cleanSender = sender.trim();
    final cleanBody = normalizeDigits(body.trim());

    if (cleanSender.isEmpty || cleanBody.isEmpty) {
      return null;
    }

    // 1. Filter out OTP, verification codes, future reminders, and promotional SMS immediately!
    if (isIgnoredMessage(cleanBody)) {
      return null;
    }

    // 2. Identify bank STRICTLY from sender ID against registeredBanks
    BankSender? matchedBank;
    for (final bank in registeredBanks) {
      if (matchesSender(cleanSender, bank.senderId)) {
        matchedBank = bank;
        break;
      }
    }

    // CRITICAL REQUIREMENT: If sender does NOT match any supported / registered service, REJECT!
    // Never monitor or record SMS from unknown entities or unlisted senders!
    if (matchedBank == null) {
      return null;
    }

    // 3. Extract Transaction Amount (Ignoring balance lines like "رصيدكم: ...")
    final amount = _extractAmount(cleanBody);
    if (amount == null || amount <= 0) {
      return null;
    }

    // 4. Extract Optional Balance After transaction
    final balanceAfter = _extractBalance(cleanBody);

    // 5. Determine if Operation is Expense or Income (Crucial for Bank Transfers)
    final isExpense = _isExpenseOperation(cleanBody);

    // 6. Extract Merchant or POS or Service name if present
    final merchant = _extractMerchant(cleanBody);

    // 7. Deduce Category
    final category = _deduceCategory(cleanBody, merchant, isExpense);

    // 8. Generate Clear, Readable Libyan Title
    final title = _generateTitle(cleanBody, matchedBank.name, merchant, isExpense);

    // 9. Extract Date from SMS body or default to incoming timestamp / now
    final effectiveTimestamp = _extractDate(cleanBody, timestamp);

    return ParsedBankSms(
      bankName: matchedBank.name,
      senderId: matchedBank.senderId,
      amount: amount,
      isExpense: isExpense,
      category: category,
      title: title,
      merchant: merchant,
      balanceAfter: balanceAfter,
      timestamp: effectiveTimestamp,
      rawBody: cleanBody,
    );
  }

  /// Checks if message is an OTP, verification code, future promise, or non-transaction notification
  static bool isIgnoredMessage(String body) {
    final lower = body.toLowerCase();

    // 1. OTP, verification codes, temporary passwords
    if (lower.contains('otp') ||
        lower.contains('كلمة المرور المؤقتة') ||
        lower.contains('رمز التحقق') ||
        lower.contains('كود التحقق') ||
        lower.contains('رمز التأكيد') ||
        lower.contains('رمز الدخول') ||
        lower.contains('كود الدخول') ||
        lower.contains('كود التفعيل') ||
        lower.contains('رمز التفعيل') ||
        lower.contains('يرجى عدم مشاركة') ||
        lower.contains('لا تشارك هذا الرمز') ||
        lower.contains('@smartbank #')) {
      return true;
    }

    // 2. Future reminders, upcoming subscription / bill charges (NOT completed transactions)
    if (lower.contains('سيتم تحصيل') ||
        lower.contains('سيتم خصم') ||
        lower.contains('سوف يتم خصم') ||
        lower.contains('سوف يتم تحصيل') ||
        lower.contains('سوف يتم') ||
        lower.contains('تذكير بموعد') ||
        lower.contains('تذكير:') ||
        lower.contains('تذكير :') ||
        lower.contains('لتجديد اشتراكك') ||
        lower.contains('يرجى سداد') ||
        lower.contains('فاتورتك القادمة') ||
        lower.contains('موعد استحقاق') ||
        lower.contains('اشتراكك في vip') ||
        lower.contains('اشتراكك في')) {
      return true;
    }

    // 3. Marketing / Promotional
    if (lower.contains('مبروك لقد ربحت') ||
        lower.contains('عرض خاص') ||
        lower.contains('اشترك الآن') ||
        lower.contains('اشترك الان') ||
        lower.contains('باقات جديدة')) {
      return true;
    }

    return false;
  }

  /// Backwards compatibility alias for tests
  static bool isOtpMessage(String body) => isIgnoredMessage(body);

  static DateTime _extractDate(String body, DateTime? incomingTimestamp) {
    final match = RegExp(r'(\d{1,2})[-/](\d{1,2})[-/](\d{2,4})').firstMatch(body);
    if (match != null) {
      try {
        int d = int.parse(match.group(1)!);
        int m = int.parse(match.group(2)!);
        int y = int.parse(match.group(3)!);
        if (y < 100) y += 2000;
        final now = DateTime.now();
        return DateTime(y, m, d, incomingTimestamp?.hour ?? now.hour, incomingTimestamp?.minute ?? now.minute);
      } catch (_) {}
    }
    return incomingTimestamp ?? DateTime.now();
  }

  static double? _extractAmount(String body) {
    // 1. Remove balance parts first to avoid picking up the account balance
    var scrubbed = body.replaceAll(
      RegExp(r'(?:رصيدكم|الرصيد|رصيد الحساب|المتاح|الرصيد المتاح|الرصيد الحالي|balance|bal)[^\n\r,;]*(?:د\.ل|دينار|lyd|د)?', caseSensitive: false),
      '',
    );

    // 2. Search for explicit amount markers first (e.g. بقيمة 120 د.ل, خصم 50.000)
    final markedPattern = RegExp(
      r'(?:بقيمة|قيمة|مبلغ|خصم|إضافة|اضافة|سحب|شراء|تحويل|توريد|تعبئة|سداد)\s*[:：\-/]?\s*\(?([0-9]+(?:\.[0-9]+)?)\)?\s*(?:د\.ل|دينار|lyd|د)?',
      caseSensitive: false,
    );
    final m1 = markedPattern.firstMatch(scrubbed);
    if (m1 != null && m1.group(1) != null) {
      final val = double.tryParse(m1.group(1)!);
      if (val != null && val > 0 && val < 5000000) {
        return val;
      }
    }

    // 3. Search for amount preceding or following currency (e.g. 120 د.ل, 120.000 دينار)
    final currPattern = RegExp(
      r'(?:\(?([0-9]+(?:\.[0-9]+)?)\)?\s*(?:د\.ل|دينار|lyd)|(?:د\.ل|دينار|lyd)\s*\(?([0-9]+(?:\.[0-9]+)?)\)?)',
      caseSensitive: false,
    );
    final m2 = currPattern.firstMatch(scrubbed);
    if (m2 != null) {
      final valStr = m2.group(1) ?? m2.group(2);
      if (valStr != null) {
        final val = double.tryParse(valStr);
        if (val != null && val > 0 && val < 5000000) {
          return val;
        }
      }
    }

    // 4. Fallback: Any standalone number if body contains financial keywords
    final fallbackPattern = RegExp(r'\b([0-9]+(?:\.[0-9]+)?)\b');
    for (final match in fallbackPattern.allMatches(scrubbed)) {
      final valStr = match.group(1);
      if (valStr != null) {
        final val = double.tryParse(valStr);
        // Exclude years, card numbers, short codes
        if (val != null && val > 0 && val < 5000000 && val != 2024 && val != 2025 && val != 2026 && val != 2027) {
          return val;
        }
      }
    }

    return null;
  }

  static double? _extractBalance(String body) {
    final balancePattern = RegExp(
      r'(?:رصيدكم|الرصيد|رصيد الحساب|المتاح|الرصيد المتاح|الرصيد الحالي|balance|bal)\s*[:：\-]?\s*([0-9]+(?:\.[0-9]+)?)',
      caseSensitive: false,
    );
    final match = balancePattern.firstMatch(body);
    if (match != null && match.group(1) != null) {
      return double.tryParse(match.group(1)!);
    }
    return null;
  }

  static bool _isExpenseOperation(String body) {
    final lower = body.toLowerCase();

    // 1. Explicit credit/deposit checks
    if (lower.contains('إيداع') ||
        lower.contains('ايداع') ||
        lower.contains('تحويل وارد') ||
        lower.contains('تحويل إليكم') ||
        lower.contains('تحويل اليكم') ||
        lower.contains('تم استلام') ||
        lower.contains('استلام حوالة') ||
        lower.contains('مرتب') ||
        lower.contains('تغذية حساب') ||
        lower.contains('قيد مبلغ') ||
        lower.contains('قيد لحسابكم') ||
        lower.contains('وارد لحسابكم')) {
      return false;
    }

    // 2. Explicit debit/withdrawal checks
    if (lower.contains('خصم بقيمة') ||
        lower.contains('تم خصم') ||
        lower.contains('خصم قيمة') ||
        lower.contains('تحويل صادر') ||
        lower.contains('تحويل من حسابكم') ||
        lower.contains('تم التحويل إلى') ||
        lower.contains('تم التحويل الى') ||
        lower.contains('سحب') ||
        lower.contains('شراء') ||
        lower.contains('دفع تاجر') ||
        lower.contains('سداد فاتورة')) {
      return true;
    }

    if (lower.contains('إضافة') || lower.contains('اضافة')) {
      return false;
    }

    return true;
  }

  /// Extracts Merchant / POS / Recipient name accurately
  static String? _extractMerchant(String body) {
    // 0. BCD pattern: First line is merchant name, followed by 'القيمة' or 'سلم البائع'
    final lines = body.trim().split(RegExp(r'[\r\n]+')).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.length >= 2) {
      final line0 = lines[0];
      final line1 = lines[1];
      final isBcdFormat = body.contains('سلم البائع') ||
          (RegExp(r'^(?:القيمة|قيمة)\s*[0-9]+', caseSensitive: false).hasMatch(line1) &&
              !RegExp(r'^(?:سحب|إيداع|ايداع|رصيد|wabs)', caseSensitive: false).hasMatch(line0));
      if (isBcdFormat) {
        if (!RegExp(r'(?:سحب|إيداع|ايداع|رصيدكم|رصيد|wabs)', caseSensitive: false).hasMatch(line0) &&
            line0.length >= 2 &&
            line0.length <= 50) {
          return line0;
        }
      }
    }

    final patterns = [
      // 1. Compound & explicit merchant keywords
      RegExp(r'(?:لدى متجر|لدى محل|لدى التاجر|إلى التاجر|الى التاجر|نقطة بيع|التاجر|المتجر|متجر|محل|لدى)\s*[:：\-/]?\s*([^\n\r,]+)', caseSensitive: false),
      // 2. Transfer recipients / beneficiaries
      RegExp(r'(?:إلى المشترك|الى المشترك|المشترك|لصالح|المستفيد|تحويل إلى|تحويل الى|تم التحويل إلى|تم التحويل الى)\s*[:：\-/]?\s*([^\n\r,]+)', caseSensitive: false),
      // 3. Sender in transfer
      RegExp(r'(?:تحويل وارد من|تحويل من|من المشترك|من حساب)\s*[:：\-/]?\s*([^\n\r,]+)', caseSensitive: false),
    ];

    for (final p in patterns) {
      final m = p.firstMatch(body);
      if (m != null && m.groupCount >= 1) {
        String? res = m.group(1)?.trim();
        if (res != null && res.isNotEmpty) {
          // Strip trailing metadata & dates & account details
          res = res.replaceAll(RegExp(r'\s+(بنجاح|بتاريخ.*|بقيمة.*|عبر.*|رقم.*|بطاقة.*|من حسابكم.*|رصيدكم.*|الرصيد.*|\d{1,2}[-/]\d{1,2}.*)$', caseSensitive: false), '').trim();
          res = res.replaceAll(RegExp(r'[:：\-./]+$'), '').trim();
          res = res.replaceAll(RegExp(r'^[\s\-–—.:•*]+'), '').trim();
          // Strip inner prefixes if matched greedily
          res = res.replaceAll(RegExp(r'^(?:متجر|محل|التاجر|نقطة بيع)\s*[:：\-/]?\s*', caseSensitive: false), '').trim();
          if (res.isNotEmpty && res.length >= 2 && res.length <= 50) {
            return res;
          }
        }
      }
    }
    return null;
  }

  /// Generates clean, user-friendly Libyan titles
  static String _generateTitle(String body, String bankName, String? merchant, bool isExpense) {
    final lower = body.toLowerCase();
    String title;

    // 1. OnePay Transfers: user specifically requested:
    // "ورسايل تحويل يكتب تحويل ون باي بس عادي سواء خصم او اضافه"
    if (lower.contains('ون باي') || lower.contains('onepay')) {
      if (merchant != null && merchant.isNotEmpty && !merchant.contains('ون باي') && !merchant.contains('onepay')) {
        title = merchant;
      } else {
        title = 'تحويل ون باي';
      }
    } else if (merchant != null && merchant.isNotEmpty) {
      // 2. Merchant / Store POS title (e.g. سنتر الفرجاني, سوق حور مول)
      title = merchant;
    } else if (lower.contains('سداد') || lower.contains('sadad')) {
      title = isExpense ? 'خدمة سداد' : 'شحن سداد';
    } else if (lower.contains('تداول') || lower.contains('tadawul')) {
      title = isExpense ? 'بطاقة تداول' : 'تداول - استرجاع';
    } else if (lower.contains('تحويل') || lower.contains('transfer')) {
      title = isExpense ? 'تحويل صادر' : 'تحويل وارد';
    } else if (lower.contains('تعبئة') || lower.contains('شحن رصيد')) {
      title = 'تعبئة رصيد';
    } else if (isExpense) {
      title = lower.contains('شراء') ? 'مشتريات POS' : 'سحب نقدي';
    } else {
      title = lower.contains('مرتب') ? 'إيداع مرتب' : 'إيداع نقدي';
    }

    // Clean title from any leading/trailing symbols or punctuation
    title = title.replaceAll(RegExp(r'^[\s\-–—.:•*]+'), '').trim();
    title = title.replaceAll(RegExp(r'[\s\-–—.:•*]+$'), '').trim();
    return title.isNotEmpty ? title : (isExpense ? 'سحب نقدي' : 'إيداع نقدي');
  }

  static String _deduceCategory(String body, String? merchant, bool isExpense) {
    if (!isExpense) return 'دخل وراتب';

    final text = '$body ${merchant ?? ""}'.toLowerCase();

    if (text.contains('بريستو') || text.contains('presto')) {
      return 'مطاعم ومقاهي';
    }
    if (text.contains('كليك') || text.contains('click')) {
      return 'تسوق';
    }

    // 1. OnePay transfers
    if (text.contains('ون باي') || text.contains('onepay')) {
      return 'تحويلات ون باي';
    }

    // 2. Cafes, sweets, and restaurants
    if (text.contains('حلواني') ||
        text.contains('مذاقي') ||
        text.contains('حلويات') ||
        text.contains('كافي') ||
        text.contains('قهوة') ||
        text.contains('مطعم') ||
        text.contains('شاورما') ||
        text.contains('وجبات') ||
        text.contains('بيتزا') ||
        text.contains('فطائر') ||
        text.contains('مشويات') ||
        text.contains('مأكولات') ||
        text.contains('سناك')) {
      return 'مطاعم ومقاهي';
    }

    // 3. Shopping malls, centers, clothing, shoes, boutiques, electronics
    if (text.contains('مول') ||
        text.contains('سنتر') ||
        text.contains('ملابس') ||
        text.contains('أحذية') ||
        text.contains('بوتيك') ||
        text.contains('عطور') ||
        text.contains('ساعات') ||
        text.contains('أجهزة') ||
        text.contains('إلكترونيات') ||
        text.contains('محل') ||
        text.contains('متجر')) {
      return 'تسوق';
    }

    // 4. Groceries, supermarkets, butchers, bakeries
    if (text.contains('سوق') ||
        text.contains('ماركت') ||
        text.contains('سوبر ماركت') ||
        text.contains('غذائية') ||
        text.contains('خضار') ||
        text.contains('خضروات') ||
        text.contains('لحوم') ||
        text.contains('قصاب') ||
        text.contains('مخبز') ||
        text.contains('أجبان')) {
      return 'بقالة ومواد غذائية';
    }

    // 5. Fuel and automotive
    if (text.contains('بنزين') ||
        text.contains('وقود') ||
        text.contains('محطة') ||
        text.contains('نفط') ||
        text.contains('سيارات') ||
        text.contains('غسيل سيارات') ||
        text.contains('قطع غيار')) {
      return 'وقود وسيارات';
    }

    // 6. Health and pharmacies
    if (text.contains('صيدلية') ||
        text.contains('مستشفى') ||
        text.contains('دواء') ||
        text.contains('أدوية') ||
        text.contains('عيادة') ||
        text.contains('مختبر') ||
        text.contains('طبي') ||
        text.contains('أسنان')) {
      return 'صحة وأدوية';
    }

    // 7. Telecom and utilities
    if (text.contains('مدار') ||
        text.contains('لبيانا') ||
        text.contains('ليبيانا') ||
        text.contains('نت') ||
        text.contains('انترنت') ||
        text.contains('فاتورة') ||
        text.contains('كهرباء') ||
        text.contains('شحن رصيد') ||
        text.contains('تعبئة') ||
        text.contains('كروت')) {
      return 'فواتير واتصالات';
    }

    // 8. General transfers
    if (text.contains('تحويل') || text.contains('transfer')) {
      return 'تحويلات مالية';
    }

    return 'تسوق';
  }
}

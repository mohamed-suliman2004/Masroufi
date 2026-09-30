import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class TransactionItem {
  final String title;
  final String category;
  final String date;
  final DateTime timestamp;
  final double amount;
  final bool isExpense;
  final String sourceBadge;
  final String? bankName;
  final IconData icon;
  final List<String> attachments;

  TransactionItem({
    required this.title,
    required this.category,
    required this.date,
    DateTime? timestamp,
    required this.amount,
    required this.isExpense,
    required this.sourceBadge,
    this.bankName,
    required this.icon,
    List<String>? attachments,
  })  : timestamp = timestamp ?? DateTime.now(),
        attachments = attachments ?? const [];

  TransactionItem copyWith({
    String? title,
    String? category,
    String? date,
    DateTime? timestamp,
    double? amount,
    bool? isExpense,
    String? sourceBadge,
    String? bankName,
    IconData? icon,
    List<String>? attachments,
  }) {
    return TransactionItem(
      title: title ?? this.title,
      category: category ?? this.category,
      date: date ?? this.date,
      timestamp: timestamp ?? this.timestamp,
      amount: amount ?? this.amount,
      isExpense: isExpense ?? this.isExpense,
      sourceBadge: sourceBadge ?? this.sourceBadge,
      bankName: bankName ?? this.bankName,
      icon: icon ?? this.icon,
      attachments: attachments ?? this.attachments,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'category': category,
        'date': date,
        'timestamp': timestamp.toIso8601String(),
        'amount': amount,
        'isExpense': isExpense,
        'sourceBadge': sourceBadge,
        'bankName': bankName,
        'iconCodePoint': icon.codePoint,
        'attachments': attachments,
      };

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    final cat = json['category'] as String? ?? 'عام';
    final isExp = json['isExpense'] as bool? ?? true;
    final tsStr = json['timestamp'] as String?;
    final ts = tsStr != null ? (DateTime.tryParse(tsStr) ?? DateTime.now()) : DateTime.now();
    final d = json['date'] as String? ?? formatDisplayDate(ts);
    final attachList = (json['attachments'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];

    final rawBadge = json['sourceBadge'] as String? ?? 'كاش';
    String finalBadge = 'كاش';
    String? bank = json['bankName'] as String?;

    if (rawBadge == 'SMS') {
      finalBadge = 'SMS';
    } else if (rawBadge == 'كاش' || rawBadge == 'يدوي') {
      finalBadge = 'كاش';
    } else {
      // Old badge where bank name was saved as sourceBadge (e.g. 'NCB')
      finalBadge = 'SMS';
      bank ??= rawBadge;
    }

    return TransactionItem(
      title: json['title'] as String? ?? '',
      category: cat,
      date: d,
      timestamp: ts,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      isExpense: isExp,
      sourceBadge: finalBadge,
      bankName: bank,
      icon: _resolveIcon(cat, isExp),
      attachments: attachList,
    );
  }

  static String formatDisplayDate(DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day;

    final months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    final monthName = months[dt.month - 1];

    if (isToday) {
      return 'اليوم ${dt.day} $monthName';
    } else if (isYesterday) {
      return 'أمس ${dt.day} $monthName';
    } else {
      if (dt.year == now.year) {
        return '${dt.day.toString().padLeft(2, '0')} $monthName';
      } else {
        return '${dt.day.toString().padLeft(2, '0')} $monthName ${dt.year}';
      }
    }
  }

  static IconData _resolveIcon(String category, bool isExpense) {
    if (!isExpense) return Icons.account_balance_wallet_outlined;
    switch (category) {
      case 'تسوق':
        return Icons.shopping_bag_outlined;
      case 'مطاعم ومقاهي':
        return Icons.local_cafe_outlined;
      case 'مواصلات ووقود':
        return Icons.local_gas_station_outlined;
      case 'صحة وعلاج':
        return Icons.medication_outlined;
      case 'فواتير':
        return Icons.wifi;
      case 'بقالة ومواد غذائية':
        return Icons.shopping_cart_outlined;
      case 'تحويلات مالية':
      case 'تحويلات ون باي':
        return Icons.swap_horiz_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }
}

class TransactionTile extends StatelessWidget {
  final TransactionItem item;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.item,
    this.onTap,
  });

  String _buildSubtitle(TransactionItem item) {
    final bank = item.bankName?.trim();
    if (bank != null && bank.isNotEmpty) {
      return '${item.category} • $bank • ${item.date}';
    }
    return '${item.category} • ${item.date}';
  }

  @override
  Widget build(BuildContext context) {
    final bool isSms = item.sourceBadge == 'SMS';
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = Theme.of(context).cardColor;
    final borderColor = Theme.of(context).dividerColor;
    final iconBgColor = isDark ? AppTheme.darkBackground : const Color(0xFFF1F5F9);
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Icon Container
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: textSecondary, size: 20),
                ),
                const SizedBox(width: 12),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(_buildSubtitle(item),
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (item.attachments.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.receipt_outlined, size: 10.5, color: AppTheme.primary),
                                  const SizedBox(width: 2.5),
                                  Text(
                                    '${item.attachments.length}',
                                    style: GoogleFonts.cairo(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Amount & Badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${item.isExpense ? '-' : '+'}${item.amount.toStringAsFixed(3)}',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: item.isExpense
                            ? (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary)
                            : AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isSms
                            ? const Color(0xFF38BDF8).withValues(alpha: 0.15)
                            : AppTheme.accentGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.sourceBadge,
                        style: GoogleFonts.cairo(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: isSms ? const Color(0xFF0284C7) : AppTheme.accentGold,
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
    );
  }
}

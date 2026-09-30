import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/services/receipt_service.dart';
import '../../home/widgets/transaction_tile.dart';
import 'receipt_preview_dialog.dart';

Future<void> showTransactionActionSheet(
  BuildContext context,
  TransactionItem initialTx, {
  VoidCallback? onDeleted,
  ValueChanged<TransactionItem>? onUpdated,
}) async {
  TransactionItem currentTx = initialTx;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
      final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

      return SafeArea(
        top: false,
        child: StatefulBuilder(
          builder: (sheetContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header: Title & Amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentTx.title,
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${currentTx.category} • ${currentTx.date}',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${currentTx.isExpense ? "-" : "+"}${currentTx.amount.toStringAsFixed(3)} د.ل',
                        style: GoogleFonts.cairo(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: currentTx.isExpense ? AppTheme.danger : AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Receipts / Invoices Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.receipt_long_outlined, size: 18, color: AppTheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            'الفواتير والمرفقات (${currentTx.attachments.length})',
                            style: GoogleFonts.cairo(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                      if (currentTx.attachments.isNotEmpty)
                        Text(
                          'اضغط للتكبير والمعاينة',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: textSecondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Horizontal Thumbnails & Add Button
                  SizedBox(
                    height: 90,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        // "+ إضافة فاتورة" Card Button
                        GestureDetector(
                          onTap: () async {
                            _showImageSourcePicker(context, (fromCamera) async {
                              final path = await ReceiptService.pickAndSaveReceipt(fromCamera: fromCamera);
                              if (path != null) {
                                final updated = AppState.instance.addAttachmentToTransaction(currentTx, path);
                                if (updated != null) {
                                  setModalState(() => currentTx = updated);
                                  onUpdated?.call(updated);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'تمت إضافة صورة الفاتورة بنجاح',
                                          style: GoogleFonts.cairo(fontSize: 12),
                                        ),
                                        backgroundColor: AppTheme.primary,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                }
                              }
                            });
                          },
                          child: Container(
                            width: 85,
                            height: 85,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppTheme.primary.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_a_photo_outlined, color: AppTheme.primary, size: 26),
                                const SizedBox(height: 4),
                                Text(
                                  'إضافة فاتورة',
                                  style: GoogleFonts.cairo(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Thumbnails of attached receipts
                        ...currentTx.attachments.map((filePath) {
                          final file = File(filePath);
                          return Container(
                            width: 85,
                            height: 85,
                            margin: const EdgeInsets.only(right: 10),
                            child: Stack(
                              children: [
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ReceiptPreviewDialog(
                                            imagePath: filePath,
                                            title: currentTx.title,
                                            onDelete: () {
                                              final updated = AppState.instance
                                                  .removeAttachmentFromTransaction(currentTx, filePath);
                                              if (updated != null) {
                                                setModalState(() => currentTx = updated);
                                                onUpdated?.call(updated);
                                              }
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: file.existsSync()
                                          ? Image.file(
                                              file,
                                              width: 85,
                                              height: 85,
                                              fit: BoxFit.cover,
                                              errorBuilder: (ctx, _, _) => Container(
                                                color: Colors.grey.withValues(alpha: 0.2),
                                                child: const Icon(Icons.broken_image_outlined),
                                              ),
                                            )
                                          : Container(
                                              color: Colors.grey.withValues(alpha: 0.2),
                                              child: const Icon(Icons.image_not_supported_outlined),
                                            ),
                                    ),
                                  ),
                                ),

                                // Quick Delete Badge on top corner
                                Positioned(
                                  top: 4,
                                  left: 4,
                                  child: GestureDetector(
                                    onTap: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (dCtx) => AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          title: Text(
                                            'حذف الفاتورة',
                                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          content: Text(
                                            'هل تريد حذف صورة هذه الفاتورة؟',
                                            style: GoogleFonts.cairo(fontSize: 13),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(dCtx, false),
                                              child: Text('إلغاء', style: GoogleFonts.cairo()),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppTheme.danger,
                                              ),
                                              onPressed: () => Navigator.pop(dCtx, true),
                                              child: Text(
                                                'حذف',
                                                style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        final updated = AppState.instance
                                            .removeAttachmentFromTransaction(currentTx, filePath);
                                        if (updated != null) {
                                          setModalState(() => currentTx = updated);
                                          onUpdated?.call(updated);
                                        }
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: Colors.black87,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        color: Colors.white,
                                        size: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1),

                  // Change Category ListTile
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.category_outlined, color: AppTheme.primary, size: 20),
                    ),
                    title: Text(
                      'تعديل الفئة (${currentTx.category})',
                      style: GoogleFonts.cairo(fontSize: 13.5, fontWeight: FontWeight.w600, color: textPrimary),
                    ),
                    trailing: const Icon(Icons.chevron_left_rounded),
                    onTap: () {
                      _showChangeCategorySheet(context, currentTx, (newCategory) {
                        AppState.instance.updateTransactionCategory(currentTx, newCategory);
                        final updated = currentTx.copyWith(category: newCategory);
                        setModalState(() => currentTx = updated);
                        onUpdated?.call(updated);
                      });
                    },
                  ),

                  const Divider(height: 1),

                  // Delete Transaction ListTile
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 20),
                    ),
                    title: Text(
                      'حذف هذه المعاملة',
                      style: GoogleFonts.cairo(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppTheme.danger),
                    ),
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dCtx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          title: Row(
                            children: [
                              const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'حذف المعاملة',
                                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                          content: Text(
                            'هل تريد حذف معاملة "${currentTx.title}" بقيمة ${currentTx.amount.toStringAsFixed(3)} د.ل؟',
                            style: GoogleFonts.cairo(fontSize: 13),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dCtx, false),
                              child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey)),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.danger,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => Navigator.pop(dCtx, true),
                              child: Text(
                                'حذف',
                                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true && context.mounted) {
                        Navigator.pop(ctx);
                        AppState.instance.deleteTransaction(currentTx);
                        onDeleted?.call();
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'تم حذف "${currentTx.title}" بنجاح',
                              style: GoogleFonts.cairo(fontSize: 12.5),
                            ),
                            duration: const Duration(seconds: 4),
                            action: SnackBarAction(
                              label: 'تراجع',
                              textColor: AppTheme.accentGold,
                              onPressed: () {
                                AppState.instance.addTransaction(
                                  title: currentTx.title,
                                  amount: currentTx.amount,
                                  category: currentTx.category,
                                  isExpense: currentTx.isExpense,
                                  sourceBadge: currentTx.sourceBadge,
                                  timestamp: currentTx.timestamp,
                                  icon: currentTx.icon,
                                  attachments: currentTx.attachments,
                                );
                              },
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
    },
  );
}

void _showImageSourcePicker(BuildContext context, ValueChanged<bool> onSelectSource) {
  showModalBottomSheet(
    context: context,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 18,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إضافة صورة الفاتورة / الإيصال',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 14),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt_outlined, color: AppTheme.primary, size: 22),
              ),
              title: Text(
                'التقاط صورة بالكاميرا فوراً',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: Text(
                'تصوير الفاتورة الورقية مباشرة من الكاشير',
                style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
              ),
              onTap: () {
                Navigator.pop(ctx);
                onSelectSource(true);
              },
            ),
            const SizedBox(height: 6),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library_outlined, color: AppTheme.accentGold, size: 22),
              ),
              title: Text(
                'اختيار من استوديو الصور',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: Text(
                'تحديد صورة أو لقطة شاشة من المعرض',
                style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
              ),
              onTap: () {
                Navigator.pop(ctx);
                onSelectSource(false);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  },
);
}

void _showChangeCategorySheet(
  BuildContext context,
  TransactionItem tx,
  ValueChanged<String> onCategoryChanged,
) {
  final categories = [
    'تسوق',
    'مطاعم ومقاهي',
    'بقالة ومواد غذائية',
    'مواصلات ووقود',
    'صحة وعلاج',
    'فواتير',
    'تحويلات مالية',
    'عام',
  ];

  showModalBottomSheet(
    context: context,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 18,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'اختر الفئة الجديدة لـ "${tx.title}"',
              style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((cat) {
                final isSelected = tx.category == cat;
                return ChoiceChip(
                  label: Text(cat, style: GoogleFonts.cairo(fontSize: 12)),
                  selected: isSelected,
                  selectedColor: AppTheme.primary,
                  onSelected: (val) {
                    Navigator.pop(ctx);
                    onCategoryChanged(cat);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'تم تعديل فئة "${tx.title}" إلى $cat',
                          style: GoogleFonts.cairo(fontSize: 12),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  },
);
}

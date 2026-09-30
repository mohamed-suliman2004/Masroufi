import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class ReceiptPreviewDialog extends StatelessWidget {
  final String imagePath;
  final String title;
  final VoidCallback onDelete;

  const ReceiptPreviewDialog({
    super.key,
    required this.imagePath,
    required this.title,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final file = File(imagePath);
    final bool exists = file.existsSync();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.black.withValues(alpha: 0.7),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'معاينة الفاتورة / الإيصال',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 24),
                    tooltip: 'حذف الفاتورة',
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          title: Row(
                            children: [
                              const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'حذف الفاتورة',
                                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                          content: Text(
                            'هل أنت متأكد من رغبتك في حذف صورة هذه الفاتورة نهائياً؟',
                            style: GoogleFonts.cairo(fontSize: 13),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey)),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.danger,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(
                                'حذف',
                                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && context.mounted) {
                        onDelete();
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
            ),

            // Image Area with Zoom
            Expanded(
              child: exists
                  ? InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 5.0,
                      panEnabled: true,
                      scaleEnabled: true,
                      child: Center(
                        child: Image.file(
                          file,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 64),
                                const SizedBox(height: 12),
                                Text(
                                  'تعذر تحميل صورة الفاتورة',
                                  style: GoogleFonts.cairo(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.image_not_supported_outlined, color: Colors.white54, size: 64),
                          const SizedBox(height: 12),
                          Text(
                            'ملف الفاتورة غير موجود',
                            style: GoogleFonts.cairo(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
            ),

            // Bottom Hint Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.black.withValues(alpha: 0.7),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.zoom_in_rounded, color: Colors.white60, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'يمكنك التكبير والتصغير بإصبعين لقراءة الأسعار والأصناف بدقة',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'export_helper.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/home/widgets/transaction_tile.dart';

class PdfExportService {
  static Future<void> exportTransactionsPdf({
    required List<TransactionItem> transactions,
    required double totalIncome,
    required double totalExpense,
    String? filterTitle,
  }) async {
    // Load local bundled Arabic font (100% offline & reliable)
    pw.Font fontRegular;
    pw.Font fontBold;
    try {
      final fontData = await rootBundle.load('assets/fonts/Cairo.ttf');
      fontRegular = pw.Font.ttf(fontData);
      fontBold = fontRegular;
    } catch (_) {
      try {
        final amiriData = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
        fontRegular = pw.Font.ttf(amiriData);
        fontBold = fontRegular;
      } catch (_) {
        fontRegular = await PdfGoogleFonts.cairoRegular();
        fontBold = await PdfGoogleFonts.cairoBold();
      }
    }

    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
        ),
        header: (pw.Context context) {
          final now = DateTime.now();
          final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
          return pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'مصروفي - Masroufi',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#D97706'),
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'كشف المعاملات والحركات المالية',
                        style: pw.TextStyle(
                          fontSize: 11,
                          color: PdfColor.fromHex('#475569'),
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (filterTitle != null && filterTitle.isNotEmpty)
                        pw.Text(
                          filterTitle,
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: PdfColor.fromHex('#0284C7'),
                          ),
                        ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F8FAFC'),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                      border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'تاريخ التقرير: $dateStr',
                          style: pw.TextStyle(fontSize: 8.5, color: PdfColor.fromHex('#64748B')),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'إجمالي العمليات: ${transactions.length}',
                          style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1E293B')),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1, color: PdfColor.fromHex('#CBD5E1')),
              pw.SizedBox(height: 8),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 10),
            padding: const pw.EdgeInsets.only(top: 6),
            decoration: pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColor.fromHex('#E2E8F0'), width: 0.8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'تم استخراج التقرير آلياً عبر تطبيق مصروفي لإدارة المصاريف الليبية',
                  style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex('#94A3B8')),
                ),
                pw.Text(
                  'صفحة ${context.pageNumber} من ${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex('#94A3B8')),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          final netBalance = totalIncome - totalExpense;

          return [
            // Summary Cards Box
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 14),
              padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F8FAFC'),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: PdfColor.fromHex('#CBD5E1'), width: 1),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Text(
                        'إجمالي الإيداعات',
                        style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex('#64748B'), fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        '+${totalIncome.toStringAsFixed(2)} د.ل',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#059669'),
                        ),
                      ),
                    ],
                  ),
                  pw.Container(width: 1, height: 26, color: PdfColor.fromHex('#CBD5E1')),
                  pw.Column(
                    children: [
                      pw.Text(
                        'إجمالي المصروفات',
                        style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex('#64748B'), fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        '-${totalExpense.toStringAsFixed(2)} د.ل',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#DC2626'),
                        ),
                      ),
                    ],
                  ),
                  pw.Container(width: 1, height: 26, color: PdfColor.fromHex('#CBD5E1')),
                  pw.Column(
                    children: [
                      pw.Text(
                        'صافي الرصيد',
                        style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex('#64748B'), fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        '${netBalance >= 0 ? '+' : ''}${netBalance.toStringAsFixed(2)} د.ل',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: netBalance >= 0
                              ? PdfColor.fromHex('#059669')
                              : PdfColor.fromHex('#DC2626'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Transactions Table
            pw.TableHelper.fromTextArray(
              headers: ['التاريخ', 'البيان / الجهة', 'المصرف', 'التصنيف', 'النوع', 'المصدر', 'المبلغ (د.ل)'],
              data: transactions.map((tx) {
                final bank = (tx.bankName != null && tx.bankName!.trim().isNotEmpty) ? tx.bankName!.trim() : '-';
                final source = (tx.sourceBadge == 'كاش' || tx.sourceBadge == 'يدوي') ? 'كاش' : 'SMS';
                return [
                  tx.date,
                  tx.title,
                  bank,
                  tx.category,
                  tx.isExpense ? 'خصم' : 'إيداع',
                  source,
                  '${tx.isExpense ? '-' : '+'}${tx.amount.toStringAsFixed(2)}',
                ];
              }).toList(),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.6),
                1: const pw.FlexColumnWidth(2.3),
                2: const pw.FlexColumnWidth(1.8),
                3: const pw.FlexColumnWidth(1.6),
                4: const pw.FlexColumnWidth(1.0),
                5: const pw.FlexColumnWidth(1.1),
                6: const pw.FlexColumnWidth(1.7),
              },
              border: pw.TableBorder.all(color: PdfColor.fromHex('#E2E8F0'), width: 0.7),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
                color: PdfColors.white,
              ),
              headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#1E293B')),
              cellStyle: const pw.TextStyle(fontSize: 8.5, color: PdfColors.black),
              cellAlignment: pw.Alignment.center,
              headerAlignment: pw.Alignment.center,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            ),
          ];
        },
      ),
    );

    final pdfBytes = await doc.save();
    final fileName = 'masroufi_statement_${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}.pdf';
    await saveAndLaunchFile(pdfBytes, fileName);
  }
}
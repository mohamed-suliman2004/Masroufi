import 'package:flutter_test/flutter_test.dart';
import 'package:masroufi_mobile/core/models/bank_sender_model.dart';
import 'package:masroufi_mobile/core/services/libyan_sms_parser.dart';

void main() {
  group('LibyanBankSmsParser Tests', () {
    final banks = const [
      BankSender(name: 'المصرف التجاري الوطني', senderId: 'NCB'),
      BankSender(name: 'مصرف التجارة والتنمية', senderId: '18787'),
      BankSender(name: 'مصرف الجمهورية', senderId: 'Jumhouria'),
      BankSender(name: 'مصرف الوحدة', senderId: 'WahdaBank'),
      BankSender(name: 'سداد Sadad', senderId: '10040'),
      BankSender(name: 'مصرف النوران', senderId: '15050', isCustom: true),
    ];

    group('مصرف التجارة والتنمية (18787) Tests', () {
      test('Parses withdrawal (سحب) with balance', () {
        const body = 'سحب 12818 د.ل\n791006\nرصيدكم: 16198.589 د.ل';
        final parsed = LibyanBankSmsParser.parse(
          sender: '18787',
          body: body,
          registeredBanks: banks,
        );

        expect(parsed, isNotNull);
        expect(parsed!.bankName, 'مصرف التجارة والتنمية');
        expect(parsed.amount, 12818.0);
        expect(parsed.isExpense, true);
        expect(parsed.balanceAfter, 16198.589);
        expect(parsed.title, 'سحب نقدي');
      });

      test('Parses another withdrawal', () {
        const body = 'سحب 8000 د.ل\nGT0000028484103\nرصيدكم: 198.589 د.ل';
        final parsed = LibyanBankSmsParser.parse(
          sender: '18787',
          body: body,
          registeredBanks: banks,
        );

        expect(parsed, isNotNull);
        expect(parsed!.amount, 8000.0);
        expect(parsed.isExpense, true);
        expect(parsed.balanceAfter, 198.589);
      });

      test('Parses deposit (إيداع) with balance', () {
        const body = 'إيداع 240 د.ل\n1768223220664\nرصيدكم 240 د.ل';
        final parsed = LibyanBankSmsParser.parse(
          sender: '18787',
          body: body,
          registeredBanks: banks,
        );

        expect(parsed, isNotNull);
        expect(parsed!.amount, 240.0);
        expect(parsed.isExpense, false);
        expect(parsed.balanceAfter, 240.0);
        expect(parsed.title, 'إيداع نقدي');
      });

      test('Parses deposit without balance', () {
        const body = 'إيداع 5000 د.ل\nc8cfb4fefadea498';
        final parsed = LibyanBankSmsParser.parse(
          sender: '18787',
          body: body,
          registeredBanks: banks,
        );

        expect(parsed, isNotNull);
        expect(parsed!.amount, 5000.0);
        expect(parsed.isExpense, false);
      });

      test('Ignores WABS OTP message from 18787', () {
        const body = 'كلمة المرور المؤقتة لخدمة WABS هي 191134\n@SmartBank #191134 OTP';
        final parsed = LibyanBankSmsParser.parse(
          sender: '18787',
          body: body,
          registeredBanks: banks,
        );

        expect(parsed, isNull);
      });
    });

      test('Ignores BCD Click OTP / authorization message (سلم البائع الرقم ...) to prevent double calculation', () {
        const body = 'شركة كليك\nالقيمة 89.25 د\nسلم البائع الرقم 9874';
        final parsed = LibyanBankSmsParser.parse(
          sender: '18787',
          body: body,
          registeredBanks: banks,
        );

        expect(parsed, isNull, reason: 'BCD OTP containing price must not be counted to prevent double calculation');
      });

      test('Ignores BCD Presto OTP / authorization message (سلم البائع)', () {
        const body = 'بريستو\nالقيمة 167.0 د\nسلم البائع الرقم 4103';
        final parsed = LibyanBankSmsParser.parse(
          sender: '18787',
          body: body,
          registeredBanks: banks,
        );

        expect(parsed, isNull, reason: 'Presto OTP code with amount must be ignored');
      });

      test('Ignores BCD Al-Tahdith OTP / authorization message', () {
        const body = 'التحديث\nالقيمة 50.0 د\nسلم البائع الرقم 2852';
        final parsed = LibyanBankSmsParser.parse(
          sender: '18787',
          body: body,
          registeredBanks: banks,
        );

        expect(parsed, isNull, reason: 'Al-Tahdith OTP code with amount must be ignored');
      });

      test('Parses actual completed BCD transaction debit notification', () {
        const body = 'تم خصم قيمة 89.25 د.ل من حسابكم لصالح شركة كليك\nرصيدكم: 12000.00 د.ل';
        final parsed = LibyanBankSmsParser.parse(
          sender: '18787',
          body: body,
          registeredBanks: banks,
        );

        expect(parsed, isNotNull);
        expect(parsed!.amount, 89.25);
        expect(parsed.isExpense, true);
        expect(parsed.bankName, 'مصرف التجارة والتنمية');
      });

      test('Universal rule: Any message with OTP and amount is completely ignored', () {
        final otpSamples = [
          'القيمة 50 دينار رمز التأكيد: 492040 لا تشارك هذا الرمز',
          'تم طلب شراء بمبلغ 120 د.ل كود التحقق 551928 صالح لمدة 5 دقائق',
          'مبلغ العملية 35 د.ل رمز التفويض الخاص بكم هو 882910',
          'قيمة المعاملة 75 د.ل سلم للتاجر الرمز 4492',
          'مبلغ 200 د.ل OTP: 981240 صالح لمرة واحدة',
        ];

        for (final sample in otpSamples) {
          final p = LibyanBankSmsParser.parse(
            sender: '18787',
            body: sample,
            registeredBanks: banks,
          );
          expect(p, isNull, reason: 'Failed to ignore OTP sample: \$sample');
        }
      });

        group('المصرف التجاري الوطني (NCB) Tests', () {
      test('Parses OnePay incoming transfer (إضافة - Income)', () {
        const body = 'خدمة تحويل ون باي\nإضافة بقيمة 290.000 د.ل\nبتاريخ 2026-09-08';
        final parsed = LibyanBankSmsParser.parse(
          sender: 'NCB',
          body: body,
          registeredBanks: banks,
        );

        expect(parsed, isNotNull);
        expect(parsed!.bankName, 'المصرف التجاري الوطني');
        expect(parsed.amount, 290.0);
        expect(parsed.isExpense, false);
        expect(parsed.title, 'تحويل ون باي');
        expect(parsed.category, 'دخل وراتب');
      });

      test('Parses OnePay outgoing transfer (خصم - Expense)', () {
        const body = 'خدمة تحويل ون باي\nخصم بقيمة 130.000 د.ل\nبتاريخ 2026-09-08';
        final parsed = LibyanBankSmsParser.parse(
          sender: 'NCB',
          body: body,
          registeredBanks: banks,
        );

        expect(parsed, isNotNull);
        expect(parsed!.amount, 130.0);
        expect(parsed.isExpense, true);
        expect(parsed.title, 'تحويل ون باي');
        expect(parsed.category, 'تحويلات ون باي');
      });

      test('Parses POS purchase with merchant extraction (حلواني مذاقي)', () {
        const body = 'تم خصم قيمة 55.5 من حسابكم إلى التاجر: حلواني مذاقي';
        final parsed = LibyanBankSmsParser.parse(
          sender: 'NCB',
          body: body,
          registeredBanks: banks,
        );

        expect(parsed, isNotNull);
        expect(parsed!.amount, 55.5);
        expect(parsed.isExpense, true);
        expect(parsed.merchant, 'حلواني مذاقي');
        expect(parsed.category, 'مطاعم ومقاهي');
      });

      test('Ignores NCB OTP message', () {
        const body = 'رمز التحقق: 447760 يرجى عدم مشاركة الرمز مع أي جهة أخرى <#>hHTI8ARjD/L';
        final parsed = LibyanBankSmsParser.parse(
          sender: 'NCB',
          body: body,
          registeredBanks: banks,
        );

        expect(parsed, isNull);
      });
    });

    group('Other Banks & Custom Bank Transfers', () {
      test('Parses incoming general transfer for other banks (إضافة / وارد)', () {
        const body = 'تم استلام تحويل بمبلغ 450.00 د.ل لحسابكم طرفنا';
        final parsed = LibyanBankSmsParser.parse(
          sender: 'WahdaBank',
          body: body,
          registeredBanks: banks,
        );

        expect(parsed, isNotNull);
        expect(parsed!.amount, 450.0);
        expect(parsed.isExpense, false);
        expect(parsed.title, 'تحويل وارد');
      });

      test('Parses outgoing general transfer for other banks (خصم / صادر)', () {
        const body = 'تم التحويل إلى حساب رقم 01234 بمبلغ 700.00 د.ل من حسابكم';
        final parsed = LibyanBankSmsParser.parse(
          sender: 'Jumhouria',
          body: body,
          registeredBanks: banks,
        );

        expect(parsed, isNotNull);
        expect(parsed!.amount, 700.0);
        expect(parsed.isExpense, true);
        expect(parsed.title, 'حساب');
      });

      test('Parses custom bank transaction (15050)', () {
        const body = 'تم خصم 30.000 د.ل مشتريات نقطة بيع';
        final parsed = LibyanBankSmsParser.parse(
          sender: '15050',
          body: body,
          registeredBanks: banks,
        );

        expect(parsed, isNotNull);
        expect(parsed!.bankName, 'مصرف النوران');
        expect(parsed.amount, 30.0);
        expect(parsed.isExpense, true);
      });
    });
  });
}

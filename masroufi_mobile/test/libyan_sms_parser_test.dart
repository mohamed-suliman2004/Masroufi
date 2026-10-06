import 'package:flutter_test/flutter_test.dart';
import 'package:masroufi_mobile/core/models/bank_sender_model.dart';
import 'package:masroufi_mobile/core/services/libyan_sms_parser.dart';

void main() {
  group('LibyanBankSmsParser Tests', () {
    final banks = <BankSender>[
      const BankSender(name: 'المصرف التجاري الوطني', senderId: 'NCB'),
      const BankSender(name: 'ون باي OnePay', senderId: 'OnePay'),
      const BankSender(name: 'مصرف التجارة والتنمية', senderId: '18787'),
      const BankSender(name: 'مصرف الجمهورية', senderId: 'Jumhouria'),
      const BankSender(name: 'مصرف الوحدة', senderId: 'WahdaBank'),
    ];

    test('Merchant extraction - Center Al Ferjani from supported sender', () {
      final parsed = LibyanBankSmsParser.parse(
        sender: 'NCB',
        body: 'تم خصم قيمة 120 من حسابكم إلى التاجر: سنتر الفرجاني',
        registeredBanks: banks,
      );
      expect(parsed, isNotNull);
      expect(parsed!.title, 'سنتر الفرجاني');
      expect(parsed.amount, 120.0);
      expect(parsed.isExpense, true);
      expect(parsed.category, 'تسوق');
    });

    test('Merchant extraction - Souq Hour Mall from supported sender', () {
      final parsed = LibyanBankSmsParser.parse(
        sender: 'NCB',
        body: 'تم خصم قيمة 22.75 من حسابكم إلى التاجر: سوق حور مول',
        registeredBanks: banks,
      );
      expect(parsed, isNotNull);
      expect(parsed!.title, 'سوق حور مول');
      expect(parsed.amount, 22.75);
      expect(parsed.isExpense, true);
      expect(parsed.category, 'تسوق');
    });

    test('OnePay Debit Transfer from OnePay sender', () {
      final parsed = LibyanBankSmsParser.parse(
        sender: 'OnePay',
        body: 'تحويل ون باي\nتم خصم 160.000 د.ل\nبتاريخ 19-09-2026',
        registeredBanks: banks,
      );
      expect(parsed, isNotNull);
      expect(parsed!.title, 'تحويل ون باي');
      expect(parsed.amount, 160.0);
      expect(parsed.isExpense, true);
    });

    test('CRITICAL: Messages from UNREGISTERED sender must be REJECTED (null)', () {
      // Message containing financial keywords but from an unsupported sender (e.g. telecom, random number, VIP)
      final parsed = LibyanBankSmsParser.parse(
        sender: 'VIP_SERVICES',
        body: 'تم خصم قيمة 50 دينار من حسابكم',
        registeredBanks: banks,
      );
      expect(parsed, isNull, reason: 'SMS from unsupported sender ID must be completely ignored');
    });

    test('CRITICAL: Non-transaction future notifications (سيتم تحصيل) must be REJECTED (null)', () {
      final parsed = LibyanBankSmsParser.parse(
        sender: 'NCB',
        body: 'سيتم تحصيل رسوم اشتراكك في VIP بـ 13.990 د.ل',
        registeredBanks: banks,
      );
      expect(parsed, isNull, reason: 'Upcoming bill / future payment reminders must be ignored');
    });

    test('Custom user-registered service is parsed successfully', () {
      final customBanks = [
        ...banks,
        const BankSender(name: 'محفظتي الخاصة', senderId: 'MyWallet', isCustom: true),
      ];

      final parsed = LibyanBankSmsParser.parse(
        sender: 'MyWallet',
        body: 'تم دفع 85 د.ل لدى متجر: ملابس الأناقة',
        registeredBanks: customBanks,
      );
      expect(parsed, isNotNull);
      expect(parsed!.title, 'ملابس الأناقة');
      expect(parsed.amount, 85.0);
    });

    test('CRITICAL: NCB OTP & Confirmation messages (user reported duplicate) must be ignored', () {
      // 1. Message 1 from user screenshot (Must be ignored!)
      final p1 = LibyanBankSmsParser.parse(
        sender: 'NCB',
        body: 'سيتم خصم القيمة 550.65 من حسابكم، اسم التاجر سوق حور مول يرجى عدم مشاركة رمز التأكيد مع أي جهة لحماية حسابكم، رمز التأكيد: 147373',
        registeredBanks: banks,
      );
      expect(p1, isNull, reason: 'OTP message containing price must be completely skipped');

      // 2. Message 4 from user screenshot (Must be ignored!)
      final p4 = LibyanBankSmsParser.parse(
        sender: 'NCB',
        body: 'سيتم خصم القيمة 236 من حسابكم، اسم التاجر عدم مشاركة رمز التأكيد مع أي جهة لحماية حسابكم، رمز التأكيد: 582194',
        registeredBanks: banks,
      );
      expect(p4, isNull, reason: 'OTP message with code must be skipped');

      // 3. OTP without hamza (رمز التاكيد)
      final pNoHamza = LibyanBankSmsParser.parse(
        sender: 'NCB',
        body: 'سيتم خصم 100 د.ل رمز التاكيد: 998877 يرجى عدم مشاركه الرمز',
        registeredBanks: banks,
      );
      expect(pNoHamza, isNull, reason: 'OTP without hamza must be skipped');

      // 4. Message 2 from user screenshot (Real completed transaction)
      final p2 = LibyanBankSmsParser.parse(
        sender: 'NCB',
        body: 'تم خصم قيمة 550.65 من حسابكم إلى التاجر: سوق حور مول',
        registeredBanks: banks,
      );
      expect(p2, isNotNull);
      expect(p2!.title, 'سوق حور مول');
      expect(p2.amount, 550.65);
      expect(p2.isExpense, true);

      // 5. Message 3 from user screenshot (Yusr settlement message with ISO date YYYY-MM-DD)
      final p3 = LibyanBankSmsParser.parse(
        sender: 'NCB',
        body: 'خدمة يسر\nخصم بقيمة 550.650 د.ل\nبتاريخ 2026-09-22',
        registeredBanks: banks,
      );
      expect(p3, isNotNull);
      expect(p3!.title, 'خدمة يسر');
      expect(p3.amount, 550.65);
      expect(p3.timestamp.year, 2026, reason: 'Year must be 2026, not 2022!');
      expect(p3.timestamp.month, 9);
      expect(p3.timestamp.day, 22);
    });

    test('OTP message ignored', () {
      final parsed = LibyanBankSmsParser.parse(
        sender: 'NCB',
        body: 'رمز التحقق : 493761 يرجى عدم مشاركة هذا الرمز مع أي شخص rHtiBARjDL>#',
        registeredBanks: banks,
      );
      expect(parsed, isNull);
    });
  });
}

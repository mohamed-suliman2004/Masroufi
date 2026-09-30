import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../state/app_state.dart';
import 'libyan_sms_parser.dart';

class SmsService {
  static final SmsService instance = SmsService._internal();
  SmsService._internal();

  static const MethodChannel _methodChannel = MethodChannel('ly.masroufi.sms/channel');
  static const EventChannel _eventChannel = EventChannel('ly.masroufi.sms/stream');

  StreamSubscription? _smsSubscription;
  bool _isListening = false;
  bool get isListening => _isListening;

  /// Callback for notifying UI when an SMS is intercepted and recorded
  Function(ParsedBankSms parsed)? onSmsParsed;

  /// Initialize, start listening, and sync inbox on Android
  Future<void> init() async {
    if (kIsWeb) return;

    try {
      final bool hasPermission = await checkPermission();
      if (hasPermission) {
        startListening();
        await syncSmsInbox();
      }
    } catch (_) {}
  }

  /// Request SMS Permission from Android system
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    try {
      final bool granted = await _methodChannel.invokeMethod('requestSmsPermission');
      if (granted) {
        startListening();
        await syncSmsInbox();
      }
      return granted;
    } catch (_) {
      return false;
    }
  }

  /// Check if SMS permission is already granted
  Future<bool> checkPermission() async {
    if (kIsWeb) return false;
    try {
      final bool granted = await _methodChannel.invokeMethod('checkSmsPermission');
      return granted;
    } catch (_) {
      return false;
    }
  }

  /// Open App Settings page directly on Android
  Future<void> openAppSettings() async {
    if (kIsWeb) return;
    try {
      await _methodChannel.invokeMethod('openAppSettings');
    } catch (_) {}
  }

  /// Start listening to live incoming SMS messages
  void startListening() {
    if (kIsWeb || _isListening) return;

    try {
      _smsSubscription = _eventChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          if (event is Map) {
            _processRawSms(event);
          }
        },
        onError: (err) {
          debugPrint('SMS stream error: $err');
        },
      );
      _isListening = true;
    } catch (_) {}
  }

  /// Sync device SMS inbox and native pending queue strictly for the CURRENT MONTH
  Future<int> syncSmsInbox({bool currentMonthOnly = true}) async {
    if (kIsWeb) return 0;

    int importedCount = 0;
    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) return 0;

      // Ensure listener is running
      startListening();

      // Filter: from the 1st of the current month 00:00:00
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final minTimestamp = currentMonthOnly ? startOfMonth.millisecondsSinceEpoch : 0;

      // 1. Process pending messages saved by native BroadcastReceiver while app was closed
      try {
        final dynamic pending = await _methodChannel.invokeMethod('getPendingSms');
        if (pending is List) {
          for (final item in pending) {
            if (item is Map) {
              final rawTs = item['timestamp'];
              if (currentMonthOnly && rawTs is int && rawTs > 0) {
                if (DateTime.fromMillisecondsSinceEpoch(rawTs).isBefore(startOfMonth)) {
                  continue; // Skip messages before current month
                }
              }
              if (_processRawSms(item, minTimestamp: currentMonthOnly ? startOfMonth : null)) {
                importedCount++;
              }
            }
          }
        }
      } catch (_) {}

      // 2. Read recent inbox messages directly from Android SMS provider (only current month!)
      try {
        final dynamic inbox = await _methodChannel.invokeMethod(
          'readSmsInbox',
          {'minTimestamp': minTimestamp},
        );
        if (inbox is List) {
          for (final item in inbox) {
            if (item is Map && _processRawSms(item, minTimestamp: currentMonthOnly ? startOfMonth : null)) {
              importedCount++;
            }
          }
        }
      } catch (_) {}
    } catch (e) {
      debugPrint('syncSmsInbox error: $e');
    }
    return importedCount;
  }

  bool _processRawSms(Map item, {DateTime? minTimestamp}) {
    final sender = item['sender'] as String? ?? '';
    final body = item['body'] as String? ?? '';
    final rawTs = item['timestamp'];
    DateTime? ts;
    if (rawTs is int && rawTs > 0) {
      ts = DateTime.fromMillisecondsSinceEpoch(rawTs);
    }
    if (minTimestamp != null && ts != null && ts.isBefore(minTimestamp)) {
      return false; // Skip messages from past months
    }
    return _handleIncomingSms(sender, body, timestamp: ts, minTimestamp: minTimestamp);
  }

  bool _handleIncomingSms(String sender, String body, {DateTime? timestamp, DateTime? minTimestamp}) {
    if (sender.isEmpty || body.isEmpty) return false;

    // Parse with Libyan Bank Parser
    final parsed = LibyanBankSmsParser.parse(
      sender: sender,
      body: body,
      registeredBanks: AppState.instance.allBankSenders,
      timestamp: timestamp,
    );

    if (parsed != null) {
      // Strict current month filter: if transaction date is before start of current month, skip it!
      if (minTimestamp != null && parsed.timestamp.isBefore(minTimestamp)) {
        return false;
      }

      // Record into AppState without duplicating
      final added = AppState.instance.addTransactionIfNotExists(
        title: parsed.title,
        amount: parsed.amount,
        category: parsed.category,
        isExpense: parsed.isExpense,
        sourceBadge: 'SMS',
        bankName: parsed.bankName,
        timestamp: parsed.timestamp,
      );

      if (added) {
        onSmsParsed?.call(parsed);
        return true;
      }
    }
    return false;
  }

  void dispose() {
    _smsSubscription?.cancel();
    _isListening = false;
  }
}

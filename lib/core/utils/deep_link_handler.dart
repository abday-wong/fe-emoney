import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

class PendingTrx {
  final double amount;
  final String recipient;
  final String trxId;
  final String callback;

  PendingTrx({
    required this.amount,
    required this.recipient,
    required this.trxId,
    required this.callback,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'recipient': recipient,
      'trx_id': trxId,
      'callback': callback,
    };
  }
}

class DeepLinkHandler {
  static PendingTrx? pendingTrx;
  static final _appLinks = AppLinks();
  static StreamSubscription? _subscription;

  static void init({required Function(PendingTrx) onPaymentLinkReceived}) {
    // Listen to incoming deep links (scheme: emoney://)
    _subscription = _appLinks.uriLinkStream.listen((uri) {
      _handleIncomingUri(uri, onPaymentLinkReceived);
    }, onError: (err) {
      debugPrint('Deep Link Error: $err');
    });

    // Check initial link on cold start
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _handleIncomingUri(uri, onPaymentLinkReceived);
      }
    });
  }

  static void _handleIncomingUri(Uri uri, Function(PendingTrx) callback) {
    debugPrint('Received Deep Link Uri: $uri');
    bool isPaymentLink = (uri.scheme == 'emoney' && uri.host == 'pay');
    if (kIsWeb && uri.queryParameters.containsKey('amount') && uri.queryParameters.containsKey('recipient')) {
      isPaymentLink = true;
    }

    if (isPaymentLink) {
      final amountStr = uri.queryParameters['amount'];
      final recipient = uri.queryParameters['recipient'];
      final trxId = uri.queryParameters['trx_id'];
      final callbackUrl = uri.queryParameters['callback'];

      if (amountStr != null && recipient != null && trxId != null && callbackUrl != null) {
        final amount = double.tryParse(amountStr) ?? 0.0;
        final trx = PendingTrx(
          amount: amount,
          recipient: recipient,
          trxId: trxId,
          callback: callbackUrl,
        );
        pendingTrx = trx;
        callback(trx);
      }
    }
  }

  static void dispose() {
    _subscription?.cancel();
  }
}

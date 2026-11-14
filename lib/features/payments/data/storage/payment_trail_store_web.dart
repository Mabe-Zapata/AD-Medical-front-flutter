import 'dart:convert';

import 'package:medicalbooking_portal/features/payments/data/storage/payment_trail_store.dart';
import 'package:web/web.dart' as web;

const _key = 'medilo.payment.trails';

/// Keeps the trails in `sessionStorage`: they survive a reload but not closing the tab. Storage can be
/// unavailable (private mode), so every access is guarded and the portal then works in memory.
class WebPaymentTrailStore implements PaymentTrailStore {
  @override
  Map<String, PaymentTrail> load() {
    try {
      final raw = web.window.sessionStorage.getItem(_key);
      final data = raw == null ? null : jsonDecode(raw);
      if (data is! Map) return {};
      return {
        for (final entry in data.entries)
          if (entry.value case {'invoice': final String invoice, 'key': final String key})
            entry.key as String: (invoiceId: invoice, key: key, paymentId: (entry.value as Map)['payment'] as String?),
      };
    } catch (_) {
      return {};
    }
  }

  @override
  void save(Map<String, PaymentTrail> trails) {
    try {
      web.window.sessionStorage.setItem(
        _key,
        jsonEncode({
          for (final entry in trails.entries)
            entry.key: {'invoice': entry.value.invoiceId, 'key': entry.value.key, 'payment': entry.value.paymentId},
        }),
      );
    } catch (_) {
      // Still remembered in memory for this page load.
    }
  }
}

PaymentTrailStore createPaymentTrailStore() => WebPaymentTrailStore();

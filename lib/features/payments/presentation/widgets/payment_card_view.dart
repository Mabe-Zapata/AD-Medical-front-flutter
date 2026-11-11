import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/saved_card.dart';

/// Presentational: the saved card drawn in the brand colors. The number is masked; only the last four
/// digits are known.
class PaymentCardView extends StatelessWidget {
  const PaymentCardView({super.key, required this.card, required this.holderName});

  final SavedCard card;
  final String holderName;

  @override
  Widget build(BuildContext context) {
    final expiry = '${card.expMonth.toString().padLeft(2, '0')}/${(card.expYear % 100).toString().padLeft(2, '0')}';
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: AspectRatio(
        aspectRatio: 1.586,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Tokens.orangeDeep, Tokens.gradientStart, Tokens.gradientEnd],
            ),
            borderRadius: BorderRadius.circular(Tokens.radiusMd + 4),
            boxShadow: [
              BoxShadow(color: Tokens.orange.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 12)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'MEDILO',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'PACIENTE',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 9, letterSpacing: 1),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.contactless_outlined, color: Colors.white),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: 44,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Tokens.orangeSoft, Color(0xFFFDBA74)]),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const Spacer(),
              Text(
                '••••  ••••  ••••  ${card.last4}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: _Field('TITULAR', holderName.toUpperCase())),
                  _Field('VENCE', expiry),
                  const SizedBox(width: 16),
                  Text(
                    card.brand.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 9, letterSpacing: 1)),
      const SizedBox(height: 2),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
      ),
    ],
  );
}

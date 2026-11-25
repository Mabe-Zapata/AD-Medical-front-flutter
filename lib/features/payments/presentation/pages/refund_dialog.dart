import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/gradient_button.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/refund.dart';

/// What the patient chose in [RefundDialog].
typedef RefundRequest = ({RefundReason reason, String? text});

const refundReasonLabels = <RefundReason, String>{
  RefundReason.patientCancellation: 'Cancelé mi cita',
  RefundReason.doctorCancellation: 'La canceló el laboratorio o el médico',
  RefundReason.chargeError: 'Me cobraron por error',
};

/// Presentational: asks why the patient wants the payment back. The amount is not asked: the server decides it.
class RefundDialog extends StatefulWidget {
  const RefundDialog({super.key});

  @override
  State<RefundDialog> createState() => _RefundDialogState();
}

class _RefundDialogState extends State<RefundDialog> {
  RefundReason _reason = RefundReason.patientCancellation;
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: Tokens.orange.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.currency_exchange_outlined, color: Tokens.orange, size: 28),
              ),
              const SizedBox(height: 18),
              const Text(
                'Pedir reembolso',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Tokens.slate900),
              ),
              const SizedBox(height: 10),
              const Text(
                'Se devuelve el pago completo de esta cita. El banco puede tardar en acreditarlo.',
                style: TextStyle(fontSize: 15, height: 1.5, color: Tokens.muted),
              ),
              const SizedBox(height: 16),
              RadioGroup<RefundReason>(
                groupValue: _reason,
                onChanged: (value) => setState(() => _reason = value ?? _reason),
                child: Column(
                  children: [
                    for (final entry in refundReasonLabels.entries)
                      RadioListTile<RefundReason>(
                        value: entry.key,
                        title: Text(entry.value),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        activeColor: Tokens.orange,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _text,
                maxLength: 500,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Cuéntanos más (opcional)'),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Volver'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GradientButton(
                      label: 'Pedir reembolso',
                      onPressed: () => Navigator.of(context).pop((reason: _reason, text: _text.text.trim().isEmpty ? null : _text.text.trim())),
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

import 'package:flutter/material.dart';
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
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Pedir reembolso'),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Se devuelve el pago completo de esta cita. El banco puede tardar en acreditarlo.'),
            const SizedBox(height: 12),
            RadioGroup<RefundReason>(
              groupValue: _reason,
              onChanged: (value) => setState(() => _reason = value ?? _reason),
              child: Column(
                children: [
                  for (final entry in refundReasonLabels.entries)
                    RadioListTile<RefundReason>(value: entry.key, title: Text(entry.value), dense: true, contentPadding: EdgeInsets.zero),
                ],
              ),
            ),
            TextField(
              controller: _text,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Cuéntanos más (opcional)'),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Volver')),
      FilledButton(
        onPressed: () => Navigator.of(context).pop((reason: _reason, text: _text.text.trim().isEmpty ? null : _text.text.trim())),
        child: const Text('Pedir reembolso'),
      ),
    ],
  );
}

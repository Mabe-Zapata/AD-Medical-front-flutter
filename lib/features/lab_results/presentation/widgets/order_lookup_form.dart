import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/shared/presentation/molecules/panel.dart';

/// Presentational: asks for the code the laboratory gave the patient and reports it.
class OrderLookupForm extends StatefulWidget {
  const OrderLookupForm({super.key, required this.busy, required this.onSubmit});

  final bool busy;
  final ValueChanged<String> onSubmit;

  @override
  State<OrderLookupForm> createState() => _OrderLookupFormState();
}

class _OrderLookupFormState extends State<OrderLookupForm> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _submit() {
    if (_code.text.trim().isEmpty || widget.busy) return;
    widget.onSubmit(_code.text);
  }

  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Consultar una orden',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Tokens.slate900),
        ),
        const SizedBox(height: 4),
        const Text(
          'Escribe el código de orden que te entregó el laboratorio.',
          style: TextStyle(color: Tokens.muted, fontSize: 13),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _code,
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(labelText: 'Código de orden'),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: widget.busy ? null : _submit,
              child: widget.busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Consultar'),
            ),
          ],
        ),
      ],
    ),
  );
}

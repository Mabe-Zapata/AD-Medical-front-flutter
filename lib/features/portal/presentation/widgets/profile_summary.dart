import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/features/auth/domain/entities/patient.dart';

const _documentLabels = {'CEDULA': 'Cédula', 'PASAPORTE': 'Pasaporte'};

/// Presentational: the patient's personal data as a card, one labeled field per datum, so nothing floats loose
/// under the greeting. Fields the account does not have are left out.
class ProfileSummary extends StatelessWidget {
  const ProfileSummary(this.patient, {super.key, this.vertical = false});

  final Patient patient;

  /// Stack the fields under the name (the side column) instead of laying them out in a row.
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final number = patient.documentNumber;
    final type = patient.documentType;
    final name = patient.fullName;
    final fields = <(IconData, String, String)>[
      (Icons.mail_outline, 'Correo', patient.email),
      if (patient.phone != null) (Icons.phone_outlined, 'Teléfono', patient.phone!),
      if (number != null) (Icons.badge_outlined, _documentLabels[type] ?? type ?? 'Documento', number),
    ];
    final identity = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: Tokens.blueSoft,
          child: Text(
            _initial(name ?? patient.email),
            style: const TextStyle(fontWeight: FontWeight.w800, color: Tokens.blueDeep, fontSize: 18),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name ?? 'Mi cuenta', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Tokens.slate900)),
            const Text('Datos de tu cuenta', style: TextStyle(color: Tokens.muted, fontSize: 12)),
          ],
        ),
      ],
    );
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(vertical ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Tokens.radiusMd),
        border: Border.all(color: Tokens.slate200),
        boxShadow: [BoxShadow(color: Tokens.blueDeep.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: vertical
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                identity,
                const SizedBox(height: 16),
                for (final (icon, label, value) in fields) ...[
                  _Field(icon: icon, label: label, value: value),
                  const SizedBox(height: 12),
                ],
              ],
            )
          : Wrap(
              spacing: 32,
              runSpacing: 14,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [identity, for (final (icon, label, value) in fields) _Field(icon: icon, label: label, value: value)],
            ),
    );
  }

  static String _initial(String text) => text.isEmpty ? '?' : text.characters.first.toUpperCase();
}

class _Field extends StatelessWidget {
  const _Field({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 18, color: Tokens.blue),
      const SizedBox(width: 8),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Tokens.blueText, letterSpacing: 0.6)),
          Text(value, style: const TextStyle(fontSize: 14, color: Tokens.slate900)),
        ],
      ),
    ],
  );
}

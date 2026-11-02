import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/features/auth/domain/entities/patient.dart';

const _documentLabels = {'CEDULA': 'Cédula', 'PASAPORTE': 'Pasaporte'};

class ProfileSummary extends StatelessWidget {
  const ProfileSummary(this.patient, {super.key});

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    final number = patient.documentNumber;
    final type = patient.documentType;
    final document = number == null ? null : '${_documentLabels[type] ?? type ?? 'Documento'} $number';
    return Wrap(
      spacing: 20,
      runSpacing: 6,
      children: [
        for (final item in [patient.fullName, patient.email, ?patient.phone, ?document])
          Text(item, style: const TextStyle(color: Tokens.muted, fontSize: 13)),
      ],
    );
  }
}

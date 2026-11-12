import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/features/profile/domain/entities/clinical_profile.dart';

/// Presentational: invites the patient to declare their clinical profile, or summarizes what they declared.
class ProfilePrompt extends StatelessWidget {
  const ProfilePrompt({super.key, required this.profile, required this.onOpen});

  final ClinicalProfile? profile;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final declared = profile;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: declared == null ? Tokens.orangeTint : Tokens.blueTint,
        borderRadius: BorderRadius.circular(Tokens.radiusMd),
        border: Border.all(
          color: declared == null ? Tokens.orangeSoft : Tokens.blueSoft,
        ),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  declared == null
                      ? Icons.assignment_outlined
                      : Icons.verified_user_outlined,
                  color: declared == null ? Tokens.orange : Tokens.blue,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: declared == null
                      ? const _Message(
                          title: 'Completa tu perfil clínico',
                          text: 'Indica tu altitud de residencia y si fumas: se usan para interpretar tu hemoglobina.',
                        )
                      : _Message(
                          title: 'Perfil clínico completo',
                          text:
                              '${declared.altitudeM} m de altitud · ${declared.smoker ? 'fumas ${declared.cigarettesPerDay ?? 0} al día' : 'no fumas'}',
                        ),
                ),
              ],
            ),
          ),
          declared == null
              ? FilledButton(onPressed: onOpen, child: const Text('Completar'))
              : TextButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Editar'),
                ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: Tokens.slate900,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        text,
        style: const TextStyle(fontSize: 13, color: Tokens.muted, height: 1.4),
      ),
    ],
  );
}

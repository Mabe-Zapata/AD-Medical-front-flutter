import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medicalbooking_portal/app/app_scope.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/features/profile/domain/entities/clinical_profile.dart';
import 'package:medicalbooking_portal/features/profile/domain/policies/clinical_profile_policy.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/gradient_button.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/section_label.dart';
import 'package:medicalbooking_portal/shared/presentation/error_message.dart';
import 'package:medicalbooking_portal/shared/presentation/molecules/error_banner.dart';
import 'package:medicalbooking_portal/shared/presentation/organisms/two_panel_modal.dart';

/// Container: the patient's clinical profile (altitude of residence and smoking). It is used to adjust
/// how the hemoglobin is interpreted, and only the patient can write it.
class ProfileDialog extends StatefulWidget {
  const ProfileDialog({super.key});

  @override
  State<ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<ProfileDialog> {
  final _altitude = TextEditingController();
  final _cigarettes = TextEditingController();
  bool? _smoker;
  bool _prefilled = false;
  bool _submitted = false;
  bool _busy = false;
  bool _saved = false;
  ErrorView? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reopening shows what was declared in this session; the API cannot give it back after a reload.
    if (_prefilled) return;
    _prefilled = true;
    final deps = AppScope.of(context);
    final patient = deps.session.patient;
    final current = patient == null ? null : deps.clinicalProfiles.of(patient.id);
    if (current == null) return;
    _altitude.text = '${current.altitudeM}';
    _smoker = current.smoker;
    _cigarettes.text = current.cigarettesPerDay == null ? '' : '${current.cigarettesPerDay}';
  }

  @override
  void dispose() {
    _altitude.dispose();
    _cigarettes.dispose();
    super.dispose();
  }

  int? get _altitudeValue => int.tryParse(_altitude.text.trim());
  int? get _cigarettesValue => int.tryParse(_cigarettes.text.trim());

  Set<ProfileProblem> get _problems =>
      profileProblems(altitudeM: _altitudeValue, smoker: _smoker, cigarettes: _cigarettesValue).toSet();

  String? _fieldError(ProfileProblem problem, String message) =>
      _submitted && _problems.contains(problem) ? message : null;

  Future<void> _save() async {
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (_problems.isNotEmpty) return;
    final deps = AppScope.of(context);
    final patient = deps.session.patient;
    if (patient == null) return;
    setState(() => _busy = true);
    try {
      await deps.clinicalProfiles.save(
        patient.id,
        ClinicalProfile(
          altitudeM: _altitudeValue!,
          smoker: _smoker!,
          cigarettesPerDay: _smoker! ? _cigarettesValue : null,
        ),
      );
      if (mounted) setState(() => _saved = true);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = describeError(
            error,
            overrides: const {
              ErrorKind.validation: 'Revisa la altitud (0 a 8848 m) y los cigarrillos por día.',
              ErrorKind.forbidden: 'Solo una cuenta de paciente puede guardar su perfil clínico.',
            },
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => TwoPanelModal(
    tag: 'Perfil clínico',
    headline: 'Para interpretar tus resultados con tus datos.',
    bullets: const [
      'Tu altitud de residencia y si fumas ajustan cómo se interpreta tu hemoglobina (OMS 2024).',
      'Solo tú puedes escribir estos datos.',
      'Puedes actualizarlos cuando cambien.',
    ],
    footerLabel: 'Datos de salud',
    footerNote: 'Privados',
    child: _saved ? _Saved(onClose: () => Navigator.of(context).maybePop()) : _form(),
  );

  Widget _form() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SectionLabel('Mi perfil'),
      const SizedBox(height: 8),
      const Text(
        'Perfil clínico',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Tokens.slate900),
      ),
      const SizedBox(height: 20),
      TextField(
        controller: _altitude,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: 'Altitud de residencia (metros)',
          prefixIcon: const Icon(Icons.terrain_outlined, size: 20),
          helperText: 'Metros sobre el nivel del mar donde vives. Quito está a unos 2850 m.',
          helperMaxLines: 2,
          errorText: _fieldError(ProfileProblem.altitude, 'Escribe un número entre 0 y $maxAltitudeM.'),
        ),
      ),
      const SizedBox(height: 20),
      const Text('¿Fumas?', style: TextStyle(fontWeight: FontWeight.w700, color: Tokens.slate900)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 10,
        children: [
          ChoiceChip(
            label: const Text('No fumo'),
            selected: _smoker == false,
            showCheckmark: false,
            selectedColor: Tokens.orangeSoft,
            onSelected: (_) => setState(() => _smoker = false),
          ),
          ChoiceChip(
            label: const Text('Fumo'),
            selected: _smoker == true,
            showCheckmark: false,
            selectedColor: Tokens.orangeSoft,
            onSelected: (_) => setState(() => _smoker = true),
          ),
        ],
      ),
      if (_fieldError(ProfileProblem.smoking, 'Elige una opción.') case final message?)
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 4),
          child: Text(message, style: const TextStyle(color: Tokens.danger, fontSize: 12)),
        ),
      if (_smoker == true) ...[
        const SizedBox(height: 16),
        TextField(
          controller: _cigarettes,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Cigarrillos por día',
            errorText: _fieldError(ProfileProblem.cigarettes, 'Escribe un número entre 0 y $maxCigarettesPerDay.'),
          ),
        ),
      ],
      if (_error != null) ...[const SizedBox(height: 16), ErrorBanner(error: _error!)],
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: GradientButton(label: _busy ? 'Guardando…' : 'Guardar perfil', onPressed: _busy ? null : _save),
      ),
    ],
  );
}

class _Saved extends StatelessWidget {
  const _Saved({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(color: Tokens.success.withValues(alpha: 0.12), shape: BoxShape.circle),
        child: const Icon(Icons.check_circle_outline, color: Tokens.success, size: 30),
      ),
      const SizedBox(height: 18),
      const Text(
        'Perfil guardado',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Tokens.slate900),
      ),
      const SizedBox(height: 12),
      const Text(
        'Tus resultados se interpretarán con estos datos. Puedes cambiarlos cuando quieras desde tu portal.',
        style: TextStyle(fontSize: 15, height: 1.5),
      ),
      const SizedBox(height: 28),
      SizedBox(
        width: double.infinity,
        child: GradientButton(label: 'Volver a mi portal', trailing: Icons.arrow_forward, onPressed: onClose),
      ),
    ],
  );
}

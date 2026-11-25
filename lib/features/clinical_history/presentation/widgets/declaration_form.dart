import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/features/clinical_history/domain/entities/patient_history.dart';
import 'package:medicalbooking_portal/features/clinical_history/domain/policies/history_policy.dart';
import 'package:medicalbooking_portal/features/clinical_history/presentation/labels.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/gradient_button.dart';
import 'package:medicalbooking_portal/shared/presentation/error_message.dart';
import 'package:medicalbooking_portal/shared/presentation/molecules/error_banner.dart';

/// Form to declare one entry of a kind the patient may declare. Fields go one under another so the
/// modal uses its height. Problems are shown under the field once the patient tries to send.
/// Presentational: the page gives the catalog loader and what to do with the declaration.
class DeclarationForm extends StatefulWidget {
  const DeclarationForm({
    super.key,
    required this.kind,
    required this.catalog,
    required this.onSubmit,
    required this.today,
  });

  final HistoryKind kind;
  final Future<List<CatalogOption>> Function(String catalog, {String? query}) catalog;
  final Future<void> Function(Declaration declaration) onSubmit;
  final DateTime today;

  @override
  State<DeclarationForm> createState() => _DeclarationFormState();
}

const _catalogOf = {
  HistoryKind.allergy: 'sustancias-alergia',
  HistoryKind.vaccine: 'vacunas',
};

class _DeclarationFormState extends State<DeclarationForm> {
  final _reaction = TextEditingController();
  final _description = TextEditingController();
  final _relative = TextEditingController();
  final _cie11 = TextEditingController();
  final _name = TextEditingController();
  final _dose = TextEditingController();
  final _frequency = TextEditingController();
  final _startDate = TextEditingController();
  final _doseNumber = TextEditingController();
  final _date = TextEditingController();
  final _lot = TextEditingController();

  CatalogOption? _substance;
  CatalogOption? _vaccine;
  String? _severity;
  String _type = 'PERSONAL';
  late final Future<List<CatalogOption>>? _options = _catalogOf[widget.kind] == null
      ? null
      : widget.catalog(_catalogOf[widget.kind]!);
  bool _submitted = false;
  bool _busy = false;
  String? _notice;
  ErrorView? _error;
  // Bumped after a successful send so the dropdowns, which only read their initial value, start empty again.
  int _generation = 0;

  @override
  void dispose() {
    for (final c in [
      _reaction,
      _description,
      _relative,
      _cie11,
      _name,
      _dose,
      _frequency,
      _startDate,
      _doseNumber,
      _date,
      _lot,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// The declaration as the form reads it now, and the problems the backend rules would report for it.
  ({Declaration declaration, Set<String> problems}) _draft() {
    final today = widget.today;
    switch (widget.kind) {
      case HistoryKind.allergy:
        final declaration = AllergyDeclaration(
          substanceCode: _substance?.code ?? '',
          severity: _severity ?? '',
          reaction: _blankToNull(_reaction.text),
        );
        return (declaration: declaration, problems: validateDeclaration(declaration, today).toSet());
      case HistoryKind.antecedent:
        final declaration = AntecedentDeclaration(
          type: _type,
          description: _description.text.trim(),
          relative: _blankToNull(_relative.text),
          cie11: _blankToNull(_cie11.text),
        );
        return (declaration: declaration, problems: validateDeclaration(declaration, today).toSet());
      case HistoryKind.medication:
        final start = _day(_startDate.text);
        final declaration = MedicationDeclaration(
          name: _name.text.trim(),
          dose: _blankToNull(_dose.text),
          frequency: _blankToNull(_frequency.text),
          startDate: start,
        );
        final dateBroken = _startDate.text.trim().isNotEmpty && start == null;
        return (
          declaration: declaration,
          problems: {...validateDeclaration(declaration, today), if (dateBroken) 'date'},
        );
      case HistoryKind.vaccine:
        final date = _day(_date.text);
        final declaration = VaccineDeclaration(
          vaccineCode: _vaccine?.code ?? '',
          doseNumber: int.tryParse(_doseNumber.text.trim()) ?? 0,
          date: date ?? today,
          lot: _blankToNull(_lot.text),
        );
        return (
          declaration: declaration,
          problems: {...validateDeclaration(declaration, today), if (date == null) 'date'},
        );
      case HistoryKind.problem:
        throw ArgumentError.value(widget.kind, 'kind', 'Patients do not declare diagnoses');
    }
  }

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _error = null;
      _notice = null;
    });
    final draft = _draft();
    if (draft.problems.isNotEmpty) return;
    setState(() => _busy = true);
    try {
      await widget.onSubmit(draft.declaration);
      if (!mounted) return;
      _clear();
      setState(() => _notice = 'Listo. Tu médico la revisará antes de darla por confirmada.');
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = describeError(
            error,
            overrides: const {ErrorKind.validation: 'Revisa los datos marcados.'},
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _clear() {
    for (final c in [
      _reaction,
      _description,
      _relative,
      _cie11,
      _name,
      _dose,
      _frequency,
      _startDate,
      _doseNumber,
      _date,
      _lot,
    ]) {
      c.clear();
    }
    _substance = null;
    _vaccine = null;
    _severity = null;
    _type = 'PERSONAL';
    _submitted = false;
    _generation++;
  }

  /// The first message among the keys that has a problem, shown only after the patient tried to send.
  String? _errorFor(Set<String> problems, List<String> keys) {
    if (!_submitted) return null;
    for (final key in keys) {
      if (problems.contains(key)) return problemText(key);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final problems = _draft().problems;
    final fields = switch (widget.kind) {
      HistoryKind.allergy => _allergyFields(problems),
      HistoryKind.antecedent => _antecedentFields(problems),
      HistoryKind.medication => _medicationFields(problems),
      HistoryKind.vaccine => _vaccineFields(problems),
      HistoryKind.problem => const <Widget>[],
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...fields,
        if (_error != null) ...[
          const SizedBox(height: 14),
          ErrorBanner(error: _error!),
        ],
        if (_notice != null) ...[
          const SizedBox(height: 14),
          Text(_notice!, style: const TextStyle(color: Tokens.success, fontWeight: FontWeight.w600)),
        ],
        const SizedBox(height: 20),
        GradientButton(
          label: 'Declarar',
          onPressed: _busy ? null : _submit,
        ),
      ],
    );
  }

  List<Widget> _allergyFields(Set<String> problems) => [
    _catalogDropdown(
      label: 'Sustancia',
      value: _substance,
      onChanged: (v) => setState(() => _substance = v),
      error: _errorFor(problems, const ['substanceCode']),
    ),
    _gap,
    _dropdown<String>(
      label: 'Gravedad',
      value: _severity,
      items: severityOptions,
      onChanged: (v) => setState(() => _severity = v),
      error: _errorFor(problems, const ['severity']),
    ),
    _gap,
    _text(_reaction, 'Reacción (opcional)', error: _errorFor(problems, const ['reaction'])),
  ];

  List<Widget> _antecedentFields(Set<String> problems) => [
    _dropdown<String>(
      label: 'Tipo',
      value: _type,
      items: antecedentTypeOptions,
      onChanged: (v) => setState(() => _type = v ?? 'PERSONAL'),
      error: _errorFor(problems, const ['type']),
    ),
    _gap,
    _text(
      _description,
      'Descripción',
      error: _errorFor(problems, const ['description']),
      maxLines: 3,
    ),
    _gap,
    _text(_relative, 'Familiar (solo si es familiar)', error: _errorFor(problems, const ['relative'])),
    _gap,
    _text(
      _cie11,
      'Código CIE-11 (opcional, por ejemplo BA00)',
      error: _errorFor(problems, const ['cie11']),
    ),
  ];

  List<Widget> _medicationFields(Set<String> problems) => [
    _text(_name, 'Medicamento', error: _errorFor(problems, const ['name'])),
    _gap,
    _text(_dose, 'Dosis (opcional)', error: _errorFor(problems, const ['dose'])),
    _gap,
    _text(_frequency, 'Frecuencia (opcional)', error: _errorFor(problems, const ['frequency'])),
    _gap,
    _text(
      _startDate,
      'Desde cuándo (opcional, año-mes-día)',
      error: _errorFor(problems, const ['date', 'future']),
      keyboardType: TextInputType.datetime,
    ),
  ];

  List<Widget> _vaccineFields(Set<String> problems) => [
    _catalogDropdown(
      label: 'Vacuna',
      value: _vaccine,
      onChanged: (v) => setState(() => _vaccine = v),
      error: _errorFor(problems, const ['vaccineCode']),
    ),
    _gap,
    _text(
      _doseNumber,
      'Número de dosis (1 a 10)',
      error: _errorFor(problems, const ['doseNumber']),
      keyboardType: TextInputType.number,
    ),
    _gap,
    _text(
      _date,
      'Fecha de la dosis (año-mes-día)',
      error: _errorFor(problems, const ['date', 'future']),
      keyboardType: TextInputType.datetime,
    ),
    _gap,
    _text(_lot, 'Lote (opcional)', error: _errorFor(problems, const ['lot'])),
  ];

  static const _gap = SizedBox(height: 14);

  Widget _text(
    TextEditingController controller,
    String label, {
    String? error,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) => TextField(
    controller: controller,
    maxLines: maxLines,
    keyboardType: keyboardType,
    onChanged: (_) => setState(() {}),
    decoration: InputDecoration(labelText: label, errorText: error),
  );

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<(T, String)> items,
    required ValueChanged<T?> onChanged,
    String? error,
  }) => DropdownButtonFormField<T>(
    key: ValueKey('$label-$_generation'),
    initialValue: value,
    decoration: InputDecoration(labelText: label, errorText: error),
    items: [for (final (code, text) in items) DropdownMenuItem<T>(value: code, child: Text(text))],
    onChanged: onChanged,
  );

  Widget _catalogDropdown({
    required String label,
    required CatalogOption? value,
    required ValueChanged<CatalogOption?> onChanged,
    String? error,
  }) {
    final options = _options;
    if (options == null) return const SizedBox.shrink();
    return FutureBuilder<List<CatalogOption>>(
      future: options,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(
            'No pudimos cargar la lista. Cierra y vuelve a abrir esta ventana.',
            style: const TextStyle(color: Tokens.danger),
          );
        }
        if (!snapshot.hasData) return const LinearProgressIndicator();
        return DropdownButtonFormField<CatalogOption>(
          key: ValueKey('$label-$_generation'),
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(labelText: label, errorText: error),
          items: [
            for (final option in snapshot.data!)
              DropdownMenuItem<CatalogOption>(value: option, child: Text(option.name)),
          ],
          onChanged: onChanged,
        );
      },
    );
  }

  static String? _blankToNull(String text) {
    final trimmed = text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static DateTime? _day(String text) => parseDay(text);
}

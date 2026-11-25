import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:medicalbooking_portal/app/app_scope.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/features/clinical_history/domain/entities/patient_history.dart';
import 'package:medicalbooking_portal/features/clinical_history/domain/policies/history_policy.dart';
import 'package:medicalbooking_portal/features/clinical_history/presentation/controllers/clinical_history_controller.dart';
import 'package:medicalbooking_portal/features/clinical_history/presentation/labels.dart';
import 'package:medicalbooking_portal/features/clinical_history/presentation/widgets/declaration_form.dart';
import 'package:medicalbooking_portal/features/clinical_history/presentation/widgets/history_entries.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/section_label.dart';
import 'package:medicalbooking_portal/shared/presentation/error_message.dart';
import 'package:medicalbooking_portal/shared/presentation/molecules/error_banner.dart';
import 'package:medicalbooking_portal/shared/presentation/molecules/pagination_bar.dart';
import 'package:medicalbooking_portal/shared/presentation/molecules/pill_tabs.dart';
import 'package:medicalbooking_portal/shared/presentation/organisms/two_panel_modal.dart';

/// Container: the patient's clinical history, read by date range, with the log of changes. The patient
/// declares allergies, antecedents, medication and vaccines; diagnoses and vital signs are read only.
class ClinicalHistoryDialog extends StatefulWidget {
  const ClinicalHistoryDialog({super.key});

  @override
  State<ClinicalHistoryDialog> createState() => _ClinicalHistoryDialogState();
}

class _ClinicalHistoryDialogState extends State<ClinicalHistoryDialog> {
  final _from = TextEditingController();
  final _to = TextEditingController();
  RangePreset? _preset = RangePreset.all;
  String? _rangeFormatError;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    // The first read waits for the frame: it notifies listeners, which may not happen while building.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refresh();
    });
  }

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  ClinicalHistoryController get _controller => AppScope.of(context).clinicalHistory;

  Future<void> _refresh() async {
    final controller = _controller;
    await controller.load();
    await controller.loadEvents(offset: 0);
  }

  void _applyPreset(RangePreset preset) {
    _from.clear();
    _to.clear();
    setState(() {
      _preset = preset;
      _rangeFormatError = null;
    });
    _controller.setRange(_presetSpan(preset, DateTime.now()));
    _refresh();
  }

  void _applyDates() {
    final fromText = _from.text.trim();
    final toText = _to.text.trim();
    final from = fromText.isEmpty ? null : parseDay(fromText);
    final to = toText.isEmpty ? null : parseDay(toText);
    if ((fromText.isNotEmpty && from == null) || (toText.isNotEmpty && to == null)) {
      setState(() => _rangeFormatError = problemText('date'));
      return;
    }
    setState(() {
      _preset = null;
      _rangeFormatError = null;
    });
    _controller.setRange(DateSpan(from: from, to: to));
    _refresh();
  }

  static DateSpan _presetSpan(RangePreset preset, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return switch (preset) {
      RangePreset.lastMonth => DateSpan(from: DateTime(today.year, today.month - 1, today.day), to: today),
      RangePreset.lastSixMonths => DateSpan(from: DateTime(today.year, today.month - 6, today.day), to: today),
      RangePreset.lastYear => DateSpan(from: DateTime(today.year - 1, today.month, today.day), to: today),
      RangePreset.all => DateSpan.all,
    };
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return TwoPanelModal(
      tag: 'Historia clínica',
      headline: 'Tu historia clínica, en un solo lugar.',
      bullets: const [
        'Lo que declaras y lo que confirma tu médico, por fecha.',
        'Cada cambio queda en la bitácora, con su fecha.',
        'Solo tú puedes declarar tus datos.',
      ],
      bulletIcons: const [Icons.fact_check_outlined, Icons.history, Icons.verified_user_outlined],
      footerLabel: 'Datos de salud',
      footerNote: 'Privados',
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => _body(controller),
      ),
    );
  }

  Widget _body(ClinicalHistoryController controller) {
    final history = controller.history;
    final events = controller.events;
    final rangeProblems = controller.rangeProblems;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Mi historia'),
        const SizedBox(height: 8),
        const Text(
          'Historia clínica',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Tokens.slate900),
        ),
        const SizedBox(height: 16),
        _rangePicker(rangeProblems),
        if (controller.loading) const Padding(
          padding: EdgeInsets.only(top: 12),
          child: LinearProgressIndicator(),
        ),
        if (controller.error != null) ...[
          const SizedBox(height: 12),
          ErrorBanner(
            error: describeError(controller.error!),
            onRetry: _refresh,
          ),
        ],
        const SizedBox(height: 16),
        PillTabs(
          selected: _tab,
          onSelected: (value) => setState(() => _tab = value),
          tabs: const [
            PillTab('Alergias', icon: Icons.warning_amber_outlined),
            PillTab('Antecedentes', icon: Icons.person_outline),
            PillTab('Medicación', icon: Icons.medication_outlined),
            PillTab('Vacunas', icon: Icons.vaccines_outlined),
            PillTab('Consultas', icon: Icons.monitor_heart_outlined),
            PillTab('Bitácora', icon: Icons.history),
          ],
        ),
        const SizedBox(height: 16),
        _section(history, events, controller),
      ],
    );
  }

  Widget _rangePicker(List<String> rangeProblems) {
    final problems = [
      ...rangeProblems.map(problemText),
      ?_rangeFormatError,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in RangePreset.values)
              ChoiceChip(
                label: Text(preset.label),
                selected: _preset == preset,
                onSelected: (_) => _applyPreset(preset),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 170,
              child: TextField(
                controller: _from,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(labelText: 'Desde (año-mes-día)', isDense: true),
              ),
            ),
            SizedBox(
              width: 170,
              child: TextField(
                controller: _to,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(labelText: 'Hasta (año-mes-día)', isDense: true),
              ),
            ),
            OutlinedButton(onPressed: _applyDates, child: const Text('Aplicar fechas')),
          ],
        ),
        for (final problem in problems)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(problem, style: const TextStyle(color: Tokens.danger, fontSize: 13)),
          ),
      ],
    );
  }

  Widget _section(PatientHistory? history, HistoryEventPage? events, ClinicalHistoryController controller) =>
      switch (_tab) {
        0 => _kindSection(HistoryKind.allergy, history, 'No tienes alergias registradas en este rango.'),
        1 => _kindSection(HistoryKind.antecedent, history, 'No hay antecedentes en este rango.'),
        2 => _kindSection(HistoryKind.medication, history, 'No hay medicación registrada en este rango.'),
        3 => _kindSection(HistoryKind.vaccine, history, 'No hay vacunas registradas en este rango.'),
        4 => _consultSection(history),
        _ => _logSection(events, controller),
      };

  /// The entries of one kind, then the form to declare another one of that kind.
  Widget _kindSection(HistoryKind kind, PatientHistory? history, String emptyText) {
    final declarable = _declarationForm(kind);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HistoryEntryList(entries: history?.of(kind) ?? const [], emptyText: emptyText),
        const SizedBox(height: 20),
        SectionLabel('Declarar ${kindTitle(kind).toLowerCase()}'),
        const SizedBox(height: 4),
        const Text(
          'Tu médico lo revisará antes de darlo por confirmado.',
          style: TextStyle(color: Tokens.muted, fontSize: 13),
        ),
        const SizedBox(height: 12),
        declarable,
      ],
    );
  }

  Widget _declarationForm(HistoryKind kind) => DeclarationForm(
    key: ValueKey(kind),
    kind: kind,
    today: DateTime.now(),
    catalog: (name, {query}) => _controller.catalog(name, query: query),
    onSubmit: (declaration) => _controller.declare(declaration),
  );

  Widget _consultSection(PatientHistory? history) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SectionLabel('Diagnósticos'),
      const SizedBox(height: 8),
      HistoryEntryList(
        entries: history?.of(HistoryKind.problem) ?? const [],
        emptyText: 'Tu médico aún no registra diagnósticos en este rango.',
      ),
      const SizedBox(height: 20),
      const SectionLabel('Signos vitales'),
      const SizedBox(height: 4),
      const Text(
        'Los toma tu médico durante la consulta. Solo lectura.',
        style: TextStyle(color: Tokens.muted, fontSize: 13),
      ),
      const SizedBox(height: 12),
      VitalsList(records: history?.vitals ?? const []),
    ],
  );

  Widget _logSection(HistoryEventPage? events, ClinicalHistoryController controller) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Cada alta, confirmación, cambio o corrección de tu historia.',
        style: TextStyle(color: Tokens.muted, fontSize: 13),
      ),
      const SizedBox(height: 12),
      if (controller.eventsError != null) ...[
        ErrorBanner(error: describeError(controller.eventsError!), onRetry: () => controller.loadEvents()),
        const SizedBox(height: 12),
      ],
      EventList(events: events?.items ?? const []),
      if (events != null)
        PaginationBar(
          total: events.total,
          page: controller.eventOffset ~/ controller.eventLimit,
          pageSize: controller.eventLimit,
          onPage: (page) => controller.loadEvents(offset: page * controller.eventLimit),
          onPageSize: controller.setEventPageSize,
        ),
    ],
  );
}

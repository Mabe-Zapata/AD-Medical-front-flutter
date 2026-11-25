import 'package:flutter_test/flutter_test.dart';
import 'package:medicalbooking_portal/features/clinical_history/data/repositories/demo_patient_history_repository.dart';
import 'package:medicalbooking_portal/features/clinical_history/domain/entities/patient_history.dart';
import 'package:medicalbooking_portal/features/clinical_history/domain/repositories/patient_history_repository.dart';
import 'package:medicalbooking_portal/features/clinical_history/domain/usecases/declare_history_entry.dart';
import 'package:medicalbooking_portal/features/clinical_history/domain/usecases/read_history_events.dart';
import 'package:medicalbooking_portal/features/clinical_history/domain/usecases/read_patient_history.dart';
import 'package:medicalbooking_portal/features/clinical_history/domain/usecases/search_history_catalog.dart';
import 'package:medicalbooking_portal/features/clinical_history/presentation/controllers/clinical_history_controller.dart';

/// Counts the reads, so a test can see that an invalid range never reaches the repository.
class _CountingRepository implements PatientHistoryRepository {
  _CountingRepository(this._inner);

  final PatientHistoryRepository _inner;
  int reads = 0;

  @override
  Future<PatientHistory> read(DateSpan span) {
    reads++;
    return _inner.read(span);
  }

  @override
  Future<HistoryEventPage> events({required DateSpan span, required int limit, required int offset}) =>
      _inner.events(span: span, limit: limit, offset: offset);

  @override
  Future<void> declare(String patientId, Declaration declaration) => _inner.declare(patientId, declaration);

  @override
  Future<List<CatalogOption>> catalog(String catalog, {String? query}) => _inner.catalog(catalog, query: query);
}

/// Refuses every declaration, as the backend does when it rejects one.
class _RefusingRepository extends _CountingRepository {
  _RefusingRepository(super.inner);

  @override
  Future<void> declare(String patientId, Declaration declaration) => Future.error(StateError('refused'));
}

ClinicalHistoryController _controllerOver(PatientHistoryRepository repository) => ClinicalHistoryController(
  read: ReadPatientHistory(repository),
  readEvents: ReadHistoryEvents(repository),
  declare: DeclareHistoryEntry(repository),
  searchCatalog: SearchHistoryCatalog(repository),
  now: () => DateTime(2026, 11, 24),
);

void main() {
  final today = DateTime(2026, 11, 24);

  test('loads the demo history and the first page of its log', () async {
    final controller = _controllerOver(DemoPatientHistoryRepository(now: () => today));

    await controller.load();
    await controller.loadEvents(offset: 0);

    expect(controller.history!.of(HistoryKind.allergy).single.title, 'Penicilina');
    expect(controller.events!.total, 0, reason: 'the demo log starts empty, like a new patient');
  });

  test('an invalid range is explained and never read', () async {
    final repository = _CountingRepository(DemoPatientHistoryRepository(now: () => today));
    final controller = _controllerOver(repository);

    controller.setRange(DateSpan(from: DateTime(2026, 3, 1), to: DateTime(2026, 2, 1)));
    await controller.load();
    await controller.loadEvents(offset: 0);

    expect(controller.rangeProblems, ['order']);
    expect(repository.reads, 0);
    expect(controller.history, isNull);
  });

  test('a declaration waits unconfirmed, and the log records it as created', () async {
    final controller = _controllerOver(DemoPatientHistoryRepository(now: () => today));
    await controller.load();
    await controller.loadEvents(offset: 0);

    await controller.declare(
      const AntecedentDeclaration(type: 'PERSONAL', description: 'Migraña'),
    );

    final declared = controller.history!.of(HistoryKind.antecedent).firstWhere((e) => e.title == 'Migraña');
    expect(declared.declared, isTrue);
    expect(declared.verified, isFalse);
    expect(controller.events!.items.single.entity, 'antecedente');
    expect(controller.events!.items.single.action, 'CREAR');
  });

  test('a refused declaration is rethrown and leaves the history as it was', () async {
    final controller = _controllerOver(_RefusingRepository(DemoPatientHistoryRepository(now: () => today)));
    await controller.load();
    final before = controller.history!.entries.length;

    await expectLater(
      controller.declare(const MedicationDeclaration(name: 'Losartán')),
      throwsA(isA<StateError>()),
    );

    expect(controller.history!.entries.length, before);
  });

  test('changing the page size goes back to the first page', () async {
    final controller = _controllerOver(DemoPatientHistoryRepository(now: () => today));
    await controller.load();
    await controller.loadEvents(offset: 5);

    await controller.setEventPageSize(10);

    expect(controller.eventLimit, 10);
    expect(controller.eventOffset, 0);
  });
}

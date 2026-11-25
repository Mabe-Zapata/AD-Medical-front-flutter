import 'package:flutter/foundation.dart';
import 'package:medicalbooking_portal/features/clinical_history/domain/entities/patient_history.dart';
import 'package:medicalbooking_portal/features/clinical_history/domain/policies/history_policy.dart';
import 'package:medicalbooking_portal/features/clinical_history/domain/usecases/declare_history_entry.dart';
import 'package:medicalbooking_portal/features/clinical_history/domain/usecases/read_history_events.dart';
import 'package:medicalbooking_portal/features/clinical_history/domain/usecases/read_patient_history.dart';
import 'package:medicalbooking_portal/features/clinical_history/domain/usecases/search_history_catalog.dart';

/// Rows per page of the event log.
const eventPageSize = 5;

/// Holds the patient's history for the dialog: the date range, the entries and the event log page.
/// Read failures are kept as errors for the screen to explain; a failed declaration is rethrown so
/// the form stays filled and can be retried.
class ClinicalHistoryController extends ChangeNotifier {
  ClinicalHistoryController({
    required this._read,
    required this._readEvents,
    required this._declare,
    required this._searchCatalog,
    required this._now,
  });

  final ReadPatientHistory _read;
  final ReadHistoryEvents _readEvents;
  final DeclareHistoryEntry _declare;
  final SearchHistoryCatalog _searchCatalog;
  final DateTime Function() _now;

  DateSpan _span = DateSpan.all;
  PatientHistory? _history;
  HistoryEventPage? _events;
  int _eventLimit = eventPageSize;
  int _eventOffset = 0;
  bool _loading = false;
  bool _loadingEvents = false;
  Object? _error;
  Object? _eventsError;

  DateSpan get span => _span;
  PatientHistory? get history => _history;
  HistoryEventPage? get events => _events;
  int get eventOffset => _eventOffset;
  int get eventLimit => _eventLimit;
  bool get loading => _loading;
  bool get loadingEvents => _loadingEvents;
  Object? get error => _error;
  Object? get eventsError => _eventsError;

  /// Problems of the range the patient picked, as keys the screen translates. Empty when it can be read.
  List<String> get rangeProblems => validateRange(_span, _now());

  /// Picks a new range. Call [load] and [loadEvents] afterwards to read it.
  void setRange(DateSpan span) {
    _span = span;
    notifyListeners();
  }

  Future<void> load() async {
    if (rangeProblems.isNotEmpty) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _history = await _read(_span);
    } catch (error) {
      _error = error;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Reads one page of the log. Without [offset] it keeps the page the patient is on.
  Future<void> loadEvents({int? offset}) async {
    if (rangeProblems.isNotEmpty) return;
    _eventOffset = offset ?? _eventOffset;
    _loadingEvents = true;
    _eventsError = null;
    notifyListeners();
    try {
      _events = await _readEvents(span: _span, limit: _eventLimit, offset: _eventOffset);
    } catch (error) {
      _eventsError = error;
    } finally {
      _loadingEvents = false;
      notifyListeners();
    }
  }

  /// Changes how many rows a page of the log shows, and goes back to the first page.
  Future<void> setEventPageSize(int size) async {
    _eventLimit = size;
    await loadEvents(offset: 0);
  }

  /// Declares an entry about the patient, then reads the history and the first page of the log again.
  /// A failure is rethrown without touching what is on screen.
  Future<void> declare(Declaration declaration) async {
    final patientId = _history?.patientId;
    if (patientId == null) return;
    await _declare(patientId, declaration);
    await load();
    await loadEvents(offset: 0);
  }

  Future<List<CatalogOption>> catalog(String name, {String? query}) => _searchCatalog(name, query: query);
}

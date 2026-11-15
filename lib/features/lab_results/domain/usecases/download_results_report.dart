import 'package:medicalbooking_portal/features/lab_results/domain/repositories/lab_results_repository.dart';

/// The PDF of an order's results. The API decides who may read it; the portal only asks.
class DownloadResultsReport {
  const DownloadResultsReport(this._repository);

  final LabResultsRepository _repository;

  Future<List<int>> call(String orderId) => _repository.resultsReport(orderId);
}

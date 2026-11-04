/// Values chosen when the app is built, through `--dart-define`.
///
/// * `API_BASE_URL`: base path of the REST API (for example `/api/v1` behind the same Nginx).
///   When it is empty the app runs on the in-memory demo.
/// * `SERVICES_JSON`: bookable services of the target environment, because the backend has no
///   catalog endpoint yet. A JSON array of `{id, name, durationMin, basePrice}`.
abstract final class BuildSettings {
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const servicesJson = String.fromEnvironment('SERVICES_JSON');
}

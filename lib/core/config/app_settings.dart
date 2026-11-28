/// Values chosen when the app is built, through `--dart-define`.
///
/// * `API_BASE_URL`: base path of the REST API (for example `/api/v1` behind the same Nginx).
///   When it is empty the app runs on the in-memory demo. The bookable services are read from
///   `GET /services` of that API.
abstract final class BuildSettings {
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
}

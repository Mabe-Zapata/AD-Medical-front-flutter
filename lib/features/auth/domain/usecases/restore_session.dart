import 'package:medicalbooking_portal/features/auth/domain/entities/session.dart';
import 'package:medicalbooking_portal/features/auth/domain/repositories/auth_repository.dart';

/// Reads the stored session after a reload and drops it if it already expired.
class RestoreSession {
  const RestoreSession(this._store, {this._now = DateTime.now});

  final SessionStore _store;
  final DateTime Function() _now;

  Session? call() {
    final session = _store.load();
    if (session == null) return null;
    if (session.isExpired(_now())) {
      _store.clear();
      return null;
    }
    return session;
  }
}

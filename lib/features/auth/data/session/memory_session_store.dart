import 'package:medicalbooking_portal/features/auth/domain/entities/session.dart';
import 'package:medicalbooking_portal/features/auth/domain/repositories/auth_repository.dart';

/// Keeps the session only while the app is running. Used by tests and non-web targets.
class MemorySessionStore implements SessionStore {
  Session? _session;

  @override
  Session? load() => _session;

  @override
  void save(Session session) => _session = session;

  @override
  void clear() => _session = null;
}

SessionStore createSessionStore() => MemorySessionStore();

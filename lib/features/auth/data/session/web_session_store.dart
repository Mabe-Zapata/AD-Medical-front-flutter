import 'dart:convert';

import 'package:medicalbooking_portal/features/auth/domain/entities/patient.dart';
import 'package:medicalbooking_portal/features/auth/domain/entities/session.dart';
import 'package:medicalbooking_portal/features/auth/domain/repositories/auth_repository.dart';
import 'package:web/web.dart' as web;

const _key = 'medilo.patient.session';

/// Keeps the session in `sessionStorage`: it survives a reload but not closing the tab, and it is
/// never shared with other tabs. Storage can be unavailable (private mode), so every access is guarded.
class WebSessionStore implements SessionStore {
  @override
  Session? load() {
    try {
      final raw = web.window.sessionStorage.getItem(_key);
      if (raw == null) return null;
      final data = jsonDecode(raw);
      final user = data is Map ? data['user'] : null;
      if (data is! Map ||
          data['token'] is! String ||
          data['expiresAt'] is! int ||
          user is! Map ||
          user['id'] is! String ||
          user['email'] is! String) {
        clear();
        return null;
      }
      return Session(
        token: data['token'] as String,
        expiresAt: DateTime.fromMillisecondsSinceEpoch(data['expiresAt'] as int),
        patient: Patient(
          id: user['id'] as String,
          email: user['email'] as String,
          roles: List<String>.from(user['roles'] as List? ?? const []),
          permissions: List<String>.from(user['permissions'] as List? ?? const []),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void save(Session session) {
    try {
      web.window.sessionStorage.setItem(
        _key,
        jsonEncode({
          'token': session.token,
          'expiresAt': session.expiresAt.millisecondsSinceEpoch,
          'user': {
            'id': session.patient.id,
            'email': session.patient.email,
            'roles': session.patient.roles,
            'permissions': session.patient.permissions,
          },
        }),
      );
    } catch (_) {
      // The session still works in memory for this page load.
    }
  }

  @override
  void clear() {
    try {
      web.window.sessionStorage.removeItem(_key);
    } catch (_) {
      // Nothing to clear.
    }
  }
}

SessionStore createSessionStore() => WebSessionStore();

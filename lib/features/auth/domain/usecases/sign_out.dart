import 'package:medicalbooking_portal/features/auth/domain/repositories/auth_repository.dart';

class SignOut {
  const SignOut(this._store);

  final SessionStore _store;

  void call() => _store.clear();
}

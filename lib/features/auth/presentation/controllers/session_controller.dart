import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:medicalbooking_portal/features/auth/domain/entities/new_patient_account.dart';
import 'package:medicalbooking_portal/features/auth/domain/entities/patient.dart';
import 'package:medicalbooking_portal/features/auth/domain/entities/session.dart';
import 'package:medicalbooking_portal/features/auth/domain/usecases/register_patient.dart';
import 'package:medicalbooking_portal/features/auth/domain/usecases/restore_session.dart';
import 'package:medicalbooking_portal/features/auth/domain/usecases/sign_in.dart';
import 'package:medicalbooking_portal/features/auth/domain/usecases/sign_out.dart';

/// Why the last session ended, so the login page can explain it.
enum EndReason { expired, closed }

/// Holds the signed-in patient for the whole app. Pages read it; only this class changes it.
class SessionController extends ChangeNotifier {
  SessionController({
    required this._signIn,
    required this._signOut,
    required this._register,
    required RestoreSession restore,
    this._now = DateTime.now,
  }) {
    _session = restore();
    _armExpiry();
  }

  final SignIn _signIn;
  final SignOut _signOut;
  final RegisterPatient _register;
  final DateTime Function() _now;

  Session? _session;
  EndReason? _endReason;
  Timer? _timer;

  Patient? get patient => _session?.patient;
  String? get token => _session?.token;
  EndReason? get endReason => _endReason;

  /// True while the session exists and has not expired; ends it otherwise.
  bool get isSignedIn {
    final session = _session;
    if (session == null) return false;
    if (session.isExpired(_now())) {
      signOut(EndReason.expired);
      return false;
    }
    return true;
  }

  /// Throws `AppError` when the credentials are wrong or the account is not a patient's.
  Future<void> signIn(String email, String password) async {
    _session = await _signIn(email: email, password: password);
    _endReason = null;
    _armExpiry();
    notifyListeners();
  }

  /// Creates the patient account. It stays inactive until the person opens the link sent by email, so this
  /// does not sign in. The role is always patient: this app is the patients' portal. Returns the normalized
  /// account that was sent. Throws `AppError` (validation, network...).
  Future<NewPatientAccount> register(NewPatientAccount account) => _register(account);

  void signOut([EndReason reason = EndReason.closed]) {
    _timer?.cancel();
    _signOut();
    _session = null;
    _endReason = reason;
    notifyListeners();
  }

  /// The API rejected our token: the session is no longer valid.
  void expire() {
    if (_session != null) signOut(EndReason.expired);
  }

  void _armExpiry() {
    _timer?.cancel();
    final session = _session;
    if (session == null) return;
    final delay = session.expiresAt.difference(_now());
    _timer = Timer(delay.isNegative ? Duration.zero : delay, expire);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

import 'package:flutter/foundation.dart';
import 'package:medicalbooking_portal/features/auth/domain/entities/patient.dart';
import 'package:medicalbooking_portal/features/auth/domain/usecases/sign_in.dart';
import 'package:medicalbooking_portal/features/auth/domain/usecases/sign_out.dart';

/// Holds the signed-in patient for the whole app.
class SessionController extends ChangeNotifier {
  SessionController({required this._signIn, required this._signOut});

  final SignIn _signIn;
  final SignOut _signOut;

  Patient? _patient;

  Patient? get patient => _patient;
  bool get isSignedIn => _patient != null;

  Future<bool> signIn(String email, String password) async {
    final patient = await _signIn(email: email, password: password);
    if (patient == null) return false;
    _patient = patient;
    notifyListeners();
    return true;
  }

  Future<void> signOut() async {
    await _signOut();
    _patient = null;
    notifyListeners();
  }
}

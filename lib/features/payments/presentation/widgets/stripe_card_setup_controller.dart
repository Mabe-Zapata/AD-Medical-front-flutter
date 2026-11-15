import 'package:flutter/foundation.dart';

/// Connects the Stripe card form (inside the scrollable body) with the save button (in the dialog footer), so the
/// button stays visible without scrolling the form. The form reports its state and attaches its save action.
class StripeCardSetupController extends ChangeNotifier {
  bool _ready = false;
  bool _busy = false;
  String? _error;
  Future<void> Function()? _save;

  /// True when Stripe's form is mounted and not busy: the save button may be pressed.
  bool get canSave => _ready && !_busy && _save != null;
  bool get busy => _busy;
  String? get error => _error;

  Future<void> save() async {
    if (canSave) await _save!();
  }

  /// Called by the form when it mounts (or fails), and while it saves.
  void update({required bool ready, required bool busy, String? error}) {
    _ready = ready;
    _busy = busy;
    _error = error;
    notifyListeners();
  }

  /// Called by the form to say what pressing save does.
  void attach(Future<void> Function() save) => _save = save;
}

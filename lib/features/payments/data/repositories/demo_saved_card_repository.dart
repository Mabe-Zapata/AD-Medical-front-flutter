import 'package:medicalbooking_portal/features/payments/domain/entities/card_setup.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/saved_card.dart';
import 'package:medicalbooking_portal/features/payments/domain/repositories/saved_card_repository.dart';
import 'package:medicalbooking_portal/infrastructure/demo/demo_database.dart';

/// Demo: a made-up card on file, so the screen can be reviewed without a payment provider.
class DemoSavedCardRepository implements SavedCardRepository {
  const DemoSavedCardRepository(this._db);

  final DemoDatabase _db;

  @override
  Future<SavedCard?> defaultCard(String patientId) async {
    await _db.simulateLatency();
    return _db.savedCardOf(patientId);
  }

  /// The demo does not take card details: the portal hides the button in demo mode.
  @override
  Future<CardSetup> startSetup(String patientId) async {
    await _db.simulateLatency();
    return const CardSetup(clientSecret: 'seti_demo_secret', publishableKey: 'pk_test_demo');
  }

  @override
  Future<void> remove(String patientId) async {
    await _db.simulateLatency();
    _db.setSavedCard(patientId, null);
  }
}

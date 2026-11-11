import 'package:medicalbooking_portal/features/payments/domain/entities/saved_card.dart';
import 'package:medicalbooking_portal/features/payments/domain/repositories/saved_card_repository.dart';
import 'package:medicalbooking_portal/infrastructure/demo/demo_database.dart';

/// Demo: a made-up card, so the screen can be reviewed without a payment provider.
class DemoSavedCardRepository implements SavedCardRepository {
  const DemoSavedCardRepository(this._db);

  final DemoDatabase _db;

  @override
  Future<SavedCard?> defaultCard(String patientId) async {
    await _db.simulateLatency();
    return const SavedCard(brand: 'VISA', last4: '4242', expMonth: 9, expYear: 2028);
  }
}

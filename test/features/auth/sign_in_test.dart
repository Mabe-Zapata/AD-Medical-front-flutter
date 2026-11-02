import 'package:flutter_test/flutter_test.dart';
import 'package:medicalbooking_portal/features/auth/data/repositories/demo_auth_repository.dart';
import 'package:medicalbooking_portal/features/auth/domain/usecases/sign_in.dart';
import 'package:medicalbooking_portal/infrastructure/demo/demo_database.dart';

void main() {
  late SignIn signIn;

  setUp(() => signIn = SignIn(DemoAuthRepository(DemoDatabase(latency: Duration.zero))));

  test('accepts the demo account, ignoring case and spaces in the email', () async {
    final patient = await signIn(email: '  ${DemoDatabase.demoEmail.toUpperCase()} ', password: DemoDatabase.demoPassword);
    expect(patient, isNotNull);
  });

  test('rejects wrong or empty credentials', () async {
    expect(await signIn(email: DemoDatabase.demoEmail, password: 'wrong'), isNull);
    expect(await signIn(email: '', password: 'x'), isNull);
    expect(await signIn(email: DemoDatabase.demoEmail, password: ''), isNull);
  });
}

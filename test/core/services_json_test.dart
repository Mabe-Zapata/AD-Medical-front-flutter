import 'package:flutter_test/flutter_test.dart';
import 'package:medicalbooking_portal/features/catalog/data/services_json.dart';

void main() {
  test('an empty setting means "use the default"', () {
    expect(parseServices(''), isNull);
    expect(parseServices('  '), isNull);
  });

  test('parses the bookable services of an environment', () {
    final services = parseServices(
      '[{"id":"11111111-2222-4333-8444-555555555555","name":"Toma de sangre","durationMin":20,"basePrice":8}]',
    )!;

    expect(services.single.name, 'Toma de sangre');
    expect(services.single.durationMin, 20);
    expect(services.single.basePrice, 8.0);
    expect(services.single.currency, 'USD');
  });

  test('a malformed setting fails loudly instead of booking against the wrong service', () {
    expect(() => parseServices('{}'), throwsFormatException);
    expect(() => parseServices('[{"id":"x"}]'), throwsFormatException);
    expect(() => parseServices('not json'), throwsFormatException);
  });
}

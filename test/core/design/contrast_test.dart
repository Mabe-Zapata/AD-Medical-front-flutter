import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';

double _ratio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (hi, lo) = la >= lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  const white = Color(0xFFFFFFFF);

  // WCAG AA for normal text is 4.5:1.
  test('text colors meet AA on white and on the orange tint', () {
    for (final color in [Tokens.orange, Tokens.orangeDeep, Tokens.muted, Tokens.slate500, Tokens.success, Tokens.danger, Tokens.warning]) {
      expect(_ratio(color, white), greaterThanOrEqualTo(4.5), reason: '$color on white');
    }
    for (final color in [Tokens.orange, Tokens.orangeDeep, Tokens.muted]) {
      expect(_ratio(color, Tokens.orangeTint), greaterThanOrEqualTo(4.5), reason: '$color on tint');
    }
  });

  test('the blue family keeps AA: text on white and on its own tint, white text on the navy', () {
    for (final color in [Tokens.blue, Tokens.blueDeep, Tokens.blueText]) {
      expect(
        _ratio(color, white),
        greaterThanOrEqualTo(4.5),
        reason: '$color on white',
      );
      expect(
        _ratio(color, Tokens.blueTint),
        greaterThanOrEqualTo(4.5),
        reason: '$color on the blue tint',
      );
    }
    expect(_ratio(white, Tokens.blue), greaterThanOrEqualTo(4.5));
    expect(_ratio(white, Tokens.blueDeep), greaterThanOrEqualTo(4.5));
    // The orange used on the tinted tabs and panels.
    expect(_ratio(Tokens.orange, Tokens.blueTint), greaterThanOrEqualTo(4.5));
  });

  test('white text on the brand button and gradient meets AA', () {
    for (final color in [Tokens.orange, Tokens.gradientStart, Tokens.gradientEnd]) {
      expect(_ratio(white, color), greaterThanOrEqualTo(4.5), reason: 'white on $color');
    }
  });
}

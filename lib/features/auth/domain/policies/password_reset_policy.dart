import 'package:medicalbooking_portal/features/auth/domain/policies/registration_policy.dart';

/// The rules a new password must meet. They are the ones the identity API enforces when a link is used.
enum PasswordRule { length, upper, lower, digit, symbol }

final passwordRuleLabels = {
  PasswordRule.length: 'al menos $minPasswordLength caracteres',
  PasswordRule.upper: 'una mayúscula',
  PasswordRule.lower: 'una minúscula',
  PasswordRule.digit: 'un número',
  PasswordRule.symbol: 'un símbolo',
};

bool _meets(PasswordRule rule, String password) => switch (rule) {
  PasswordRule.length => password.length >= minPasswordLength,
  PasswordRule.upper => RegExp('[A-Z]').hasMatch(password),
  PasswordRule.lower => RegExp('[a-z]').hasMatch(password),
  PasswordRule.digit => RegExp('[0-9]').hasMatch(password),
  PasswordRule.symbol => RegExp(r'[!-/:-@\[-`{-~]').hasMatch(password),
};

/// The rules [password] does not meet yet. Empty means it is valid.
List<PasswordRule> missingPasswordRules(String password) => [
  for (final rule in PasswordRule.values)
    if (!_meets(rule, password)) rule,
];

/// Text listing only what is missing, for example "una mayúscula, un símbolo".
String missingPasswordText(List<PasswordRule> missing) => missing.map((rule) => passwordRuleLabels[rule]!).join(', ');

/// 0 (empty) to 4 for the strength bar: the share of the rules met.
int resetStrengthLevel(String password) {
  if (password.isEmpty) return 0;
  final met = PasswordRule.values.length - missingPasswordRules(password).length;
  return (met * 4 / PasswordRule.values.length).round().clamp(0, 4);
}

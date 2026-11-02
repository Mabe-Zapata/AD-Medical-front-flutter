import 'package:flutter_test/flutter_test.dart';
import 'package:medicalbooking_portal/core/format/es_format.dart';
import 'package:medicalbooking_portal/core/time/branch_time.dart';

void main() {
  test('branch time converts UTC to UTC-5 and back', () {
    final utc = utcFromBranch(2026, 11, 2, 8, 30);
    expect(utc, DateTime.utc(2026, 11, 2, 13, 30));
    expect(timeLabel(branchTime(utc)), '08:30');
  });

  test('labels are in Spanish', () {
    final monday = DateTime(2026, 11, 2, 9, 5);
    expect(dayLabel(monday), 'lun 2 nov');
    expect(dateTimeLabel(monday), 'lun 2 nov · 09:05');
    expect(money(8), '\$8.00');
  });
}

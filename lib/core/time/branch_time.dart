/// The schema stores UTC; branches use America/Guayaquil (UTC-5, no DST).
const branchUtcOffset = Duration(hours: -5);

/// Wall-clock time at the branch for a UTC instant. Only read its fields.
DateTime branchTime(DateTime utc) => utc.toUtc().add(branchUtcOffset);

/// UTC instant for a branch wall-clock time.
DateTime utcFromBranch(int year, int month, int day, int hour, int minute) =>
    DateTime.utc(year, month, day, hour, minute).subtract(branchUtcOffset);

/// Calendar day at the branch right now.
DateTime branchToday() {
  final now = branchTime(DateTime.now());
  return DateTime(now.year, now.month, now.day);
}

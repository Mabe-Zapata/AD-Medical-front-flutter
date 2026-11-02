const _days = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
const _months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

/// Spanish short date, e.g. "lun 2 nov". Expects a branch wall-clock time.
String dayLabel(DateTime d) => '${_days[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';

String timeLabel(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

String dateTimeLabel(DateTime d) => '${dayLabel(d)} · ${timeLabel(d)}';

String money(double value, [String currency = 'USD']) =>
    '${currency == 'USD' ? '\$' : '$currency '}${value.toStringAsFixed(2)}';

import 'package:flutter/material.dart' show DateUtils;
import 'package:intl/intl.dart';

final _dayMonth = DateFormat('d MMM');
final _weekdayTime = DateFormat('EEE, d MMM · HH:mm');
final _full = DateFormat('EEEE, d MMMM yyyy');
final _time = DateFormat('HH:mm');

String formatShortDate(DateTime d) => _dayMonth.format(d);
String formatDateTime(DateTime d) => _weekdayTime.format(d);
String formatFullDate(DateTime d) => _full.format(d);
String formatTime(DateTime d) => _time.format(d);

String relativeDay(DateTime date, {DateTime? now}) {
  final today = DateUtils.dateOnly(now ?? DateTime.now());
  final days = DateUtils.dateOnly(date).difference(today).inDays;
  if (days == 0) return 'Today';
  if (days == 1) return 'Tomorrow';
  if (days > 1) return 'In $days days';
  if (days == -1) return 'Yesterday';
  return '${-days} days ago';
}

String formatPercent(double v) => '${(v * 100).round()}%';
String weekdayShort(DateTime d) => DateFormat('EEE').format(d);
String formatDayHeader(DateTime d) => DateFormat('EEEE, d MMMM').format(d);
String formatStamp(DateTime d) => DateFormat('d MMM yyyy · HH:mm').format(d);

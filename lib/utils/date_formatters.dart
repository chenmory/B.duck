import 'package:flutter/material.dart';

String twoDigits(int value) => value.toString().padLeft(2, '0');

String formatClock(DateTime time) {
  return '${twoDigits(time.hour)}:${twoDigits(time.minute)}';
}

String formatDate(DateTime time) {
  return '${time.year}-${twoDigits(time.month)}-${twoDigits(time.day)}';
}

String formatDateTime(DateTime time) {
  return '${formatDate(time)} ${formatClock(time)}';
}

TimeOfDay parseTimeOfDay(String value) {
  final parts = value.split(':');
  return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
}

String formatTimeOfDay(TimeOfDay time) {
  return '${twoDigits(time.hour)}:${twoDigits(time.minute)}';
}

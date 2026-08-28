/// Formats a timestamp the way a person would say it.
///
/// History entries are read at a glance, so "2 hours ago" beats a date stamp
/// until the entry is old enough that the date is what actually helps.
String formatRelative(DateTime timestamp, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final elapsed = reference.difference(timestamp);

  if (elapsed.inSeconds < 60) return 'just now';
  if (elapsed.inMinutes < 60) {
    final minutes = elapsed.inMinutes;
    return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
  }
  if (elapsed.inHours < 24) {
    final hours = elapsed.inHours;
    return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
  }
  if (elapsed.inDays == 1) return 'yesterday';
  if (elapsed.inDays < 7) return '${elapsed.inDays} days ago';

  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${timestamp.day} ${months[timestamp.month - 1]}';
}

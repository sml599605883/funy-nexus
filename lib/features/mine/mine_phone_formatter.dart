String formatMinePhone(String? phone) {
  final value = phone?.trim() ?? '';
  if (value.length <= 7) return value;
  return '${value.substring(0, 3)} **** ${value.substring(value.length - 4)}';
}

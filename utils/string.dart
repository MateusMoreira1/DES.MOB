extension StringExtension on String {
  String capitalize() {
    return isEmpty ? this : this[0].toUpperCase() + substring(1);
  }

  String sanitize() {
    return replaceAll('\n', ' ').replaceAll('\f', ' ');
  }
}

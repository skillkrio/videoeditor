String formatTime(double seconds) {
  int minutes = seconds ~/ 60;
  int sec = (seconds % 60).toInt();
  double milli = (seconds % 1) * 100; // Convert to hundredths of a second

  return "${minutes.toString().padLeft(2, '0')}:"
      "${sec.toString().padLeft(2, '0')}:"
      "${milli.toStringAsFixed(2).padLeft(5, '0')}"; // Ensures 2 decimal places
}

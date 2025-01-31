String formatTime(double seconds) {
  int minutes = seconds ~/ 60;
  int sec = (seconds % 60).toInt();
  int micro = ((seconds % 1) * 1e6 ~/ 100000).toInt(); // Extract first digit of microseconds

  return "${minutes.toString().padLeft(2, '0')}:"
      "${sec.toString().padLeft(2, '0')}:"
      "$micro";
}

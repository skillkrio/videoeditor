String formatTime(double seconds) {
  int minutes = seconds ~/ 60;
  int sec = (seconds % 60).toInt();
  int micro = ((seconds % 1) * 100).toInt(); 

  return "${minutes.toString().padLeft(2, '0')}:"
      "${sec.toString().padLeft(2, '0')}:"
      "${micro.toString().padLeft(2, '0')}";
}

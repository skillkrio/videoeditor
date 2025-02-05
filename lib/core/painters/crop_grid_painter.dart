// Custom painter to draw the grid overlay
import 'package:flutter/material.dart';

class CropGridPainter extends CustomPainter {
  final Rect cropRect;

  CropGridPainter(this.cropRect);

  @override
  void paint(Canvas canvas, Size size) {
    Paint overlayPaint = Paint()..color = Colors.black.withAlpha(10);
    Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw semi-transparent overlay
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), overlayPaint);

    // Clear the crop area
    canvas.drawRect(cropRect, borderPaint);

    // Draw grid lines inside the crop area
    Paint gridPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1;

    // Vertical grid lines
    for (int i = 1; i < 3; i++) {
      double dy = cropRect.left + (cropRect.width / 3) * i;
      // log('print the $i');
      // log('print the  dx value $dy');

      canvas.drawLine(
          Offset(dy, cropRect.top), Offset(dy, cropRect.bottom), gridPaint);
    }

    // Horizontal grid lines
    for (int i = 1; i < 3; i++) {
      double dx = cropRect.top + (cropRect.height / 3) * i;
      // log('print the $i');
      // log('print the dy value $dx');
      canvas.drawLine(
          Offset(cropRect.left, dx), Offset(cropRect.right, dx), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

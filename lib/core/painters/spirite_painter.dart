import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class SpriteFramePainter extends CustomPainter {
  final ui.Image spriteSheetImage;
  final Rect frameRect;

  SpriteFramePainter(this.spriteSheetImage, this.frameRect);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final src = frameRect;
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(spriteSheetImage, src, dst, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

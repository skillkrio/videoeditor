import 'dart:developer';
import 'package:flutter/material.dart';

class MasterClipper extends CustomClipper<Rect> {
  MasterClipper({required this.resizableCanvasWidth, required this.start});
  final double resizableCanvasWidth;
  final double start;
  @override
  Rect getClip(Size size) {
    log(start.toString());
    return Rect.fromLTWH(start, 0, resizableCanvasWidth, 60);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) {
    return true;
  }
}

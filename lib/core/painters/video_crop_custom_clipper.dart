import 'package:flutter/material.dart';

class VideoCropper extends CustomClipper<Rect> {
  final Rect cropRect;

  VideoCropper(this.cropRect);

  @override
  Rect getClip(Size size) => cropRect;

  @override
  bool shouldReclip(VideoCropper oldClipper) => cropRect != oldClipper.cropRect;
}

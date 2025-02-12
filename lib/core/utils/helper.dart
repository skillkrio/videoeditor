import 'package:flutter/material.dart';

class HelperUtils {
  static Alignment getVideoAlignment(Rect cropRect, Size videoSize) {
    double centerX = videoSize.width / 2;
    double centerY = videoSize.height / 2;

    double cropCenterX = cropRect.left + cropRect.width / 2;
    double cropCenterY = cropRect.top + cropRect.height / 2;

    bool isLeft = cropCenterX < centerX * 0.75;
    bool isRight = cropCenterX > centerX * 1.25;
    bool isCenterX = !isLeft && !isRight;

    bool isTop = cropCenterY < centerY * 0.75;
    bool isBottom = cropCenterY > centerY * 1.25;
    bool isCenterY = !isTop && !isBottom;

    if (isTop && isLeft) return Alignment.topLeft;
    if (isTop && isCenterX) return Alignment.topCenter;
    if (isTop && isRight) return Alignment.topRight;
    if (isCenterY && isLeft) return Alignment.centerLeft;
    if (isCenterY && isCenterX) return Alignment.center;
    if (isCenterY && isRight) return Alignment.centerRight;
    if (isBottom && isLeft) return Alignment.bottomLeft;
    if (isBottom && isCenterX) return Alignment.bottomCenter;
    if (isBottom && isRight) return Alignment.bottomRight;

    return Alignment.center; // Default case
  }
}
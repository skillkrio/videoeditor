import 'package:flutter/material.dart';

class HandleWidget extends StatelessWidget {
  const HandleWidget(
      {super.key,
      required this.height,
      required this.width,
      this.strokeWidth = 3});
  final double height;
  final double width;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(4),
          ),
          width: 3,
          height: height / 4,
        ),
      ),
    );
  }
}

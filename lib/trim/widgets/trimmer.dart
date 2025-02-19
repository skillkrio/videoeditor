import 'dart:developer';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:gudshow/core/painters/spirite_painter.dart';
import 'package:gudshow/trim/widgets/handle_wdiget.dart';

class Trimmer extends StatefulWidget {
  final ui.Image spriteSheetImage;
  final List<Rect> frameRects;
  final bool isHighlighted;
  final double startTime;
  final double endTime;
  final int totalFrames;
  final double totalTimeDuration;
  final double width;
  final List<Map<String, dynamic>> timeInfoList;
  final double initialSpace;
  final double transformedValue;
  final int groupIndex;
  final Function(Map<String, dynamic> info, int index) timeFrameUpdater;
  final void Function(
      {required double binderValue,
      required int lastGroupIndex,
      required bool isSaveDidUpdateWidget}) parentRepositioner;
  final double binderValue;
  final double totalFrameWidth;
  final double newTotalWidth;
  final void Function(
      {required int groupIndex, required double movedLeftOffset}) recompute;

  const Trimmer({
    super.key,
    required this.spriteSheetImage,
    required this.frameRects,
    required this.totalFrames,
    required this.isHighlighted,
    required this.startTime,
    required this.width,
    required this.totalTimeDuration,
    required this.endTime,
    required this.timeInfoList,
    required this.initialSpace,
    required this.transformedValue,
    required this.groupIndex,
    required this.timeFrameUpdater,
    required this.binderValue,
    required this.parentRepositioner,
    required this.totalFrameWidth,
    required this.recompute,
    required this.newTotalWidth,
  });

  @override
  State<Trimmer> createState() => _TrimmerState();
}

class _TrimmerState extends State<Trimmer> {
  late final ScrollController _scrollController;
  double leftStartHandleOffsetX = 0;
  // double leftInitialTranslation = 0;
  double resizabletotalCanvasWitdh = 0;
  double totalFrameWidthForLeftDragHandle = 0;
  double binderValue = 0;
  bool canUpdateTotalFrameWidthForLeftDragHandle = false;
  @override
  void initState() {
    super.initState();
    resizabletotalCanvasWitdh = widget.newTotalWidth;
    totalFrameWidthForLeftDragHandle = widget.newTotalWidth;
    _scrollController = ScrollController();
    leftStartHandleOffsetX = widget.initialSpace;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(Trimmer oldWidget) {
    super.didUpdateWidget(oldWidget);
    resizabletotalCanvasWitdh = widget.newTotalWidth;

    if (canUpdateTotalFrameWidthForLeftDragHandle) {
      totalFrameWidthForLeftDragHandle = widget.newTotalWidth;
      canUpdateTotalFrameWidthForLeftDragHandle = false;
    }
  }

  double calculateTrimmedTime({
    required double transformedValue, // Dragged value from left
    required double resizedWidth, // Final width after right-side trim
    required double totalWidth, // Original width
    required bool isFromLeftHandle,
    bool updateCb = false,
  }) {
    double timePerPixel = 0.005; // Adjusted time per pixel
    double startTime;
    double endTime;
    double newWidth;

    if (isFromLeftHandle) {
      // If trimming from the left, adjust start time based on transformed value
      startTime =
          (transformedValue * timePerPixel).clamp(0, widget.totalTimeDuration);

      // Calculate newWidth based on resizedWidth and transformedValue
      newWidth = resizedWidth;

      // Calculate endTime based on transformed value, resized width, and total width
      endTime = ((transformedValue + resizedWidth) * timePerPixel)
          .clamp(0, widget.totalTimeDuration);
    } else {
      // If trimming from the right, calculate start time from the transformed value
      startTime =
          (transformedValue * timePerPixel).clamp(0, widget.totalTimeDuration);

      // Width directly provided for right handle
      newWidth = resizedWidth;

      // Calculate endTime based on transformed value, resized width, and total width
      endTime = ((transformedValue + resizedWidth) * timePerPixel)
          .clamp(0, widget.totalTimeDuration);
    }

    // Update the modified map
    final modifiedMap = widget.timeInfoList[widget.groupIndex];
    modifiedMap['transformedValue'] =
        transformedValue.abs(); // Use positive value
    modifiedMap['startTime'] = startTime;
    modifiedMap['endTime'] = endTime;
    modifiedMap['newTotalWidth'] = newWidth;
    modifiedMap['initialSpace'] = transformedValue;

    log(modifiedMap.toString());

    if (updateCb) widget.timeFrameUpdater(modifiedMap, widget.groupIndex);

    return newWidth;
  }

  @override
  Widget build(BuildContext context) {
    //  leftInitialTranslation = widget.initialSpace;
    return LayoutBuilder(builder: (context, constraints) {
      double dragHandleWidth = 15;
      double dragHandleHeight = 60;

      return StatefulBuilder(builder: (context, stateSet) {
        return Container(
          // color: Colors.deepPurple.withOpacity(0.5),
          height: 100,
          width: resizabletotalCanvasWitdh,
          transform: Matrix4.translationValues(0, 0, 0),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              //Thumbmail
              Positioned(
                left: 0,
                height: 60,
                child: Container(
                  constraints: BoxConstraints(minWidth: 0),
                  clipBehavior: Clip.hardEdge,
                  height: 60,
                  width: resizabletotalCanvasWitdh,
                  transform: Matrix4.translationValues(0, 0, 0),
                  decoration: widget.isHighlighted
                      ? BoxDecoration(
                          border: Border.all(color: Colors.blue, width: 2),
                        )
                      : BoxDecoration(
                          border: Border.all(
                            color: Colors.white,
                          ),
                        ),
                  child: OverflowBox(
                    minWidth: 0,
                    maxWidth: widget.totalFrameWidth,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      transform: Matrix4.translationValues(
                          -leftStartHandleOffsetX, 0, 0),
                      height: 60,
                      child: ListView.builder(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.frameRects.length,
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          final frame = widget.frameRects[index];
                          return RepaintBoundary(
                            child: CustomPaint(
                              size: Size(frame.width, frame.height),
                              painter: SpriteFramePainter(
                                  widget.spriteSheetImage, frame),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ), //! left handle
              if (widget.isHighlighted)
                Positioned(
                  height: 60,
                  width: widget.isHighlighted ? dragHandleWidth : 0,
                  left: 0,
                  child: GestureDetector(
                    onHorizontalDragStart: (details) {
                      // leftInitialTranslation = widget.initialSpace;
                      leftStartHandleOffsetX = widget.initialSpace;
                    },
                    onHorizontalDragEnd: (details) {
                      binderValue = 0;
                      calculateTrimmedTime(
                          updateCb: true,
                          isFromLeftHandle: true,
                          resizedWidth: resizabletotalCanvasWitdh,
                          totalWidth: widget.totalFrameWidth,
                          transformedValue: leftStartHandleOffsetX);
                      widget.parentRepositioner(
                          binderValue: binderValue,
                          lastGroupIndex: widget.groupIndex,
                          isSaveDidUpdateWidget: false);
                      // leftStartHandleOffsetX = 0;
                      canUpdateTotalFrameWidthForLeftDragHandle = true;

                      // log(widget.width.toString() +
                      //     "total width --- binder :${binderValue}");
                      // widget.recompute(
                      //     groupIndex: widget.groupIndex,
                      //     movedLeftOffset: leftStartHandleOffsetX);
                      stateSet(
                        () {},
                      );
                    },
                    onHorizontalDragUpdate: (details) {
                      final double dx = details.delta.dx;

// Update the leftStartHandleOffsetX correctly
                      final double previousWidth = resizabletotalCanvasWitdh;
                      final double maxWidth =
                          (resizabletotalCanvasWitdh) + leftStartHandleOffsetX;

                      resizabletotalCanvasWitdh =
                          (resizabletotalCanvasWitdh - dx).clamp(0, maxWidth);
                      //Preventing the binder scroll when reached 0
                      if (leftStartHandleOffsetX > 0) {
                        binderValue += dx;
                      }
                      leftStartHandleOffsetX +=
                          (previousWidth - resizabletotalCanvasWitdh);

                      log("left handler - $leftStartHandleOffsetX");

// Ensure proper time calculation
                      calculateTrimmedTime(
                          updateCb: true,
                          isFromLeftHandle: true,
                          resizedWidth: resizabletotalCanvasWitdh,
                          totalWidth: widget.totalFrameWidth,
                          transformedValue: leftStartHandleOffsetX);

                      widget.parentRepositioner(
                          binderValue: binderValue,
                          lastGroupIndex: widget.groupIndex,
                          isSaveDidUpdateWidget: false);

                      stateSet(() {}); // Update UI
                    },
                    child: HandleWidget(
                      height: dragHandleHeight,
                      width: dragHandleWidth,
                    ),
                  ),
                ),
              //! right handle
              if (widget.isHighlighted)
                Positioned(
                  right: 0,
                  width: widget.isHighlighted ? dragHandleWidth : 0,
                  child: GestureDetector(
                    onHorizontalDragEnd: (details) {
                      calculateTrimmedTime(
                          resizedWidth: resizabletotalCanvasWitdh,
                          totalWidth: widget.totalFrameWidth,
                          updateCb: true,
                          isFromLeftHandle: false,
                          transformedValue: leftStartHandleOffsetX);
                    },
                    onHorizontalDragStart: (details) {
                      leftStartHandleOffsetX = widget.initialSpace;
                    },
                    onHorizontalDragUpdate: (details) {
                      final double dx = details.delta.dx;
                      final double newWidth = resizabletotalCanvasWitdh + dx;
                      final double minWidth = 0;

                      //! Adjust max width dynamically based on left handle's position
                      final double maxWidth =
                          widget.totalFrameWidth - leftStartHandleOffsetX;

                      resizabletotalCanvasWitdh =
                          newWidth.clamp(minWidth, maxWidth);
                      stateSet(() {}); // Update UI
                    },
                    child: HandleWidget(
                        height: dragHandleHeight, width: dragHandleWidth),
                  ),
                ),
            ],
          ),
        );
      });
    });
  }
}

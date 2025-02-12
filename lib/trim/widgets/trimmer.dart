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
  final Function(double binderValue, int lastGroupIndex,
      double lastMovedLeftOffset, bool canUseBinderVal) binderUpdater;
  final double binderValue;
  final double totalFrameWidth;
  final Function({required int groupIndex, required double movedLeftOffset})
      recompute;

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
    required this.binderUpdater,
    required this.totalFrameWidth,
    required this.recompute,
  });

  @override
  State<Trimmer> createState() => _TrimmerState();
}

class _TrimmerState extends State<Trimmer> {
  late final ScrollController _scrollController;
  double leftStartHandleOffsetX = 0;
  double rightEndHandleOffsetX = 0;
  double bindingValue = 0;
  double leftInitialTranslation = 0;
  @override
  void initState() {
    super.initState();
    // leftStartHandleOffsetX = widget.transformedValue;
    log('init called ${widget.width}');
    _scrollController = ScrollController();
    leftInitialTranslation = widget.initialSpace;
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _scrollController.position.jumpTo(widget.initialSpace);
    // });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(Trimmer oldWidget) {
    super.didUpdateWidget(oldWidget);
    bindingValue = widget.binderValue;
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
    double newWidth;

    if (isFromLeftHandle) {
      // If trimming from the left, adjust start time based on transformed value
      startTime =
          (transformedValue * timePerPixel).clamp(0, widget.totalTimeDuration);
      newWidth = (totalWidth - transformedValue - (totalWidth - resizedWidth))
          .clamp(0, totalWidth); // Ensure valid width
    } else {
      // If trimming from the right, keep start time the same
      startTime = 0.0;
      newWidth = resizedWidth; // Width directly provided
    }

    double endTime = (startTime + newWidth * timePerPixel)
        .clamp(0, widget.totalTimeDuration); // Ensure valid end time

    // Update the modified map
    final modifiedMap = widget.timeInfoList[widget.groupIndex];
    modifiedMap['transformedValue'] =
        transformedValue.abs(); // Use positive value
    modifiedMap['startTime'] = startTime;
    modifiedMap['endTime'] = endTime;
    modifiedMap['totalWidth'] = newWidth;
    modifiedMap['initialSpace'] =
        -leftInitialTranslation - leftStartHandleOffsetX;

    log(modifiedMap.toString());

    if (updateCb) widget.timeFrameUpdater(modifiedMap, widget.groupIndex);

    return newWidth;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      double resizabletotalCanvasWitdh = widget.width;
      double dragHandleWidth = 15;
      double dragHandleHeight = 60;

      return StatefulBuilder(builder: (context, stateSet) {
        return Container(
          // color: Colors.deepPurple.withOpacity(0.5),
          height: 100,
          width: widget.isHighlighted
              ? resizabletotalCanvasWitdh + dragHandleWidth
              : resizabletotalCanvasWitdh,
          transform: Matrix4.translationValues(0, 0, 0),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              //Thumbmail
              Positioned(
                left: widget.isHighlighted ? dragHandleWidth : 0,
                height: 60,
                child: Container(
                  constraints: BoxConstraints(minWidth: 0),
                  clipBehavior: Clip.hardEdge,
                  height: 60,
                  width: resizabletotalCanvasWitdh - leftStartHandleOffsetX,
                  transform:
                      Matrix4.translationValues(leftStartHandleOffsetX, 0, 0),
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
                          -leftInitialTranslation - leftStartHandleOffsetX,
                          0,
                          0),
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
                  left: leftStartHandleOffsetX,
                  child: GestureDetector(
                    onHorizontalDragEnd: (details) {
                      calculateTrimmedTime(
                          updateCb: true,
                          isFromLeftHandle: true,
                          resizedWidth: resizabletotalCanvasWitdh,
                          totalWidth: widget.totalFrameWidth,
                          transformedValue: leftStartHandleOffsetX);
                      widget.recompute(
                          groupIndex: widget.groupIndex,
                          movedLeftOffset: leftStartHandleOffsetX);
                      stateSet(
                        () {},
                      );
                    },
                    onHorizontalDragUpdate: (details) {
                      leftStartHandleOffsetX += details.delta.dx;
                      leftStartHandleOffsetX = leftStartHandleOffsetX.clamp(
                          0, resizabletotalCanvasWitdh);
                      widget.binderUpdater(
                          leftStartHandleOffsetX, widget.groupIndex, 0, true);
                      resizabletotalCanvasWitdh =
                          resizabletotalCanvasWitdh - details.delta.dx;
                      final double minWidth =
                          leftStartHandleOffsetX; // Set a reasonable minimum width
                      //! modify maxwidth to take only the available space
                      final double maxWidth = widget.totalFrameWidth -
                          widget.initialSpace; // Allow some expansion

                      resizabletotalCanvasWitdh = double.parse(
                          resizabletotalCanvasWitdh
                              .clamp(minWidth, maxWidth)
                              .toStringAsFixed(2));
                      log("left offset $leftStartHandleOffsetX $resizabletotalCanvasWitdh");
                      stateSet(() {});
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
                  height: 60,
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
                    onHorizontalDragUpdate: (details) {
                      final double dx = details.delta.dx;
                      final double newWidth = resizabletotalCanvasWitdh + dx;
                      final double minWidth =
                          leftStartHandleOffsetX; // Set a reasonable minimum width
                      //! modify maxwidth to take only the available space
                      final double maxWidth = widget.totalFrameWidth -
                          leftInitialTranslation; // Allow some expansion

                      resizabletotalCanvasWitdh = double.parse(newWidth
                          .clamp(minWidth, maxWidth)
                          .toStringAsFixed(2));
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

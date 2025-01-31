import 'dart:developer';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:gudshow/core/painters/spirite_painter.dart';
import 'package:gudshow/trim/widgets/handle_wdiget.dart';
import 'package:gudshow/core/painters/master_clipper.dart';

class FrameRow extends StatefulWidget {
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
  const FrameRow({
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
  });

  @override
  State<FrameRow> createState() => _FrameRowState();
}

class _FrameRowState extends State<FrameRow> {
  late final ScrollController _scrollController;
  double leftStartHandleOffsetX = 0;
  double rightEndHandleOffsetX = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.position.jumpTo(widget.initialSpace);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(FrameRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients)
        _scrollController.jumpTo(widget.initialSpace);
    });
  }

  double calculateTrimmedTime(
      {required double transformedValue,
      required double originalWidth,
      required bool isFromLeftHandle,
      bool updateCb = false}) {
    double newWidth = 0;
    const double timePerPixel = 0.00025;

    double startTime = transformedValue * timePerPixel;
    if (isFromLeftHandle) {
      newWidth = originalWidth - transformedValue;
    }

    double endTime = originalWidth * timePerPixel;
    final modifiedMap = widget.timeInfoList[widget.groupIndex];
    modifiedMap['transformedValue'] = transformedValue;
    modifiedMap['startTime'] = startTime;
    modifiedMap['endTime'] = endTime;
    modifiedMap['totalWidth'] = originalWidth;
    if (updateCb) widget.timeFrameUpdater(modifiedMap, widget.groupIndex);
    return newWidth;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      int totalCanvasWidth = (widget.totalFrames * 100);
      double resizabletotalCanvasWitdh = double.parse(widget.width.toString());
      double dragHandleWidth = 10;
      double dragHandleHeight = 60;
      return StatefulBuilder(builder: (context, stateSet) {
        return SizedBox(
          height: 100,
          width: resizabletotalCanvasWitdh,
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.isHighlighted)
                    Transform.translate(
                      offset: Offset(leftStartHandleOffsetX, 0),
                      child: GestureDetector(
                        onHorizontalDragEnd: (details) {
                          calculateTrimmedTime(
                              updateCb: true,
                              isFromLeftHandle: true,
                              originalWidth: resizabletotalCanvasWitdh,
                              transformedValue: leftStartHandleOffsetX);
                        },
                        onHorizontalDragUpdate: (details) {
                          leftStartHandleOffsetX += details.delta.dx;
                          leftStartHandleOffsetX = leftStartHandleOffsetX.clamp(
                              0,
                              resizabletotalCanvasWitdh -
                                  (dragHandleWidth * 2));
                          stateSet(() {});
                        },
                        child: HandleWidget(
                          height: dragHandleHeight,
                          width: dragHandleWidth,
                        ),
                      ),
                    ),
                  Expanded(
                    child: IgnorePointer(
                        ignoring: false,
                        child: Container(
                            clipBehavior: widget.isHighlighted
                                ? Clip.hardEdge
                                : Clip.none,
                            decoration: widget.isHighlighted
                                ? BoxDecoration(
                                    border: Border.all(
                                        color: Colors.blue, width: 3),
                                    borderRadius: BorderRadius.circular(5),
                                  )
                                : null,
                            child: ClipRect(
                                clipper: MasterClipper(
                                    resizableCanvasWidth:
                                        resizabletotalCanvasWitdh,
                                    start: leftStartHandleOffsetX),
                                child: SizedBox(
                                  height:
                                      60, // Set height for consistent layout
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
                                )))),
                  ),
                  if (widget.isHighlighted)
                    Transform.translate(
                      offset: Offset(-rightEndHandleOffsetX, 0),
                      child: GestureDetector(
                        onHorizontalDragEnd: (details) {
                          calculateTrimmedTime(
                              updateCb: true,
                              isFromLeftHandle: false,
                              originalWidth: resizabletotalCanvasWitdh,
                              transformedValue: leftStartHandleOffsetX);
                        },
                        onHorizontalDragUpdate: (details) {
                          final double dx = details.delta.dx;
                          final double newWidth =
                              resizabletotalCanvasWitdh + dx;

                          // Adjust clamping range to prevent getting stuck
                          final double minWidth =
                              30; // Set a reasonable minimum width
                          final double maxWidth =
                              totalCanvasWidth + 1000; // Allow some expansion

                          resizabletotalCanvasWitdh = double.parse(newWidth
                              .clamp(minWidth, maxWidth)
                              .toStringAsFixed(2));

                          log("Dragged DX: $dx");
                          log("Updated Width: $resizabletotalCanvasWitdh");

                          stateSet(() {}); // Update UI
                        },
                        child: HandleWidget(
                            height: dragHandleHeight, width: dragHandleWidth),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      });
    });
  }
}

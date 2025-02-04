import 'dart:async';
import 'dart:developer';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gudshow/core/utils/time_formatter.dart';
import 'package:gudshow/trim/widgets/trimmer.dart';

typedef MyBuilder = void Function(BuildContext context, void Function() splitMethod);

class TrimmerAndSplit extends StatefulWidget {
  const TrimmerAndSplit(
      {super.key, required this.builder, required this.isVideoInitialized, required this.timeInfoUpdater});
  final MyBuilder builder;
  final ValueChanged<List<Map<String, dynamic>>> timeInfoUpdater;
  final bool isVideoInitialized;

  @override
  State<TrimmerAndSplit> createState() => _TrimmerAndSplitState();
}

class _TrimmerAndSplitState extends State<TrimmerAndSplit> {
  ui.Image? spriteSheetImage;
  List<List<Rect>> frameGroups = []; // Flat list of frame groups
  late List<Rect> initialFrames;
  final int frameWidth = 100;
  final int frameHeight = 60;
  final double totalDuration = 10.0; // Total video duration in seconds
  double frameDuration = 0.0;
  late int totalFrames;
  late final ScrollController _scrollController;
  late final ScrollController _timelineScrollController;
  bool _isSyncing = false; // Prevents circular updates

  int clampedIndex = 0;
  late double redLinePosition; // Fixed red line position (pixels)
  final double sliderWidth = 5; // Width of the red line
  int? highlightedIndex;
  double currentTime = 0.0;
  List<Map<String, dynamic>> timeInfoList = [];
  double groupBinderValue = 0;

  Future<void> _loadSpriteSheet() async {
    try {
      final spriteSheet = await _loadNetworkImage(
          'https://d2e983ilc6ufv4.cloudfront.net/upload_media/112/112/1271058019/frame_image.jpg');
      setState(() {
        spriteSheetImage = spriteSheet;
        initialFrames = _generateFrameRects(
          spriteSheet.width,
          spriteSheet.height,
          frameWidth,
          frameHeight,
        );
        totalFrames = initialFrames.length;
        frameDuration = totalDuration / totalFrames;
        frameGroups = [initialFrames];

        timeInfoList.add({
          'index': 'init',
          'startTime': 0.0,
          'endTime': 0.0 + initialFrames.length * frameDuration,
          'totalWidth': initialFrames.length * frameWidth.toDouble(),
          'totalTimeDuration': initialFrames.length * frameDuration,
          'totalFrames': initialFrames.length,
          'initialSpace': 0.0,
          'transformedValue': 0.0
        });
        widget.timeInfoUpdater(timeInfoList);
      });
    } catch (e) {
      print("Error loading sprite sheet: $e");
    }
  }

  Future<ui.Image> _loadNetworkImage(String url) async {
    try {
      final uri = Uri.parse(url);
      final httpResponse = await NetworkAssetBundle(uri).load("");
      final codec = await ui.instantiateImageCodec(httpResponse.buffer.asUint8List());
      final frameInfo = await codec.getNextFrame();
      return frameInfo.image;
    } catch (e) {
      throw Exception("Failed to load image from network: $e");
    }
  }

  List<Rect> _generateFrameRects(int width, int height, int frameWidth, int frameHeight) {
    final columns = width ~/ frameWidth;
    final rows = height ~/ frameHeight;
    final rects = <Rect>[];

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < columns; col++) {
        final rect = Rect.fromLTWH(
          col * frameWidth.toDouble(),
          row * frameHeight.toDouble(),
          frameWidth.toDouble(),
          frameHeight.toDouble(),
        );
        rects.add(rect);
      }
    }
    return rects;
  }

  double calculateWidthFromTime(double time) {
    double frameWidth = 100.0; // width of one frame in pixels
    double frameDuration = 0.25; // duration of one frame in seconds
    double width = (time / frameDuration) * frameWidth;
    return width;
  }

  void _onScroll() {
    final scrollOffset = _scrollController.offset;

    // Adjusted scroll offset to account for left padding (200px)
    final adjustedScrollOffset = scrollOffset - redLinePosition;

    // Calculate floating-point frame index at red line position
    final double redLineExactFrameIndex = (adjustedScrollOffset + redLinePosition) / frameWidth;

    // Clamp within valid frame range
    clampedIndex = redLineExactFrameIndex.floor().clamp(0, totalFrames - 1);

    // Get exact time based on fractional frame position
    currentTime = redLineExactFrameIndex * frameDuration;

    print("Frame at red line: $clampedIndex");
    print("Exact Time: ${currentTime.toStringAsFixed(2)}s");

    setState(() {});
  }

  void _splitFrames() {
    if (frameGroups.isEmpty || timeInfoList.isEmpty) return;

    List<List<Rect>> newFrameGroups = [];
    List<Map<String, dynamic>> newTimeInfoList = [];

    int accumulatedCount = 0;

    for (int i = 0; i < frameGroups.length; i++) {
      final group = frameGroups[i];
      final timeInfo = timeInfoList[i];

      double groupStartTime = timeInfo['startTime'];
      double groupEndTime = timeInfo['endTime'];

      if (currentTime >= groupStartTime && currentTime <= groupEndTime) {
        int splitIndex = ((currentTime - groupStartTime) / frameDuration).round();
        // Ensure splitIndex is within bounds
        if (splitIndex < 0 || splitIndex >= group.length) return;

        // Split the frames
        List<Rect> firstPart = group.sublist(0, splitIndex + 1);
        List<Rect> secondPart = group.sublist(splitIndex + 1);

        newFrameGroups.add(firstPart);
        newFrameGroups.add(secondPart);

        // Remove the old time info entry before adding new ones
        if (timeInfoList[i]['index'] == 'init') {
          timeInfoList.removeAt(i);
        }

        // Update time values (rounded to 2 decimal places)
        double firstPartStart = groupStartTime;
        double firstPartEnd = double.parse(currentTime.toStringAsFixed(2));
        double secondPartStart = firstPartEnd;
        double secondPartEnd = double.parse(groupEndTime.toStringAsFixed(2));

        // Compute width using time-to-width conversion
        double firstPartWidth = ((firstPartEnd - firstPartStart) / frameDuration) * frameWidth;
        double secondPartWidth = ((secondPartEnd - secondPartStart) / frameDuration) * frameWidth;

        // Insert the new time info
        newTimeInfoList.add({
          'index': '${i}_first',
          'startTime': firstPartStart,
          'endTime': firstPartEnd,
          'totalWidth': firstPartWidth,
          'totalTimeDuration': double.parse((firstPartEnd - firstPartStart).toStringAsFixed(2)),
          'totalFrames': firstPart.length,
          'initialSpace': calculateWidthFromTime(firstPartStart),
          'transformedValue': firstPartStart
        });

        newTimeInfoList.add({
          'index': '${i}_second',
          'startTime': secondPartStart,
          'endTime': secondPartEnd,
          'totalWidth': secondPartWidth,
          'totalTimeDuration': double.parse((secondPartEnd - secondPartStart).toStringAsFixed(2)),
          'totalFrames': secondPart.length,
          'initialSpace': calculateWidthFromTime(secondPartStart),
          'transformedValue': secondPartStart
        });
        highlightedIndex = i + 1;
        print("Split at time: $currentTime");
        print("First part: Start $firstPartStart, End $firstPartEnd, Width $firstPartWidth");
        print("Second part: Start $secondPartStart, End $secondPartEnd, Width $secondPartWidth");
      } else {
        newFrameGroups.add(group);
        newTimeInfoList.add(timeInfo);
      }
      widget.timeInfoUpdater(newTimeInfoList);
      accumulatedCount += group.length;
    }

    setState(() {
      frameGroups = newFrameGroups;
      timeInfoList = newTimeInfoList;
    });

    print("Updated Time Info List: $timeInfoList");
  }

  void timeFrameUpdate(Map<String, dynamic> info, int index) {
    timeInfoList[index] = info;
    log(timeInfoList.toString());
    //     setState(() {});
  }

  void groupBinder(double value) {
    log(value.toString() + "binder value");
    setState(() {
      groupBinderValue = value;
    });
  }

  void _syncScroll(ScrollController source, ScrollController target) {
    if (_isSyncing) return; // Prevents infinite loop
    _isSyncing = true;
    target.jumpTo(source.offset);
    _isSyncing = false;
  }

  void infoUpdater(Map<String, dynamic> info, int index) {
    timeInfoList[index] = info;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _loadSpriteSheet();
    widget.builder.call(context, _splitFrames);
    _scrollController = ScrollController();
    _timelineScrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _scrollController.addListener(() {
      _syncScroll(_scrollController, _timelineScrollController);
    });

    _timelineScrollController.addListener(() {
      _syncScroll(_timelineScrollController, _scrollController);
    });
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
    _timelineScrollController.dispose();
    _scrollController.removeListener(_onScroll);
  }

  @override
  Widget build(BuildContext context) {
    redLinePosition = MediaQuery.sizeOf(context).width * .38;

    if (spriteSheetImage == null || !widget.isVideoInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    List<Rect> allFrames = frameGroups.expand((group) => group).toList();
    double totalTime = allFrames.length * frameDuration; // Total video duration

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 30,
          child: ListView.builder(
            controller: _timelineScrollController,
            scrollDirection: Axis.horizontal,
            itemCount: (timeInfoList.fold(0.0, (sum, timeInfo) => sum + timeInfo['totalWidth']) / frameWidth).ceil() +
                2, // +2 for padding
            itemBuilder: (context, index) {
              // Calculate total width by summing the totalWidth values of all timeInfoList items
              double totalWidthSum = timeInfoList.fold(0.0, (sum, timeInfo) => sum + timeInfo['totalWidth']);

              // Calculate the total duration based on totalWidth and frame duration
              double totalDuration = timeInfoList.fold(0.0, (sum, timeInfo) => sum + timeInfo['totalTimeDuration']);

              // Handle padding logic for the first and last items
              if (index == 0) {
                return SizedBox(width: redLinePosition); // Padding at the start
              } else if (index ==
                  (timeInfoList.fold(0.0, (sum, timeInfo) => sum + timeInfo['totalWidth']) / frameWidth).ceil() + 1) {
                return SizedBox(width: redLinePosition); // Padding at the end
              }

              // Calculate the time for the current frame based on the width and totalWidth
              double timeForFrame = ((index - 1) * frameWidth) / totalWidthSum * totalDuration;

              return SizedBox(
                width: 100, // Ensure width matches frame width
                child: Text(
                  "${timeForFrame.toStringAsFixed(2)}s\n|",
                  textAlign: TextAlign.start,
                  style: TextStyle(fontSize: 15, color: Colors.grey, height: 1),
                ),
              );
            },
          ),
        ),
        SizedBox(
          height: 100,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Scrollable Frame List
              ListView.builder(
                controller: _scrollController,
                itemCount: timeInfoList.length,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, groupIndex) {
                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => setState(() {
                      if (highlightedIndex == groupIndex) {
                        highlightedIndex = -1;
                        return;
                      }
                      highlightedIndex = groupIndex; // Highlight the group
                    }),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (groupIndex == 0) SizedBox(width: 140), // Left padding
                        Transform.translate(
                          offset: Offset(groupIndex != 0 ? (-groupBinderValue) : 0, 0),
                          child: Trimmer(
                            timeFrameUpdater: timeFrameUpdate,
                            groupIndex: groupIndex,
                            transformedValue: timeInfoList[groupIndex]['transformedValue'] ?? 0,
                            spriteSheetImage: spriteSheetImage!,
                            frameRects: initialFrames,
                            timeInfoList: timeInfoList,
                            isHighlighted: highlightedIndex == groupIndex,
                            totalFrames: timeInfoList[groupIndex]['totalFrames'],
                            startTime: timeInfoList[groupIndex]['startTime'],
                            endTime: timeInfoList[groupIndex]['endTime'],
                            width: timeInfoList[groupIndex]['totalWidth'],
                            totalTimeDuration: timeInfoList[groupIndex]['totalTimeDuration'],
                            initialSpace: 0.0,
                            binderValue: groupBinderValue,
                            binderUpdater: groupBinder,
                          ),
                        ),
                        if (groupIndex == frameGroups.length - 1) SizedBox(width: 180), // Right padding
                      ],
                    ),
                  );
                },
              ),

              // White Tracking Line
              Positioned(
                left: redLinePosition - sliderWidth / 2,
                top: 0,
                bottom: 0,
                child: Container(
                  width: sliderWidth,
                  color: Colors.red, // Changed from red to white
                ),
              ),
              // Positioned(
              //     top: -20,
              //     right: 0,
              //     child: Text(
              //       currentTime.toString().padLeft(2, '0'),
              //       style: TextStyle(color: Colors.white),
              //     )),
              Positioned(
                top: 80,
                right: 60,
                child: Text(
                  "Current - " + formatTime(currentTime),
                  style: TextStyle(color: Colors.white),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}

import 'dart:async';
import 'dart:developer';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gudshow/core/utils/time_formatter.dart';
import 'package:gudshow/trim/widgets/trimmer.dart';
import 'package:video_player/video_player.dart';

typedef MyBuilder = void Function(
    BuildContext context, void Function() splitMethod);

class TrimmerAndSplit extends StatefulWidget {
  const TrimmerAndSplit({
    super.key,
    required this.builder,
    required this.isVideoInitialized,
    required this.timeInfoUpdater,
    required this.groupIndexAndTimeUpdater,
    required this.videoPlayerController,
  });
  final MyBuilder builder;
  final ValueChanged<List<Map<String, dynamic>>> timeInfoUpdater;
  final Function(int groupIndex, double lastPlayedMillSeconds)
      groupIndexAndTimeUpdater;
  final bool isVideoInitialized;
  final VideoPlayerController videoPlayerController;

  @override
  State<TrimmerAndSplit> createState() => _TrimmerAndSplitState();
}

class _TrimmerAndSplitState extends State<TrimmerAndSplit> {
  ui.Image? spriteSheetImage;
  List<List<Rect>> frameGroups = [];
  late List<Rect> initialFrames;
  final int frameWidth = 100;
  final int frameHeight = 60;
  final double totalDuration = 3.0;
  double frameDuration = 0.0;
  late int totalFrames;
  int framesPerSeconds = 2;
  late final ScrollController _scrollController;
  late final ScrollController _timelineScrollController;
  bool _isSyncing = false;

  int clampedIndex = 0;
  late double redLinePosition; // Fixed red line position (pixels)
  final double sliderWidth = 3; // Width of the red line
  int? highlightedIndex;
  double currentTime = 0.0;
  List<Map<String, dynamic>> timeInfoList = [];
  double groupBinderValue = 0;
  double totalFrameWidth = 0;
  int lastMovedGroupIndex = -1;
  double lastLeftMovedOffsetPos = 0;
  bool canUseLeftBinderInfo = false;
  Map<int, double> groupBinderInfo = {};
  void recompute({required int groupIndex, required double movedLeftOffset}) {
    // if (_scrollController.hasClients) {
    //   _scrollController.animateTo(0,
    //       duration: Duration(milliseconds: 500), curve: Curves.easeIn);
    // }
  }

  Future<void> _loadSpriteSheet() async {
    try {
      final spriteSheet = await _loadNetworkImage(
          'https://gudsho-channelstatic.akamaized-staging.net/editor/media_1730714997978/frame_image.jpg');
      setState(() {
        spriteSheetImage = spriteSheet;
        initialFrames = generateFrameRects(
            frameWidth, frameHeight, totalDuration.toInt(), framesPerSeconds);
        totalFrames = initialFrames.length;
        frameDuration = totalDuration / totalFrames;
        frameGroups = [initialFrames];

        timeInfoList.add({
          'index': 'init',
          'startTime': 0.0,
          'endTime': 0.0 + initialFrames.length * frameDuration,
          'totalWidth': initialFrames.length * frameWidth.toDouble(),
          'totalTimeDuration': totalDuration,
          'totalFrames': initialFrames.length,
          'initialSpace': 0.0,
          'transformedValue': 0.0
        });
        totalFrameWidth = calculateWidthFromTime(totalDuration);
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
      final codec =
          await ui.instantiateImageCodec(httpResponse.buffer.asUint8List());
      final frameInfo = await codec.getNextFrame();
      return frameInfo.image;
    } catch (e) {
      throw Exception("Failed to load image from network: $e");
    }
  }

  List<Rect> generateFrameRects(
      int frameWidth, int frameHeight, int totalSeconds, int fps) {
    const int framesPerRow = 20; // Given constraint
    final int totalFrames = totalSeconds * fps;
    final int totalRows = (totalFrames / framesPerRow).ceil();

    final List<Rect> rects = [];

    for (int row = 0; row < totalRows; row++) {
      for (int col = 0; col < framesPerRow; col++) {
        if (rects.length >= totalFrames)
          break; // Stop if we reached required frames
        rects.add(Rect.fromLTWH(
          col * frameWidth.toDouble(),
          row * frameHeight.toDouble(),
          frameWidth.toDouble(),
          frameHeight.toDouble(),
        ));
      }
    }

    return rects;
  }

  double calculateWidthFromTime(double time) {
    //!hardcoded
    double frameDuration = 0.50;
    double width = (time / frameDuration) * frameWidth;
    return width;
  }

  void _onScroll() {
    final maxScrollOffset = totalDuration /
        frameDuration *
        frameWidth; // Max scroll based on duration
    final scrollOffset = _scrollController.offset.clamp(0.0, maxScrollOffset);

    if (_scrollController.offset != scrollOffset) {
      _scrollController.jumpTo(scrollOffset); // Prevent overscrolling
    }

    final adjustedScrollOffset = scrollOffset - redLinePosition;
    final double redLineExactFrameIndex =
        (adjustedScrollOffset + redLinePosition) / frameWidth;

    clampedIndex = redLineExactFrameIndex.floor().clamp(0, totalFrames - 1);
    currentTime = redLineExactFrameIndex * frameDuration;

    // Track the group number
    int currentGroupIndex = 0;

    for (int i = 0; i < timeInfoList.length; i++) {
      final timeInfo = timeInfoList[i];
      double groupStartTime = timeInfo['startTime'];
      double groupEndTime = timeInfo['endTime'];

      if (currentTime >= groupStartTime && currentTime <= groupEndTime) {
        currentGroupIndex = i;
        break; // Stop checking once we find the correct group
      }
    }

    log("Current Time: $currentTime, Group Index: $currentGroupIndex");
    widget.groupIndexAndTimeUpdater(currentGroupIndex, currentTime);

    setState(() {
      // highlightedIndex = currentGroupIndex; // Update UI if needed
    });
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
        int splitIndex =
            ((currentTime - groupStartTime) / frameDuration).floor();

        if (splitIndex < 0) splitIndex = 0;
        if (splitIndex >= group.length) splitIndex = group.length - 1;

        List<Rect> firstPart = group.sublist(0, splitIndex + 1);
        List<Rect> secondPart = group.sublist(splitIndex + 1);

        newFrameGroups.add(firstPart);
        newFrameGroups.add(secondPart);

        if (timeInfoList[i]['index'] == 'init') {
          timeInfoList.removeAt(i);
        }

        double firstPartStart = groupStartTime;
        double firstPartEnd = double.parse(currentTime.toStringAsFixed(2));
        double secondPartStart = firstPartEnd;
        double secondPartEnd = double.parse(groupEndTime.toStringAsFixed(2));

        double firstPartWidth =
            ((firstPartEnd - firstPartStart) / frameDuration) * frameWidth;
        double secondPartWidth =
            ((secondPartEnd - secondPartStart) / frameDuration) * frameWidth;

        newTimeInfoList.add({
          'index': '${i}_first',
          'startTime': firstPartStart,
          'endTime': firstPartEnd,
          'totalWidth': firstPartWidth,
          'totalTimeDuration': totalDuration,
          'totalFrames': firstPart.length,
          'initialSpace': calculateWidthFromTime(firstPartStart),
          'transformedValue': firstPartStart
        });

        newTimeInfoList.add({
          'index': '${i}_second',
          'startTime': secondPartStart,
          'endTime': secondPartEnd,
          'totalWidth': secondPartWidth,
          'totalTimeDuration': totalDuration,
          'totalFrames': secondPart.length,
          'initialSpace': calculateWidthFromTime(secondPartStart),
          'transformedValue': secondPartStart
        });

        highlightedIndex = i + 1;
        print("Split at time: $currentTime");
        print(
            "First part: Start $firstPartStart, End $firstPartEnd, Width $firstPartWidth");
        print(
            "Second part: Start $secondPartStart, End $secondPartEnd, Width $secondPartWidth");
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
  }

  void timeFrameUpdate(Map<String, dynamic> info, int index) {
    timeInfoList[index] = info;
    log(timeInfoList.toString());
  }

  void groupBinder(double value, int lastGroupIndex,
      double lastMovedLeftOffsetPos, bool canUseBinderVal) {
    setState(() {
      lastGroupIndex = lastGroupIndex;
      lastLeftMovedOffsetPos = lastMovedLeftOffsetPos;
      canUseLeftBinderInfo = canUseBinderVal;
      groupBinderValue = value;
      groupBinderInfo[lastGroupIndex] = lastMovedLeftOffsetPos;
      log("binder ----$groupBinderValue");
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
    //! FIXME VIDEO
    // widget.videoPlayerController.addListener(_scrollListView);
  }

  void _scrollListView() {
    // Get the video playback position in seconds
    double position =
        widget.videoPlayerController.value.position.inSeconds.toDouble();

    // Calculate the total number of frames at the given time (position)
    double totalFrames = position * framesPerSeconds;

    // Calculate the scroll offset: each frame is 100px
    double scrollOffset = totalFrames * 100; // 100px per frame

    // Scroll the ListView to the calculated offset
    if (_scrollController.hasClients &&
        scrollOffset < _scrollController.position.maxScrollExtent) {
      _scrollController.jumpTo(scrollOffset);
    } else {
      // Ensure it doesn't exceed the max scroll extent
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _timelineScrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    redLinePosition = MediaQuery.sizeOf(context).width / 2;

    if (spriteSheetImage == null || !widget.isVideoInitialized) {
      return Center(child: CircularProgressIndicator());
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 30,
          child: ListView.builder(
            controller: _timelineScrollController,
            scrollDirection: Axis.horizontal,
            itemCount:
                ((totalFrameWidth / frameWidth).ceil()) + 2, // +2 for padding
            itemBuilder: (context, index) {
              // Calculate time per frame
              double timeForFrame =
                  ((index - 1) * frameWidth) / totalFrameWidth * totalDuration;

              // Padding at the start
              if (index == 0) return SizedBox(width: redLinePosition);

              return SizedBox(
                width: (index == (totalFrameWidth / frameWidth).ceil() + 1)
                    ? redLinePosition // Padding at the end
                    : 100, // Fixed width for time labels
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
                  double rightPadding = MediaQuery.of(context).size.width / 2 -
                      (totalFrameWidth % 100);

                  rightPadding = rightPadding < 0 ? 0 : rightPadding;
                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => setState(
                      () {
                        canUseLeftBinderInfo = true;
                        if (highlightedIndex == groupIndex) {
                          highlightedIndex = -1;
                          return;
                        }
                        highlightedIndex = groupIndex; // Highlight the group
                      },
                    ),
                    child: Row(
                      children: [
                        if (groupIndex == 0)
                          SizedBox(width: MediaQuery.sizeOf(context).width / 2),
                        Transform.translate(
                          offset: Offset(
                            canUseLeftBinderInfo
                                ? groupBinderInfo[groupIndex] != null
                                    ? -groupBinderInfo[groupIndex]!
                                    : 0
                                : groupIndex < (highlightedIndex ?? 0)
                                    ? groupBinderInfo[groupIndex]??-lastLeftMovedOffsetPos
                                    : -lastLeftMovedOffsetPos,
                            0,
                          ),
                          child: Trimmer(
                            recompute: recompute,
                            totalFrameWidth: totalFrameWidth,
                            timeFrameUpdater: timeFrameUpdate,
                            groupIndex: groupIndex,
                            transformedValue: timeInfoList[groupIndex]
                                    ['transformedValue'] ??
                                0,
                            spriteSheetImage: spriteSheetImage!,
                            frameRects: initialFrames,
                            timeInfoList: timeInfoList,
                            isHighlighted: highlightedIndex == groupIndex,
                            totalFrames: timeInfoList[groupIndex]
                                ['totalFrames'],
                            startTime: timeInfoList[groupIndex]['startTime'],
                            endTime: timeInfoList[groupIndex]['endTime'],
                            width: timeInfoList[groupIndex]['totalWidth'],
                            totalTimeDuration: timeInfoList[groupIndex]
                                ['totalTimeDuration'],
                            initialSpace: timeInfoList[groupIndex]
                                ['initialSpace'],
                            binderValue: groupBinderValue,
                            binderUpdater: groupBinder,
                          ),
                        ),
                        if (groupIndex == frameGroups.length - 1)
                          SizedBox(width: rightPadding),
                      ],
                    ),
                  );
                },
              ),

              // White Tracking Line
              Positioned(
                left: (redLinePosition),
                top: 0,
                bottom: 0,
                child: Container(
                  width: sliderWidth,
                  color: Colors.red, // Changed from red to white
                ),
              ),

              Positioned(
                top: 70,
                right: 60,
                child: IgnorePointer(
                  ignoring: true,
                  child: Text(
                    "Current - " + formatTime(currentTime),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}

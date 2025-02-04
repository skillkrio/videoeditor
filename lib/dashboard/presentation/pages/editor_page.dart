import 'package:flutter/material.dart';
import 'package:gudshow/core/painters/video_crop_custom_clipper.dart';
import 'package:gudshow/crop/crop_screen.dart';
import 'package:gudshow/split/trimmer_with_split.dart';
import 'package:video_player/video_player.dart';

class ContusPlayerScreen extends StatefulWidget {
  const ContusPlayerScreen({super.key});

  @override
  State<ContusPlayerScreen> createState() => _ContusPlayerScreenState();
}

class _ContusPlayerScreenState extends State<ContusPlayerScreen> {
  late VideoPlayerController _videoController;
  bool _isInitialized = false;
  Rect? _rect;
  late VoidCallback triggerSplit;
  final videoUrl = "https://gudsho-channelstatic.akamaized-staging.net/editor/video_001/Video_Campus_Time.mp4";
  double? sourceVideoHeight;
  double? sourceVideoWidth;
  double? deviceVideoWidth;
  double? deviceVideoHeight;
  int currentSegmentIndex = 0;
  List<Map<String, dynamic>> timeInfo = [];
  bool isPlayingSegments = false;
  double aspectRatio = 16 / 9;
  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    // Replace this URL with your video URL
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(videoUrl),
    );

    try {
      await _videoController.initialize();
      sourceVideoHeight = _videoController.value.size.height;
      sourceVideoWidth = _videoController.value.size.width;
      // await _videoController.setLooping(true);
      setState(() {
        _isInitialized = true;
        playNextSegment();
      });
    } catch (e) {
      debugPrint('Error initializing video: $e');
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  void timeInfoUpdater(List<Map<String, dynamic>> info) {
    timeInfo = info;
  }

  void playpause() {
    setState(() {
      if (_videoController.value.isPlaying) {
        _videoController.pause();
      } else {
        _videoController.play();
      }
    });
  }

  void playNextSegment() async {
    if (!isPlayingSegments || currentSegmentIndex >= timeInfo.length) {
      return;
    }

    Map<String, dynamic> segment = timeInfo[currentSegmentIndex];
    double startTime = segment['startTime'];
    double endTime = segment['endTime'];

    // Seek to start time
    await _videoController.seekTo(Duration(milliseconds: (startTime * 1000).toInt()));
    _videoController.play();

    // Wait until endTime is reached
    Future.delayed(Duration(milliseconds: ((endTime - startTime) * 1000).toInt()), () {
      _videoController.pause();
      currentSegmentIndex++;

      if (currentSegmentIndex < timeInfo.length) {
        startPlayingSegments();
      } else {
        currentSegmentIndex = 0; // Reset for looping
        startPlayingSegments();
      }
    });
  }

  void startPlayingSegments() {
    if (!isPlayingSegments) {
      isPlayingSegments = true;
      currentSegmentIndex = 0;
      playNextSegment();
    }
  }

  void ratio(double ratio) {
    setState(() {
      aspectRatio = ratio;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            FloatingActionButton(
                heroTag: '16/9',
                mini: true,
                onPressed: () {
                  ratio(16 / 9);
                },
                child: Text('16/9')),
            FloatingActionButton(
                heroTag: '9/16',
                mini: true,
                onPressed: () {
                  ratio(9 / 16);
                },
                child: Text('9/16')),
            FloatingActionButton(
                heroTag: '1',
                mini: true,
                onPressed: () {
                  ratio(1);
                },
                child: Text('1:1')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xFF2E7D32),
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              Expanded(
                child: Center(
                  child: (_isInitialized && _rect == null)
                      ? AspectRatio(
                          aspectRatio: aspectRatio,
                          child: Container(
                            color: Colors.black,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                AspectRatio(
                                  aspectRatio: _videoController.value.aspectRatio,
                                  child: VideoPlayer(_videoController),
                                ),
                                // Custom play/pause overlay
                                _buildPlayPauseOverlay(),
                              ],
                            ),
                          ),
                        )
                      : (!_isInitialized)
                          ? const CircularProgressIndicator(color: Colors.white)
                          : AspectRatio(
                              aspectRatio: aspectRatio,
                              child: Container(
                                color: Colors.black,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.contain,
                                      child: Transform.translate(
                                        offset: Offset(
                                          -_rect!.left,
                                          -_rect!.top,
                                        ),
                                        child: ClipRect(
                                          clipper: VideoCropper(_rect!),
                                          child: Container(
                                            color: Colors.blue,
                                            height: deviceVideoHeight,
                                            width: deviceVideoWidth,
                                            child: VideoPlayer(_videoController),
                                          ),
                                        ),
                                      ),
                                    ),
                                    CircleAvatar(
                                      child: IconButton(
                                        onPressed: playpause,
                                        icon: _videoController.value.isPlaying
                                            ? Icon(Icons.pause)
                                            : Icon(Icons.play_arrow),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Video Progress Bar
                    VideoProgressIndicator(
                      _videoController,
                      allowScrubbing: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      colors: const VideoProgressColors(
                        playedColor: Colors.white,
                        bufferedColor: Colors.white24,
                        backgroundColor: Colors.grey,
                      ),
                    ),

                    // Time indicators
                    _buildTimeRow(),

                    // Media Controls
                    _buildMediaControls(),

                    // Bottom Action Buttons
                    _buildActionButtons(),

                    // Timeline
                    _buildTimeline(timeInfoUpdater),
                    // TrimmerAndSplit()
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlayPauseOverlay() {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_videoController.value.isPlaying) {
            _videoController.pause();
          } else {
            _videoController.play();
          }
        });
      },
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: AnimatedOpacity(
            opacity: _videoController.value.isPlaying ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  _videoController.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRow() {
    return ValueListenableBuilder(
      valueListenable: _videoController,
      builder: (context, VideoPlayerValue value, child) {
        final duration = value.duration;
        final position = value.position;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(position),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                '-${_formatDuration(duration - position)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildMediaControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: const Icon(Icons.skip_previous, color: Colors.white),
          iconSize: 32,
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(
            _videoController.value.isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
          ),
          iconSize: 48,
          onPressed: () {
            playpause();
          },
        ),
        IconButton(
          icon: const Icon(Icons.skip_next, color: Colors.white),
          iconSize: 32,
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.volume_up, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildActionButton(
            Icons.crop,
            'Crop',
            onPressed: () async {
              final result = await Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => CropScreen(videoUrl: videoUrl),
              ));
              if (result != null) {
                Rect cropRect = result['rect'];
                double deviceHeight = result['deviceHeight'];
                double deviceWidth = result['deviceWidth'];

                // Convert cropRect from device resolution to actual video resolution
                Rect convertedRect = Rect.fromLTWH(
                  cropRect.left * (sourceVideoWidth! / deviceWidth),
                  cropRect.top * (sourceVideoHeight! / deviceHeight),
                  cropRect.width * (sourceVideoWidth! / deviceWidth),
                  cropRect.height * (sourceVideoHeight! / deviceHeight),
                );

                setState(() {
                  _rect = convertedRect;
                  deviceVideoHeight = sourceVideoHeight;
                  deviceVideoWidth = sourceVideoWidth;
                });
              }
            },
          ),
          _buildActionButton(
            Icons.call_split,
            'Split',
            onPressed: () {
              triggerSplit();
            },
          ),
          // _buildActionButton(Icons.delete_outline, 'Delete'),
          // _buildActionButton(Icons.refresh, 'Reload'),
          // _buildActionButton(Icons.undo, 'Undo'),
          // _buildActionButton(Icons.redo, 'Redo'),
          // _buildActionButton(Icons.open_in_full, 'Scale'),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, {void Function()? onPressed}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.white),
          onPressed: onPressed,
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildTimeline(Function(List<Map<String, dynamic>>) timeInfoUpdater) {
    return Container(
      height: 130,
      margin: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          FloatingActionButton(
            heroTag: 'timelineBtn',
            mini: true,
            backgroundColor: Colors.white,
            child: const Icon(Icons.add, color: Colors.black),
            onPressed: () {},
          ),
          Expanded(
            child: TrimmerAndSplit(
              isVideoInitialized: _isInitialized,
              builder: (context, splitMethod) {
                triggerSplit = splitMethod;
              },
              timeInfoUpdater: (List<Map<String, dynamic>> timeInfos) {
                timeInfoUpdater(timeInfos);
              },
            ),
          ),
        ],
      ),
    );
  }
}

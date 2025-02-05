import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MediaControls extends StatefulWidget {
  const MediaControls(
      {super.key,
      required this.videoController,
      required this.currentSegmentIndex,
      required this.playSegment});
  final VideoPlayerController videoController;
  final Function(int index, {bool ignoreLastPlayedInMilliSeconds}) playSegment;
  final int currentSegmentIndex;

  @override
  State<MediaControls> createState() => _MediaControlsState();
}

class _MediaControlsState extends State<MediaControls> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: const Icon(Icons.skip_previous, color: Colors.white),
          iconSize: 32,
          onPressed: () {
            Duration currentPosition = widget.videoController.value.position;
            Duration newPosition = currentPosition - Duration(seconds: 2);
            if (newPosition < Duration.zero)
              newPosition = Duration.zero; // Prevent seeking before the start
            widget.videoController.seekTo(newPosition);
          },
        ),
        IconButton(
          icon: Icon(
            widget.videoController.value.isPlaying
                ? Icons.pause
                : Icons.play_arrow,
            color: Colors.white,
          ),
          iconSize: 48,
          onPressed: () {
            setState(() {
              if (widget.videoController.value.isPlaying) {
                widget.videoController.pause();
              } else {
                widget.playSegment(
                  widget.currentSegmentIndex,
                );
              }
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.skip_next, color: Colors.white),
          iconSize: 32,
          onPressed: () {
            Duration currentPosition = widget.videoController.value.position;
            Duration newPosition = currentPosition + Duration(seconds: 2);
            if (newPosition > widget.videoController.value.duration) {
              newPosition = widget.videoController.value
                  .duration; // Prevent seeking beyond the video duration
            }
            widget.videoController.seekTo(newPosition);
          },
        ),
        // IconButton(
        //   icon: const Icon(Icons.volume_up, color: Colors.white),
        //   onPressed: () {},
        // ),
      ],
    );
  }
}

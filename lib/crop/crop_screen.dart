import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../core/painters/crop_grid_painter.dart';

class CropScreen extends StatefulWidget {
  final String videoUrl;
  final VideoPlayerController controller;
  final int playedDurationInMilliSec;
  const CropScreen(
      {super.key,
      required this.videoUrl,
      required this.playedDurationInMilliSec,
      required this.controller});

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  // late VideoPlayerController controller;
  bool isLoading = true;
  final stateKey = GlobalKey();
  double? deviceVideoHeight = 0;
  double? deviceVideoWidth = 0;
  Rect cropRect = Rect.zero;
  double aspectRatio2 = 1 / 1;
  bool isResizing = false;
  bool isDragging = false;
  Offset? dragStartPoint;
  Rect? initialRect;
  String? activeHandle;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        deviceVideoHeight = stateKey.currentContext?.size?.height;
        deviceVideoWidth = stateKey.currentContext?.size?.width;
        cropRect = Rect.fromLTWH(0, 0, deviceVideoWidth!, deviceVideoHeight!);
      });
    });
  }

  void _startDrag(Offset position) {
    setState(() {
      log('calling the startdrag function');

      isDragging = true;
      dragStartPoint = position;
      initialRect = cropRect;
    });
  }

  void _changeAspectRatio(double newRatio) {
    if (!widget.controller.value.isInitialized) return;
    setState(() {
      aspectRatio2 = newRatio;

      // Get video dimensions
      final videoWidth = deviceVideoWidth;
      final videoHeight = deviceVideoHeight;

      // Calculate maximum possible crop width and height that fits the video
      double maxCropWidth = videoWidth!;
      double maxCropHeight = videoHeight!;

      // Calculate crop dimensions maintaining the aspect ratio
      double cropWidth;
      double cropHeight;

      if (newRatio > 1) {
        // For landscape ratios (e.g., 16:9)
        cropHeight = maxCropHeight;
        cropWidth = cropHeight * newRatio;

        // If calculated width exceeds video width, scale down
        if (cropWidth > maxCropWidth) {
          cropWidth = maxCropWidth;
          cropHeight = cropWidth / newRatio;
        }
      } else {
        // For portrait ratios (e.g., 9:16)
        cropWidth = maxCropWidth;
        cropHeight = cropWidth / newRatio;

        // If calculated height exceeds video height, scale down
        if (cropHeight > maxCropHeight) {
          cropHeight = maxCropHeight;
          cropWidth = cropHeight * newRatio;
        }
      }

      // Create the crop rectangle centered in the video frame
      cropRect = Rect.fromCenter(
        center: Offset(videoWidth / 2, videoHeight / 2),
        width: cropWidth,
        height: cropHeight,
      );
    });
  }

  void _updateDrag(Offset newPosition) {
    // Calculate the delta of the drag movement
    double dx = newPosition.dx - dragStartPoint!.dx;
    double dy = newPosition.dy - dragStartPoint!.dy;

    // Update the position of the crop rectangle
    double newLeft = initialRect!.left + dx;
    double newTop = initialRect!.top + dy;
    double newRight = initialRect!.right + dx;
    double newBottom = initialRect!.bottom + dy;

    // Clamp the position of the crop rectangle within the video boundaries
    double minLeft = 0.0;
    double minTop = 0.0;
    double maxRight = deviceVideoWidth! -
        cropRect.width; // Assuming videoWidth is the video width
    double maxBottom = deviceVideoHeight! -
        cropRect.height; // Assuming videoHeight is the video height

    newLeft = newLeft.clamp(minLeft, maxRight);
    newTop = newTop.clamp(minTop, maxBottom);
    newRight =
        newRight.clamp(minLeft + cropRect.width, maxRight + cropRect.width);
    newBottom =
        newBottom.clamp(minTop + cropRect.height, maxBottom + cropRect.height);

    // Update the crop rectangle position
    setState(() {
      cropRect = Rect.fromLTRB(newLeft, newTop, newRight, newBottom);
    });
  }

  void _endDrag() {
    setState(() {
      log('calling the endDrag function');

      isDragging = false;
      dragStartPoint = null;
      initialRect = null;
    });
  }

  void _startResize(Offset position, String handle) {
    setState(() {
      log('calling the startresize function');

      isResizing = true;
      dragStartPoint = position;
      initialRect = cropRect;
      activeHandle = handle;
    });
  }

  void _updateResize(Offset position) {
    if (!isResizing || dragStartPoint == null || initialRect == null) return;

    double dx = position.dx - dragStartPoint!.dx;
    double dy = position.dy - dragStartPoint!.dy;

    setState(() {
      switch (activeHandle) {
        case 'topLeft':
          cropRect = Rect.fromLTRB(
            (initialRect!.left + dx).clamp(0, initialRect!.right - 50),
            (initialRect!.top + dy).clamp(0, initialRect!.bottom - 50),
            initialRect!.right,
            initialRect!.bottom,
          );
          break;
        case 'topCenter':
          cropRect = Rect.fromLTRB(
            initialRect!.left,
            (initialRect!.top + dy).clamp(0, initialRect!.bottom - 50),
            initialRect!.right,
            initialRect!.bottom,
          );
          break;
        case 'topRight':
          cropRect = Rect.fromLTRB(
            initialRect!.left,
            (initialRect!.top + dy).clamp(0, initialRect!.bottom - 50),
            (initialRect!.right + dx)
                .clamp(initialRect!.left + 50, deviceVideoWidth!),
            initialRect!.bottom,
          );
          break;
        case 'rightCenter':
          cropRect = Rect.fromLTRB(
            initialRect!.left,
            initialRect!.top,
            (initialRect!.right + dx)
                .clamp(initialRect!.left + 50, deviceVideoWidth!),
            initialRect!.bottom,
          );
          break;
        case 'bottomRight':
          cropRect = Rect.fromLTRB(
            initialRect!.left,
            initialRect!.top,
            (initialRect!.right + dx)
                .clamp(initialRect!.left + 50, deviceVideoWidth!),
            (initialRect!.bottom + dy)
                .clamp(initialRect!.top + 50, deviceVideoHeight!),
          );
          break;
        case 'bottomCenter':
          cropRect = Rect.fromLTRB(
            initialRect!.left,
            initialRect!.top,
            initialRect!.right,
            (initialRect!.bottom + dy)
                .clamp(initialRect!.top + 50, deviceVideoHeight!),
          );
          break;
        case 'bottomLeft':
          cropRect = Rect.fromLTRB(
            (initialRect!.left + dx).clamp(0, initialRect!.right - 50),
            initialRect!.top,
            initialRect!.right,
            (initialRect!.bottom + dy)
                .clamp(initialRect!.top + 50, deviceVideoHeight!),
          );
          break;
        case 'leftCenter':
          cropRect = Rect.fromLTRB(
            (initialRect!.left + dx).clamp(0, initialRect!.right - 50),
            initialRect!.top,
            initialRect!.right,
            initialRect!.bottom,
          );
          break;
      }

      // Ensure the crop rect stays within the boundaries
      cropRect = Rect.fromLTRB(
          cropRect.left,
          cropRect.top,
          cropRect.right.clamp(cropRect.left + 50, deviceVideoWidth!),
          cropRect.bottom.clamp(cropRect.top + 50, deviceVideoHeight!));
    });
  }

  void _endResize() {
    setState(() {
      log('calling the endResize function');

      isResizing = false;
      dragStartPoint = null;
      initialRect = null;
      activeHandle = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[400],
        title: Text('Crop Video'),
        centerTitle: true,
        leading: InkWell(
          child: Icon(Icons.arrow_back),
          onTap: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        color: Colors.black,
        child: Column(
          children: [
            Container(
              alignment: Alignment.center,
              height: 500,
              child: Stack(
                children: [
                  AspectRatio(
                      key: stateKey,
                      aspectRatio: widget.controller.value.aspectRatio,
                      child: VideoPlayer(widget.controller)),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: CropOverlayPainter(
                        cropRect: cropRect,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: GestureDetector(
                      //Prevent croprect within its boundary and prevent overflow outside boundary

                      onPanStart: (details) {
                        if (isResizing) return;
                        _startDrag(details.localPosition);
                      },
                      onPanUpdate: (details) {
                        log("middle container");
                        if (isResizing) {
                          _updateResize(details.localPosition);
                        } else if (isDragging) {
                          _updateDrag(details.localPosition);
                        }
                      },
                      onPanEnd: (details) {
                        if (isResizing) {
                          _endResize();
                        } else if (isDragging) {
                          _endDrag();
                        }
                      },
                      child: Stack(
                        children: [
                          // Grid Overlay

                          CustomPaint(
                            painter: CropGridPainter(cropRect),
                          ),

                          // Draggable Crop Box
                          Positioned.fromRect(
                            rect: cropRect,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white,
                                ),
                              ),
                              child: Stack(
                                // alignment: Alignment.center,
                                children: [
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    child: _buildHandle('topLeft', cropRect),
                                  ),
                                  Positioned(
                                    left: (cropRect.width -
                                            (cropRect.width / 3)) /
                                        2,
                                    child: _buildHandle('topCenter', cropRect),
                                  ),
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: _buildHandle('topRight', cropRect),
                                  ),
                                  // Right edge dots
                                  Positioned(
                                    right: 0,
                                    top: (cropRect.height -
                                            (cropRect.height / 3)) /
                                        2,
                                    child:
                                        _buildHandle('rightCenter', cropRect),
                                  ),
                                  // Left edge dots
                                  Positioned(
                                    left: 0,
                                    top: (cropRect.height -
                                            (cropRect.height / 3)) /
                                        2,
                                    child: _buildHandle('leftCenter', cropRect),
                                  ),
                                  // Bottom edge dots
                                  Positioned(
                                    left: 0,
                                    bottom: 0,
                                    child: _buildHandle('bottomLeft', cropRect),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    // top: deviceVideoHeight! -
                                    //     (deviceVideoHeight! / 3),
                                    left: (cropRect.width -
                                            (cropRect.width / 3)) /
                                        2,
                                    child:
                                        _buildHandle('bottomCenter', cropRect),
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child:
                                        _buildHandle('bottomRight', cropRect),
                                  ),
                                  Positioned(
                                    top: -8, // Adjust positioning as needed
                                    left: -8, // Adjust positioning as needed
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white, // Circle color
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: -8, // Adjust positioning as needed
                                    right: -8, // Adjust positioning as needed
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white, // Circle color
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: -8, // Adjust positioning as needed
                                    left: -8, // Adjust positioning as needed
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white, // Circle color
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: -8, // Adjust positioning as needed
                                    right: -8, // Adjust positioning as needed
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _changeAspectRatio(16 / 9);
                    log('print the stateey of height ${stateKey.currentContext?.size?.height}');
                  },
                  child: Text('16:9'),
                ),
                ElevatedButton(
                  onPressed: () => _changeAspectRatio(9 / 16),
                  child: Text('9:16'),
                ),
                ElevatedButton(
                  onPressed: () => _changeAspectRatio(1 / 1),
                  child: Text('1:1'),
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                debugPrint('Crop box saved in aspectRatio: $aspectRatio2');
                debugPrint("Crop box saved in cropRect: $cropRect");
                Navigator.pop(context, {
                  "rect": cropRect,
                  "deviceHeight": deviceVideoHeight,
                  "deviceWidth": deviceVideoWidth
                });
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle(String handle, Rect rect) {
    log('buildhandle calling here ');
    return GestureDetector(
      onPanStart: (details) {
        _startResize(details.localPosition, handle);
      },
      onPanUpdate: (details) {
        log(details.delta.dx.toString());
        _updateResize(details.localPosition);
      },
      onPanEnd: (details) {
        _endResize();
      },
      child: Container(
        width: rect.width / 3,
        height: rect.height / 3,
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
        ),
      ),
    );
  }
}

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:gudshow/core/painters/crop_grid_painter.dart';
import 'package:video_player/video_player.dart';

class CropScreen extends StatefulWidget {
  final String videoUrl;
  const CropScreen({super.key, required this.videoUrl});

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  late VideoPlayerController controller;
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

    controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {
          isLoading = false;
        });
        Future.delayed(
          Duration(milliseconds: 100),
          () {
            setState(() {
              deviceVideoHeight = stateKey.currentContext?.size?.height;
              deviceVideoWidth = stateKey.currentContext?.size?.width;
              log('print the device height and width : $deviceVideoHeight,$deviceVideoWidth');
              log('Print the video original video height and width : ${controller.value.size.height},${controller.value.size.width}');
              cropRect =
                  Rect.fromLTWH(0, 0, deviceVideoWidth!, deviceVideoHeight!);
            });
            // log('print the aspectratio of height $heightVideo');
            // log('print the aspectratio of width $widthVideo');

            log('print the cropRect value $cropRect');

            log('print the stateey of height ${stateKey.currentContext?.size?.height}');
          },
        );
      }).catchError((error) {
        debugPrint('Failed to initialize video: $error');
        setState(() {
          isLoading = false;
        });
      });

    // double videoWidth = controller.value.size.width;
    // double videoHeight = controller.value.size.height;
    // cropRect = Rect.fromLTWH(0, 0, videoWidth, videoHeight);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _startDrag(Offset position) {
    setState(() {
      log('calling the startdrag function');

      isDragging = true;
      dragStartPoint = position;
      initialRect = cropRect;
    });
  }

  // void _changeAspectRatio(double newRatio) {
  //   setState(() {
  //     aspectRatio2 = newRatio;
  //     double newHeight = cropRect.width / newRatio;
  //     final double videoHeight = controller.value.size.height;
  //     newHeight = newHeight.clamp(0.0, videoHeight);
  //     cropRect = Rect.fromCenter(
  //       center: cropRect.center,
  //       width: cropRect.width,
  //       height: newHeight,
  //     );
  //   });
  // }
  void _changeAspectRatio(double newRatio) {
    if (!controller.value.isInitialized) return;

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

  void _updateDrag(Offset position) {
    log('calling the updateDrag function');

    if (!isDragging || dragStartPoint == null || initialRect == null) return;

    final double dx = position.dx - dragStartPoint!.dx;
    final double dy = position.dy - dragStartPoint!.dy;

    setState(() {
      cropRect = Rect.fromLTRB(
        initialRect!.left + dx,
        initialRect!.top + dy,
        initialRect!.right + dx,
        initialRect!.bottom + dy,
      );

      // Clamp the crop rectangle within the video bounds
      final double videoWidth = controller.value.size.width;
      final double videoHeight = controller.value.size.height;

      cropRect = Rect.fromLTRB(
        cropRect.left.clamp(0.0, videoWidth - cropRect.width),
        cropRect.top.clamp(0.0, videoHeight - cropRect.height),
        cropRect.right.clamp(cropRect.width, videoWidth),
        cropRect.bottom.clamp(cropRect.height, videoHeight),
      );
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
    log('calling the updateResize function');

    if (!isResizing || dragStartPoint == null || initialRect == null) return;

    final double dx = position.dx - dragStartPoint!.dx;
    final double dy = position.dy - dragStartPoint!.dy;

    setState(() {
      // newRight = cropRect.right;
      // newBottom = cropRect.bottom;

      switch (activeHandle) {
        case 'topLeft':
          cropRect = Rect.fromLTRB(
            initialRect!.left + dx,
            initialRect!.top + dy,
            initialRect!.right,
            initialRect!.bottom,
          );
          break;
        case 'topCenter':
          cropRect = Rect.fromLTRB(
            initialRect!.left,
            initialRect!.top + dy,
            initialRect!.right,
            initialRect!.bottom,
          );
          break;
        case 'topRight':
          cropRect = Rect.fromLTRB(
            initialRect!.left,
            initialRect!.top + dy,
            initialRect!.right + dx,
            initialRect!.bottom,
          );
          break;
        case 'rightCenter':
          cropRect = Rect.fromLTRB(
            initialRect!.left,
            initialRect!.top,
            initialRect!.right + dx,
            initialRect!.bottom,
          );
          break;
        case 'bottomRight':
          cropRect = Rect.fromLTRB(
            initialRect!.left,
            initialRect!.top,
            initialRect!.right + dx,
            initialRect!.bottom + dy,
          );
          break;
        case 'bottomCenter':
          cropRect = Rect.fromLTRB(
            initialRect!.left,
            initialRect!.top,
            initialRect!.right,
            initialRect!.bottom + dy,
          );
          break;
        case 'bottomLeft':
          cropRect = Rect.fromLTRB(
            initialRect!.left + dx,
            initialRect!.top,
            initialRect!.right,
            initialRect!.bottom + dy,
          );
          break;
        case 'leftCenter':
          cropRect = Rect.fromLTRB(
            initialRect!.left + dx,
            initialRect!.top,
            initialRect!.right,
            initialRect!.bottom,
          );
          break;
      }

      // Clamp the crop rectangle within the video bounds
      // final double videoWidth = controller.value.size.width;
      // final double videoHeight = controller.value.size.height;

      // cropRect = Rect.fromLTRB(
      //   cropRect.left.clamp(0.0, videoWidth),
      //   cropRect.top.clamp(0.0, videoHeight),
      //   cropRect.right.clamp(0.0, videoWidth),
      //   cropRect.bottom.clamp(0.0, videoHeight),
      // );
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
              child: isLoading
                  ? CircularProgressIndicator(
                      color: Colors.white,
                    )
                  : Stack(
                      children: [
                        AspectRatio(
                            key: stateKey,
                            aspectRatio: controller.value.aspectRatio,
                            child: VideoPlayer(controller)),
                        Positioned.fill(
                          child: GestureDetector(
                            onPanStart: (details) {
                              if (isResizing) return;
                              _startDrag(details.localPosition);
                            },
                            onPanUpdate: (details) {
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
                                        color: Colors.red,
                                        width: 1,
                                      ),
                                    ),
                                    child: Stack(
                                      // alignment: Alignment.center,
                                      children: [
                                        // Top edge dots
                                        Positioned(
                                          left: 0,
                                          top: -10,
                                          child: _buildHandle('topLeft'),
                                        ),
                                        Positioned(
                                          left: cropRect.width / 2 - 10,
                                          top: -10,
                                          child: _buildHandle('topCenter'),
                                        ),
                                        Positioned(
                                          right: 0,
                                          top: -10,
                                          child: _buildHandle('topRight'),
                                        ),
                                        // Right edge dots
                                        Positioned(
                                          right: -10,
                                          top: cropRect.height / 2 - 10,
                                          child: _buildHandle('rightCenter'),
                                        ),
                                        Positioned(
                                          right: -10,
                                          top: 0,
                                          child: _buildHandle('rightTop'),
                                        ),
                                        Positioned(
                                          right: -10,
                                          bottom: 0,
                                          child: _buildHandle('rightBottom'),
                                        ),
                                        // Bottom edge dots
                                        Positioned(
                                          left: 0,
                                          bottom: -10,
                                          child: _buildHandle('bottomLeft'),
                                        ),
                                        Positioned(
                                          left: cropRect.width / 2 - 10,
                                          bottom: -10,
                                          child: _buildHandle('bottomCenter'),
                                        ),
                                        Positioned(
                                          right: 0,
                                          bottom: -10,
                                          child: _buildHandle('bottomRight'),
                                        ),
                                        // Left edge dots
                                        Positioned(
                                          left: -10,
                                          top: cropRect.height / 2 - 10,
                                          child: _buildHandle('leftCenter'),
                                        ),
                                        Positioned(
                                          left: -10,
                                          top: 0,
                                          child: _buildHandle('leftTop'),
                                        ),
                                        Positioned(
                                          left: -10,
                                          bottom: 0,
                                          child: _buildHandle('leftBottom'),
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

  Widget _buildHandle(String handle) {
    log('buildhandle calling here ');
    return GestureDetector(
      onPanStart: (details) {
        // log('print the buildHandle details $details');
        _startResize(details.localPosition, handle);
      },
      onPanUpdate: (details) {
        _updateResize(details.localPosition);
      },
      onPanEnd: (details) {
        _endResize();
      },
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

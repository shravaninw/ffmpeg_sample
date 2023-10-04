import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class AppVideoPlayer extends StatefulWidget {
  const AppVideoPlayer(
    this.videoUrl, {
    Key? key,
  }) : super(key: key);
  final File videoUrl;

  @override
  _AppVideoPlayerState createState() => _AppVideoPlayerState();
}

class _AppVideoPlayerState extends State<AppVideoPlayer> {
  late VideoPlayerController videoPlayerController;
  Duration videoDuration = Duration();
  Duration currentDuration = Duration();
  bool playing = false;
  bool isHovering = false;

  File get videoUrl => widget.videoUrl;

  @override
  void initState() {
    super.initState();
    videoControllerInitialize();
  }

  Future<void> videoControllerInitialize() async {
    videoPlayerController = VideoPlayerController.file(videoUrl);
    await videoPlayerController.initialize();

    videoPlayerController.play();
    videoDuration = videoPlayerController.value.duration;
    videoPlayerController.addListener(_onVideoValueChange);
    setState(() {});
  }

  void _onVideoValueChange() {
    var value = videoPlayerController.value;
    currentDuration = value.position;
  }

  void play() {
    videoPlayerController.play();
  }

  void pause() {
    videoPlayerController.pause();
  }

  void changeAction() {
    videoPlayerController.value.isPlaying ? pause() : play();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: videoPlayerController.value.aspectRatio,
      child: VideoPlayer(videoPlayerController),
    );
  }

  @override
  void dispose() {
    videoPlayerController.dispose();
    super.dispose();
  }
}

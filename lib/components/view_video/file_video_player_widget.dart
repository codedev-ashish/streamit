import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_flutter/main.dart';
import 'package:streamit_flutter/network/rest_apis.dart';
import 'package:streamit_flutter/utils/common.dart';
import 'package:streamit_flutter/utils/constants.dart';
import 'package:streamit_flutter/utils/resources/colors.dart';
import 'package:streamit_flutter/utils/resources/extentions/string_extentions.dart';

class FileVideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final String videoImage;
  final String videoTitle;
  final bool isFromLocalStorage;
  final String videoId;
  final bool hasResumePauseVideo;
  final String videoDuration;

  final VoidCallback? videoCompletedCallback;

  @override
  _FileVideoPlayerWidgetState createState() => _FileVideoPlayerWidgetState();

  FileVideoPlayerWidget({
    Key? key,
    required this.videoUrl,
    this.videoImage = blankImage,
    this.videoTitle = "",
    this.isFromLocalStorage = false,
    required this.videoId,
    this.hasResumePauseVideo = false,
    required this.videoDuration,
    this.videoCompletedCallback,
  }) : super(key: key);
}

class _FileVideoPlayerWidgetState extends State<FileVideoPlayerWidget> {
  bool isLiveStreamingURL = false;
  int? lastWatchDuration;

  BetterPlayerController? controller;

  @override
  void initState() {
    super.initState();
    isLiveStreamingURL = widget.videoUrl.isLiveURL;
    appStore.setShowPIP(true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeVideoPlayer();
    lastWatchDuration = getLastWatchDuration(postId: widget.videoId);
  }

  Future<void> _initializeVideoPlayer() async {
    controller = BetterPlayerController(
      BetterPlayerConfiguration(
        autoPlay: true,
        autoDetectFullscreenDeviceOrientation: true,
        fit: BoxFit.cover,
        controlsConfiguration: BetterPlayerControlsConfiguration(
          enablePip: appStore.showPIP,
          showControls: true,
          enableMute: true,
          progressBarBackgroundColor: context.iconColor,
          progressBarPlayedColor: colorPrimary,
        ),
        handleLifecycle: true,
        rotation: 3.14 / 2,
      ),
    );
    controller!.setupDataSource(
      BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        widget.videoUrl,
      ),
    );
    if (controller != null && controller!.isVideoInitialized().validate()) {
      if (appStore.isLogging && lastWatchDuration != null && lastWatchDuration! > 0) {
        if (appStore.isPIPOn) {
          controller!.videoPlayerController!.seekTo(Duration(seconds: lastWatchDuration.validate()));
          controller!.play();
        } else {
          resumeVideoDialog();
        }
      }
    }
    setState(() {});
  }

  void storeLastVideoMoment() async {
    final duration = controller!.videoPlayerController!.value.position.inSeconds;
    await saveVideoContinueWatch(postId: widget.videoId.toInt(), watchedTime: duration, watchedTotalTime: controller!.videoPlayerController!.value.duration!.inSeconds).then((value) {
      LiveStream().emit(RefreshHome);
      getContinueWatchList();
    }).catchError((e) {
      toast(language?.somethingWentWrong);
      log("=====>Error ${e.toString()}<=====");
    });
  }

  Future<void> saveWatchTime() async {
    saveVideoContinueWatch(
      postId: widget.videoId.validate().toInt(),
      watchedTotalTime: controller!.videoPlayerController!.value.duration!.inSeconds,
      watchedTime: controller!.videoPlayerController!.value.position.inSeconds,
    ).then((value) {
      LiveStream().emit(RefreshHome);
      getContinueWatchList();
    }).catchError(onError);
  }

  void resumeVideoDialog() {
    showResumeVideoDialog(
      context: context,
      resume: () async {
        controller!.videoPlayerController!.seekTo(Duration(seconds: lastWatchDuration.validate()));
        controller!.play();
        finish(context);
      },
      starOver: () {
        controller!.videoPlayerController!.seekTo(Duration(seconds: 0));
        controller!.play();
        finish(context);
      },
    );
  }

  void seekToRelativePosition(Offset globalPosition, {bool isDoubleTapped = false}) {
    final RenderBox box = context.findRenderObject()! as RenderBox;
    final Offset tapPos = box.globalToLocal(globalPosition);
    final double relative = tapPos.dx / box.size.width;
    final Duration position = controller!.videoPlayerController!.value.duration! * relative;
    final currentPosition = controller!.videoPlayerController!.value.position;
    if (isDoubleTapped) {
      Duration seekPosition;
      if (relative > 0.5) {
        // Seeking forward by 10 seconds
        seekPosition = currentPosition + Duration(seconds: 10);
        if (seekPosition > controller!.videoPlayerController!.value.duration!) {
          seekPosition = controller!.videoPlayerController!.value.duration!;
        }
      } else {
        // Seeking backward by 10 seconds
        seekPosition = currentPosition - Duration(seconds: 10);
        if (seekPosition < Duration.zero) {
          seekPosition = Duration.zero;
        }
      }
      controller!.videoPlayerController!.seekTo(seekPosition);
    } else {
      controller!.videoPlayerController!.seekTo(position);
    }
  }

  @override
  void dispose() {
    saveWatchTime();
    appStore.setShowPIP(false);
    if (appStore.isLogging && !widget.isFromLocalStorage) storeLastVideoMoment();
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!appStore.showPIP) appStore.setShowPIP(true);
    return Stack(
      children: [
        SizedBox(
          width: context.width(),
          child: GestureDetector(
            onHorizontalDragUpdate: (details) {
              if (!controller!.videoPlayerController!.value.initialized) {
                return;
              } else
                seekToRelativePosition(details.globalPosition);
            },
            onTapDown: (TapDownDetails details) {
              if (!controller!.videoPlayerController!.value.initialized) {
                return;
              } else
                seekToRelativePosition(details.globalPosition, isDoubleTapped: true);
            },
            child: controller != null
                ? BetterPlayer(
                    controller: controller!,
                  )
                : SizedBox(),
          ),
        ),
        if (isLiveStreamingURL)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorPrimary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text("Live", style: boldTextStyle(size: 14, color: Colors.white)),
            ),
          ),
        Positioned(
          left: 8,
          top: 8,
          child: BackButton(),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:pod_player/pod_player.dart';
import 'package:streamit_flutter/utils/resources/extentions/string_extentions.dart';

import '../../main.dart';
import '../../utils/app_widgets.dart';
import '../../utils/common.dart';
import '../../utils/resources/colors.dart';
import '../../utils/resources/size.dart';
import '../cached_image_widget.dart';

class PodPlayerWidget extends StatefulWidget {
  final String? url;
  final String? title;
  final String? runTime;
  final String? image;
  final bool isShowTitle;
  final bool isVideoInLoop;
  final bool showVolumnDowner;

  final VoidCallback? onTap;

  const PodPlayerWidget({
    this.url,
    this.title,
    this.runTime,
    this.isShowTitle = false,
    this.image,
    this.isVideoInLoop = false,
    this.showVolumnDowner = false,
    this.onTap,
    super.key,
  });

  @override
  _PodPlayerWidgetState createState() => _PodPlayerWidgetState();
}

class _PodPlayerWidgetState extends State<PodPlayerWidget> {
  PodPlayerController? podPlayerController;

  bool isMute = true;

  @override
  void initState() {
    super.initState();

  }

  Future<void> initVideoPlayer({required String url}) async {
    podPlayerController = PodPlayerController(
      playVideoFrom: url.getPlatformVideo(),
      podPlayerConfig: PodPlayerConfig(
        autoPlay: true,
        wakelockEnabled: true,
        isLooping: true,
        forcedVideoFocus: true,
      ),
    );
    podPlayerController?.initialise();
    await podPlayerController?.mute();

    podPlayerController?.togglePlayPause();
    isMute = (await podPlayerController?.isMute).validate();
    log('isMute---------------------$isMute');
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(covariant PodPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  void seekToRelativePosition(Offset globalPosition, {bool isDoubleTapped = false}) {
    final RenderBox box = context.findRenderObject()! as RenderBox;
    final Offset tapPos = box.globalToLocal(globalPosition);
    final double relative = tapPos.dx / box.size.width;
    final Duration position = podPlayerController!.videoPlayerValue!.duration * relative;
    if (isDoubleTapped) {
      if (relative > 0.5)
        podPlayerController!.videoSeekForward(Duration(seconds: 10));
      else
        podPlayerController!.videoSeekBackward(Duration(seconds: 10));
    } else {
      podPlayerController!.videoSeekTo(position);
    }
    podPlayerController!.togglePlayPause();
    setState(() {});
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    podPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onTap?.call();
      },
      onHorizontalDragUpdate: (details) {
        if (widget.onTap == null) {
          if (!podPlayerController!.videoPlayerValue!.isInitialized) {
            return;
          }
          seekToRelativePosition(details.globalPosition);
        }
      },
      onTapDown: (TapDownDetails details) {
        if (widget.onTap == null) {
          if (!podPlayerController!.videoPlayerValue!.isInitialized) {
            return;
          }
          seekToRelativePosition(details.globalPosition, isDoubleTapped: true);
        }
      },
      child: podPlayerController != null
          ? PodVideoPlayer(
              controller: podPlayerController!,
              frameAspectRatio: 16 / 9,
              videoAspectRatio: 16 / 9,
              podPlayerLabels: PodPlayerLabels(),
              videoThumbnail: DecorationImage(image: NetworkImage(widget.image.validate())),
              onVideoError: () {
                return CachedImageWidget(url: widget.image.validate());
              },
              podProgressBarConfig: PodProgressBarConfig(
                playingBarColor: colorPrimary,
                circleHandlerColor: colorPrimary,
                height: 4,
                curveRadius: 8,
                padding: EdgeInsets.only(left: 8, right: 8, bottom: 8),
              ),
              alwaysShowProgressBar: false,
              videoTitle: itemTitle(context, parseHtmlString(widget.title.validate()), fontSize: ts_small_large, maxLine: 2, textAlign: TextAlign.start),
              onToggleFullScreen: (isFullScreen) async {
                return await appStore.setToFullScreen(isFullScreen);
              },
            )
          : CachedImageWidget(url: widget.image.validate()),
    );
  }
}

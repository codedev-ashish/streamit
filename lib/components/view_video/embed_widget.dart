import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_flutter/components/view_video/file_video_player_widget.dart';
import 'package:streamit_flutter/components/view_video/webview_content_widget.dart';
import 'package:streamit_flutter/main.dart';
import 'package:streamit_flutter/network/rest_apis.dart';
import 'package:streamit_flutter/utils/common.dart';
import 'package:streamit_flutter/utils/constants.dart';
import 'package:streamit_flutter/utils/resources/extentions/string_extentions.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class EmbedWidget extends StatefulWidget {
  final String data;
  final String? title;
  final String? image;
  final String videoId;
  final String videoDuration;
  final VoidCallback? videoCompletedCallback;

  EmbedWidget(
    this.data, {
    this.title,
    this.image,
    required this.videoId,
    required this.videoDuration,
    this.videoCompletedCallback,
  });

  @override
  _EmbedWidgetState createState() => _EmbedWidgetState();
}

class _EmbedWidgetState extends State<EmbedWidget> {
  bool isYoutubeUrl = false;
  YoutubePlayerController? _controller;
  String urlFromIframe = '';
  int? lastWatchDuration;

  @override
  void initState() {
    urlFromIframe = widget.data.validate().urlFromIframe;
    isYoutubeUrl = urlFromIframe.isYoutubeUrl;

    if (isYoutubeUrl) {
      lastWatchDuration = getLastWatchDuration(postId: widget.videoId);

      _controller = YoutubePlayerController(
        initialVideoId: widget.data.validate().urlFromIframe.toYouTubeId(),
        flags: const YoutubePlayerFlags(),
      )..addListener(() {
          if (_controller?.value.playerState == PlayerState.ended) {
            widget.videoCompletedCallback?.call();
          }
        });
    }

    LiveStream().on(PauseVideo, (p0) {
      if (isYoutubeUrl) _controller!.pause();
      setState(() {});
    });

    super.initState();
  }

  Future<void> saveWatchTime() async {
    if (isYoutubeUrl)
      saveVideoContinueWatch(
        postId: widget.videoId.validate().toInt(),
        watchedTotalTime: _controller!.value.metaData.duration.inSeconds,
        watchedTime: _controller!.value.position.inSeconds,
      ).then((value) {
        getContinueWatchList();
        LiveStream().emit(RefreshHome);
      }).catchError(onError);
  }

  void resumeVideoDialog() {
    showResumeVideoDialog(
      context: context,
      resume: () async {
        _controller!.seekTo(Duration(seconds: lastWatchDuration.validate()));
        _controller!.play();
        finish(context);
      },
      starOver: () {
        _controller!.seekTo(Duration(seconds: 0));
        _controller!.play();
        finish(context);
      },
    );
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    saveWatchTime();
    LiveStream().dispose(PauseVideo);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        return isYoutubeUrl
            ? SizedBox(
                width: context.width(),
                height: appStore.hasInFullScreen ? context.height() - context.statusBarHeight : context.height() * 0.3,
                child: Stack(
                  children: [
                    YoutubePlayerBuilder(
                      player: YoutubePlayer(
                        controller: _controller!,
                        onReady: () {
                          if (appStore.isLogging && lastWatchDuration != null && lastWatchDuration! > 0) {
                            resumeVideoDialog();
                          }
                        },
                        onEnded: (data) {
                          //
                        },
                      ),
                      onEnterFullScreen: () {
                        appStore.setToFullScreen(true);
                      },
                      onExitFullScreen: () {
                        appStore.setToFullScreen(false);
                      },
                      builder: (context, player) {
                        return player;
                      },
                    ),
                    IconButton(
                      onPressed: () {
                        if (appStore.hasInFullScreen) {
                          appStore.setToFullScreen(false);
                        } else {
                          appStore.setPIPOn(false);
                          finish(context);
                          finish(context);
                        }
                      },
                      icon: Icon(Icons.arrow_back_rounded),
                    ),
                  ],
                ),
              )
            : widget.data.validate().urlFromIframe.isVideoPlayerFile
                ? FileVideoPlayerWidget(
                    videoUrl: widget.data.validate().urlFromIframe,
                    videoImage: widget.image.validate(),
                    videoTitle: widget.title.validate(),
                    videoId: widget.videoId,
                    videoDuration: widget.videoDuration,
                  )
                : SizedBox(
                    width: context.width(),
                    height: appStore.hasInFullScreen ? context.height() - context.statusBarHeight : context.height() * 0.3,
                    child: Stack(
                      children: [
                        WebViewContentWidget(uri: Uri.dataFromString(movieEmbedCode, mimeType: "text/html")),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: IconButton(
                            onPressed: () {
                              if (appStore.hasInFullScreen) {
                                appStore.setToFullScreen(false);
                              } else {
                                appStore.setToFullScreen(true);
                              }
                            },
                            icon: Icon(appStore.hasInFullScreen ? Icons.fullscreen_exit : Icons.fullscreen_sharp),
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
      },
    );
  }

  String get movieEmbedCode => '''<html>
      <head>
      <script src="https://ajax.googleapis.com/ajax/libs/jquery/2.1.1/jquery.min.js"></script>
      </head>
      <body style="background-color: #000000;">
        <iframe></iframe>
      </body>
      <script>
        \$(function(){
        \$('iframe').attr('src','$urlFromIframe');
        \$('iframe').css('border','none');
        \$('iframe').attr('width','100%');
        \$('iframe').attr('height','100%');
        });
      </script>
    </html> ''';
}

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_flutter/components/view_video/file_video_player_widget.dart';
import 'package:streamit_flutter/main.dart';
import 'package:streamit_flutter/network/rest_apis.dart';
import 'package:streamit_flutter/utils/common.dart';
import 'package:streamit_flutter/utils/constants.dart';
import 'package:streamit_flutter/utils/resources/extentions/string_extentions.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

// ignore: must_be_immutable
class MovieURLWidget extends StatefulWidget {
  static String tag = '/MovieURLWidget';

  String? url;
  final String? title;
  final String? image;
  final String videoId;
  final String videoDuration;

  final VoidCallback? videoCompletedCallback;

  MovieURLWidget(
    this.url, {
    this.title,
    this.image,
    required this.videoId,
    required this.videoDuration,
    this.videoCompletedCallback,
  });

  @override
  MovieURLWidgetState createState() => MovieURLWidgetState();
}

class MovieURLWidgetState extends State<MovieURLWidget> {
  bool isYoutubeUrl = true;
  YoutubePlayerController? _controller;
  int? lastWatchDuration;

  @override
  void initState() {
    super.initState();
    init();
  }

  bool get isMovieFromGoogleDriveLink => widget.url.validate().startsWith("https://drive.google.com");

  Future<void> init() async {
    isYoutubeUrl = widget.url.validate().isYoutubeUrl;
    if (isYoutubeUrl) {
      lastWatchDuration = getLastWatchDuration(postId: widget.videoId);
      _controller = YoutubePlayerController(
        initialVideoId: widget.url.toYouTubeId(),
        flags: const YoutubePlayerFlags(),
      )..addListener(() {
          if (_controller?.value.playerState == PlayerState.ended) {
            widget.videoCompletedCallback?.call();
          }
        });
    }
  }

  Future<void> saveWatchTime() async {
    saveVideoContinueWatch(
      postId: widget.videoId.validate().toInt(),
      watchedTotalTime: _controller!.value.metaData.duration.inSeconds,
      watchedTime: _controller!.value.position.inSeconds,
    ).then((value) {
      LiveStream().emit(RefreshHome);
      getContinueWatchList();
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
    if (isYoutubeUrl) saveWatchTime();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return isYoutubeUrl
        ? Observer(builder: (context) {
            return SizedBox(
              width: context.width(),
              height: appStore.hasInFullScreen ? context.height() - context.statusBarHeight : null,
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
                        widget.videoCompletedCallback?.call();
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
                        saveWatchTime();
                        appStore.setPIPOn(false);
                        finish(context);
                      }
                    },
                    icon: Icon(Icons.arrow_back_rounded),
                  ),
                ],
              ),
            );
          })
        : widget.url.validate().isLiveURL || widget.url.validate().isVideoPlayerFile
            ? FileVideoPlayerWidget(
                videoUrl: widget.url.validate(),
                videoImage: widget.image.validate(),
                videoTitle: widget.title.validate(),
                videoId: widget.videoId,
                videoDuration: widget.videoDuration,
              )
            : isMovieFromGoogleDriveLink
                ? SizedBox(
                    width: context.width(),
                    height: appStore.hasInFullScreen ? context.height() - context.statusBarHeight : context.height() * 0.3,
                    child: Stack(
                      children: [
                        WebViewWidget(
                          controller: WebViewController()
                            ..setJavaScriptMode(JavaScriptMode.unrestricted)
                            ..loadRequest(Uri.dataFromString(movieEmbedCode, mimeType: "text/html")),
                        ),
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
                        IconButton(
                          onPressed: () {
                            if (appStore.hasInFullScreen) {
                              appStore.setToFullScreen(false);
                            } else {
                              appStore.setPIPOn(false);
                              finish(context);
                            }
                          },
                          icon: Icon(Icons.arrow_back_rounded),
                        ),
                      ],
                    ),
                  )
                : SizedBox(
                    width: context.width(),
                    height: 200,
                    child: Stack(
                      children: [
                        WebViewWidget(
                          controller: WebViewController()
                            ..setJavaScriptMode(JavaScriptMode.unrestricted)
                            ..loadRequest(Uri.parse(widget.url.validate())),
                        ),
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
                        IconButton(
                          onPressed: () {
                            if (appStore.hasInFullScreen) {
                              appStore.setToFullScreen(false);
                            } else {
                              appStore.setPIPOn(false);
                              finish(context);
                            }
                          },
                          icon: Icon(Icons.arrow_back_rounded),
                        ),
                      ],
                    ),
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
        \$('iframe').attr('src','${widget.url.validate()}');
        \$('iframe').css('border','none');
        \$('iframe').attr('width','100%');
        \$('iframe').attr('height','100%');
        \$(document).ready(function(){
              \$(".ndfHFb-c4YZDc-Wrql6b").hide();
            });
        });
      </script>
    </html> ''';
}

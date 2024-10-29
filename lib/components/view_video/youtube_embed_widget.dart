import 'package:flutter/material.dart';
import 'package:streamit_flutter/utils/resources/colors.dart';
import 'package:streamit_flutter/utils/resources/extentions/string_extentions.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../main.dart';

class YouTubeEmbedWidget extends StatelessWidget {
  final String videoURL;
  final bool? fullIFrame;
  final Key key;

  YouTubeEmbedWidget(this.videoURL, {this.fullIFrame, required this.key});

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerComponent(url: videoURL);
  }
}

class YoutubePlayerComponent extends StatefulWidget {
  final String url;

  YoutubePlayerComponent({required this.url});

  @override
  State<YoutubePlayerComponent> createState() => _YoutubePlayerComponentState();
}

class _YoutubePlayerComponentState extends State<YoutubePlayerComponent> {
  late YoutubePlayerController _controller;

  bool isPlayerReady = false;

  @override
  void initState() {
    init();
    super.initState();
  }

  void init() {
    _controller = YoutubePlayerController(
      initialVideoId: widget.url.getYouTubeId(),
      flags: YoutubePlayerFlags(
        autoPlay: true,
        disableDragSeek: false,
        loop: false,
        forceHD: false,
        enableCaption: false,
      ),
    );

    setState(() {});
    _controller.play();
    _controller.mute();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      key: widget.key,
      onEnterFullScreen: () {
        appStore.setToFullScreen(true);
      },
      onExitFullScreen: () {
        appStore.setToFullScreen(false);
      },
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        liveUIColor: colorPrimary,
        progressColors: ProgressBarColors(
          playedColor: colorPrimary,
          bufferedColor: Colors.grey.shade400,
          backgroundColor: Colors.white.withOpacity(0.2),
          handleColor: colorPrimary,
        ),
        progressIndicatorColor: colorPrimary,
        onReady: () {
          isPlayerReady = true;
        },
        onEnded: (data) {
          _controller.pause();
        },
      ),
      builder: (context, player) {
        return player;
      },
    );
  }
}

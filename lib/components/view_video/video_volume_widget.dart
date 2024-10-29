import 'package:flutter/material.dart';
import 'package:pod_player/pod_player.dart';

class VideoVolumeWidget extends StatefulWidget {
  final PodPlayerController controller;

  final VoidCallback? callback;

  VideoVolumeWidget({required this.controller,this.callback});

  @override
  VideoVolumeWidgetState createState() => VideoVolumeWidgetState();
}

class VideoVolumeWidgetState extends State<VideoVolumeWidget> {
  bool isMute = true;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    setState(() {
      widget.controller.mute();
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(isMute ? Icons.volume_off_outlined : Icons.volume_up_outlined, size: 18),
      onPressed: () {
        if (isMute) {
          widget.controller.unMute();
        } else {
          widget.controller.mute();
        }
        isMute = !isMute;
        widget.callback?.call();
        setState(() {});
      },
    );
  }
}

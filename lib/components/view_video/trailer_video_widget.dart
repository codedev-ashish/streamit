import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_flutter/components/view_video/pod_player_widget.dart';
import 'package:streamit_flutter/components/view_video/vimeo_embed_widget.dart';
import 'package:streamit_flutter/utils/resources/extentions/string_extentions.dart';

import '../../main.dart';
import '../../utils/resources/size.dart';
import '../cached_image_widget.dart';

class TrailerVideoWidget extends StatelessWidget {
  final String? url;
  final String? title;
  final String? runTime;
  final String? image;
  final bool isShowTitle;
  final bool isVideoInLoop;
  final bool showVolumnDowner;

  final VoidCallback? onTap;

  TrailerVideoWidget({this.url, this.title, this.runTime, this.isShowTitle = false, this.image, this.isVideoInLoop = false, this.showVolumnDowner = false, this.onTap, super.key});

  Widget buildPlayerWidget() {
    if (url.validate().isVimeoVideLink)
      return VimeoWidget(url.validate()).onTap(() {
        onTap?.call();
      });
    else
      return GestureDetector(
        onTap: () {
          onTap?.call();
        },
        child: PodPlayerWidget(
          title: title,
          image: image,
          isShowTitle: isShowTitle,
          isVideoInLoop: isVideoInLoop,
          onTap: () {
            onTap?.call();
          },
          runTime: runTime,
          showVolumnDowner: showVolumnDowner,
          url: url.validate(),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    var width = context.width();
    final Size cardSize = Size(width, appStore.hasInFullScreen ? context.height() : context.height() * 0.3);

    return Container(
      width: context.width(),
      height: cardSize.height,
      decoration: boxDecorationDefault(color: context.cardColor, boxShadow: []),
      child: url.validate().isEmpty
          ? CachedImageWidget(url: image.validate(), width: cardSize.width, height: cardSize.height, fit: BoxFit.cover).cornerRadiusWithClipRRect(radius_container).onTap(() {
              onTap?.call();
            })
          : Container(
              width: width,
              height: cardSize.height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    context.scaffoldBackgroundColor.withOpacity(0.3),
                  ],
                  stops: [0.3, 1.0],
                  begin: FractionalOffset.topCenter,
                  end: FractionalOffset.bottomCenter,
                  tileMode: TileMode.mirror,
                ),
              ),
              child: buildPlayerWidget(),
            ),
    );
  }
}

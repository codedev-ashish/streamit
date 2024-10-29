import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_flutter/components/cached_image_widget.dart';
import 'package:streamit_flutter/components/view_video/embed_widget.dart';
import 'package:streamit_flutter/components/view_video/file_video_player_widget.dart';
import 'package:streamit_flutter/components/view_video/webview_content_widget.dart';
import 'package:streamit_flutter/screens/movie_episode/components/movie_url_widget.dart';
import 'package:streamit_flutter/utils/common.dart';
import 'package:streamit_flutter/utils/constants.dart';
import 'package:streamit_flutter/utils/resources/extentions/string_extentions.dart';
import '../../main.dart';

class VideoContentWidget extends StatelessWidget {
  final String? choice;
  final String? urlLink;
  final String? embedContent;
  final String? fileLink;
  final String? image;
  final String? title;
  final String videoId;
  final bool? isUserResumeVideo;
  final String videoDuration;

  final VoidCallback? onMovieCompleted;

  VideoContentWidget({
    this.choice,
    this.urlLink,
    this.embedContent,
    this.fileLink,
    this.image,
    this.title,
    required this.videoId,
    this.isUserResumeVideo = false,
    required this.videoDuration,
    this.onMovieCompleted,
  });

  @override
  Widget build(BuildContext context) {
    if (choice.validate() == movieChoiceURL || choice.validate() == videoChoiceURL || choice.validate() == episodeChoiceURL || choice.validate()==movieChoiceLiveStream) {
      return MovieURLWidget(
        urlLink.validate(),
        title: title.validate(),
        image: image.validate(),
        videoId: videoId,
        videoDuration: videoDuration,
        videoCompletedCallback: () {
          onMovieCompleted?.call();
        },
      );
    } else if (choice.validate() == movieChoiceEmbed || choice.validate() == videoChoiceEmbed || choice.validate() == episodeChoiceEmbed) {
      String src = getVideoLink(embedContent.validate());
      if (src.isVimeoVideLink) {
        return FutureBuilder<String>(
          future: getQualitiesAsync(videoId: src.getVimeoVideoId.validate(), embedContent: embedContent.validate()),
          builder: (ctx, snap) {
            if (snap.hasData) {
              return snap.data!.isVimeoVideLink
                  ? WebViewContentWidget(uri: Uri.parse(getVideoLink(embedContent.validate())))
                  : FileVideoPlayerWidget(
                      videoUrl: snap.data.validate(),
                      videoImage: image.validate(),
                      videoTitle: title.validate(),
                      videoId: videoId,
                      hasResumePauseVideo: isUserResumeVideo!,
                      videoDuration: videoDuration,
                      videoCompletedCallback: () {
                        onMovieCompleted?.call();
                      },
                    );
            }
            return Loader().withHeight(context.height() * 0.3);
          },
        );
      } else {
        return EmbedWidget(
          embedContent.validate(),
          videoId: videoId,
          videoDuration: videoDuration,
          videoCompletedCallback: () {
            onMovieCompleted?.call();
          },
        );
      }
    } else if (choice.validate() == movieChoiceFile || choice.validate() == videoChoiceFile || choice.validate() == episodeChoiceFile) {
      return FileVideoPlayerWidget(
        videoUrl: fileLink.validate(),
        videoImage: image.validate(),
        videoTitle: title.validate(),
        videoId: videoId,
        hasResumePauseVideo: isUserResumeVideo!,
        videoDuration: videoDuration,
        videoCompletedCallback: () {
          onMovieCompleted?.call();
        },
      );
    } else {
      return Container(
        width: context.width(),
        height: appStore.hasInFullScreen ? context.height() - context.statusBarHeight : context.height() * 0.3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedImageWidget(
              url: image.validate(),
              fit: BoxFit.cover,
              height: appStore.hasInFullScreen ? context.height() - context.statusBarHeight : context.height() * 0.3,
            ),
            Positioned(
              top: 0,
              left: 0,
              child: BackButton(),
            ),
          ],
        ),
      );
    }
  }
}

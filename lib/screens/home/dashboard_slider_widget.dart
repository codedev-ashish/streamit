import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:pod_player/pod_player.dart';
import 'package:streamit_flutter/components/trailer_gesture_detector.dart';
import 'package:streamit_flutter/components/view_video/video_volume_widget.dart';

import 'package:streamit_flutter/main.dart';
import 'package:streamit_flutter/models/movie_episode/common_data_list_model.dart';
import 'package:streamit_flutter/screens/movie_episode/screens/movie_detail_screen.dart';
import 'package:streamit_flutter/utils/resources/extentions/string_extentions.dart';
import 'package:streamit_flutter/utils/resources/size.dart';

import '../../components/cached_image_widget.dart';
import '../../components/view_video/vimeo_embed_widget.dart';
import '../../utils/app_widgets.dart';
import '../../utils/common.dart';
import '../../utils/resources/colors.dart';

class DashboardSliderWidget extends StatefulWidget {
  final List<CommonDataListModel> mSliderList;

  DashboardSliderWidget({required this.mSliderList, super.key});

  @override
  State<DashboardSliderWidget> createState() => _DashboardSliderWidgetState();
}

class _DashboardSliderWidgetState extends State<DashboardSliderWidget> {
  PodPlayerController? podPlayerController;

  bool isMute = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> initVideoPlayer({required String url}) async {
    if (mounted) {
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
      Future.microtask(
            () => setState(
              () {
                isMute = (podPlayerController?.isMute).validate();
                if (isMute) {
                  podPlayerController?.mute();
                }
                podPlayerController?.showOverlay();
          },
        ),
      );

      Future.microtask(() => setState(() {}));
    }
  }

  Widget buildPlayerWidget(CommonDataListModel slider) {
    if (slider.trailerLink.validate().isVimeoVideLink)
      return VimeoWidget(slider.trailerLink.validate());
    else
      return Stack(
        children: [
          PodVideoPlayer(
            key: UniqueKey(),
            controller: podPlayerController!,
            frameAspectRatio: 16 / 9,
            videoAspectRatio: 16 / 9,
            podPlayerLabels: PodPlayerLabels(),
            videoThumbnail: DecorationImage(image: NetworkImage(slider.image.validate())),
            onVideoError: () {
              return CachedImageWidget(url: slider.image.validate());
            },
            onLoading: (context) {
              return Loader();
            },
            podProgressBarConfig: PodProgressBarConfig(
              playingBarColor: colorPrimary,
              circleHandlerColor: colorPrimary,
              height: 4,
              curveRadius: 8,
              padding: EdgeInsets.only(left: 16, right: 16, bottom: 8),
            ),
            alwaysShowProgressBar: false,
            videoTitle: itemTitle(context, parseHtmlString(slider.title.validate()), fontSize: ts_small_large, maxLine: 2, textAlign: TextAlign.start).paddingSymmetric(horizontal: 8),
            onToggleFullScreen: (isFullScreen) async {
              appStore.setLoading(true);
              appStore.setToFullScreen(isFullScreen);

              return Future.delayed(Duration(seconds: 1), () {
                podPlayerController?.enableFullScreen();
                appStore.setLoading(false);
              });
            },
          ),
          Positioned(
            bottom: 16,
            right: 30,
            child: VideoVolumeWidget(
              controller: podPlayerController!,
              callback: () {},
            ),
          )
        ],
      );
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    if (podPlayerController != null && podPlayerController!.isInitialised) podPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var width = context.width();
    final Size cardSize = Size(width, appStore.hasInFullScreen ? context.height() : context.height() * 0.26);

    return Container(
      height: cardSize.height,
      width: cardSize.width,
      decoration: BoxDecoration(boxShadow: [], color: context.scaffoldBackgroundColor),
      child: PageView.builder(
        onPageChanged: (value) async {
          if (!widget.mSliderList.validate()[value].trailerLink.validate().isVimeoVideLink) {
            if (podPlayerController!.isInitialised) {
              podPlayerController?.pause();
              podPlayerController?.changeVideo(
                playVideoFrom: widget.mSliderList.validate()[value].trailerLink.validate().getPlatformVideo(),
                playerConfig: PodPlayerConfig(
                  autoPlay: true,
                  wakelockEnabled: true,
                  isLooping: true,
                  forcedVideoFocus: true,
                ),
              );

              Future.microtask(
                () => setState(
                  () {
                    podPlayerController?.togglePlayPause();
                    podPlayerController?.showOverlay();
                    podPlayerController?.mute();
                  },
                ),
              );
            } else {
              initVideoPlayer(url: widget.mSliderList.validate()[value].trailerLink.validate());
            }
          }
        },
        itemCount: widget.mSliderList.validate().length,
        itemBuilder: (context, index) {
          CommonDataListModel slider = widget.mSliderList.validate()[index];
          if (!slider.trailerLink.validate().isVimeoVideLink && podPlayerController == null && mounted) initVideoPlayer(url: slider.trailerLink.validate());
          return Container(
            key: ValueKey(index),
            width: context.width(),
            height: cardSize.height,
            decoration: BoxDecoration(boxShadow: [], color: context.scaffoldBackgroundColor),
            child: TrailerGestureDetector(
              isVimeo: slider.trailerLink.validate().isVimeoVideLink,
              onTapOutsideCenter: () {
                appStore.setTrailerVideoPlayer(false);
                if (podPlayerController != null) {
                  podPlayerController?.pause();
                }
                MovieDetailScreen(movieData: slider, title: slider.title).launch(context).then((v) {
                  if (podPlayerController != null) {
                    podPlayerController?.togglePlayPause();
                  }
                });
              },
              onTapCenter: () {
                if (podPlayerController != null) {
                  if (podPlayerController!.videoPlayerValue!.isPlaying) {
                    podPlayerController?.pause();
                  } else {
                    podPlayerController?.play();
                  }
                }
              },
              child: Stack(
                children: [
                  slider.trailerLink.validate().isEmpty
                      ? CachedImageWidget(
                          url: slider.image.validate(),
                          width: cardSize.width,
                          height: cardSize.height,
                          fit: BoxFit.cover,
                        )
                      : buildPlayerWidget(slider),
                  Container(
                    width: cardSize.width,
                    height: slider.trailerLink.validate().isVimeoVideLink ? cardSize.height - 40 : cardSize.height,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          slider.trailerLink.validate().isVimeoVideLink ? Colors.transparent : context.scaffoldBackgroundColor.withOpacity(0.3),
                        ],
                        stops: [0.3, 1.0],
                        begin: FractionalOffset.topCenter,
                        end: FractionalOffset.bottomCenter,
                        tileMode: TileMode.mirror,
                      ),
                    ),
                  ),
                  Loader().visible(appStore.isLoading).center()
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

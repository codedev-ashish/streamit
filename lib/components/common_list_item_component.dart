import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:streamit_flutter/components/cached_image_widget.dart';
import 'package:streamit_flutter/main.dart';
import 'package:streamit_flutter/models/movie_episode/common_data_list_model.dart';
import 'package:streamit_flutter/models/movie_episode/movie_data.dart';
import 'package:streamit_flutter/screens/movie_episode/screens/episode_detail_screen.dart';
import 'package:streamit_flutter/screens/movie_episode/screens/movie_detail_screen.dart';
import 'package:streamit_flutter/utils/app_widgets.dart';
import 'package:streamit_flutter/utils/common.dart';
import 'package:streamit_flutter/utils/constants.dart';
import 'package:streamit_flutter/utils/resources/colors.dart';
import 'package:streamit_flutter/utils/resources/size.dart';

class CommonListItemComponent extends StatelessWidget {
  final CommonDataListModel data;
  final bool isContinueWatch;
  final VoidCallback? callback;
  final VoidCallback? refresh;
  final bool isVerticalList;
  final bool isWatchList;
  final double? width;

  final bool isLandscape;

  CommonListItemComponent({this.callback, this.isLandscape = false, required this.data, this.isContinueWatch = false, this.isVerticalList = false, this.isWatchList = false, this.width, this.refresh});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        if (!getBoolAsync(HAS_IN_REVIEW) && youtubePlayerController != null) youtubePlayerController!.pause();
        LiveStream().emit(PauseVideo);

        appStore.setTrailerVideoPlayer(!isContinueWatch);
        finish(context);

        if (data.postType == PostType.EPISODE) {
          MovieData episode = MovieData();
          episode.title = data.title;
          episode.image = data.image;
          episode.id = data.id;
          episode.postType = PostType.EPISODE;

          await EpisodeDetailScreen(episode: episode, episodes: []).launch(context).then((value) {
            if (isWatchList) refresh?.call();
          });
        } else {
          await MovieDetailScreen(movieData: data).launch(context).then((value) {
            if (isWatchList) refresh?.call();
          });
        }
        if (!getBoolAsync(HAS_IN_REVIEW) && youtubePlayerController != null) youtubePlayerController!.play();
      },
      borderRadius: BorderRadius.circular(radius_container),
      child: isLandscape
          ? Stack(
              children: [
                Container(
                  width: context.width() / 2 - 22,
                  height: context.height() * .12,
                  decoration: boxDecorationDefault(
                    boxShadow: [],
                    image: DecorationImage(
                      image: NetworkImage(data.image.validate()),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Container(
                  width: context.width() / 2 - 22,
                  height: context.height() * .12,
                  decoration: boxDecorationDefault(
                    boxShadow: [],
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      tileMode: TileMode.mirror,
                      colors: [
                        Colors.transparent,
                        Colors.black87,
                      ],
                    ),
                  ),
                ),
                if (isContinueWatch && data.watchedDuration != null)
                  Positioned(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 16),
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            color: context.scaffoldBackgroundColor.withOpacity(0.5),
                            child: Text(
                              formatWatchedTime(totalSeconds: data.watchedDuration!.watchedTotalTime.validate().toInt(), watchedSeconds: data.watchedDuration!.watchedTime.validate().toInt()),
                              style: secondaryTextStyle(size: 12),
                            ),
                          ),
                        ),
                        4.height,
                        LinearPercentIndicator(
                          animation: false,
                          lineHeight: 2,
                          percent: data.watchedDuration!.watchedTimePercentage.toInt() / 100,
                          progressColor: context.primaryColor,
                          backgroundColor: textColorThird,
                        ),
                      ],
                    ),
                    right: -10,
                    left: -10,
                    bottom: 12,
                  ),
                if (isContinueWatch && data.watchedDuration != null)
                  Positioned(
                    top: 2,
                    right: -4,
                    child: InkWell(
                      onTap: () {
                        callback?.call();
                      },
                      child: Icon(Icons.cancel, color: context.primaryColor, size: 20),
                    ).paddingSymmetric(horizontal: 8, vertical: 4),
                  ),
                if (!isContinueWatch && appStore.showItemName)
                  Positioned(
                    child: Text(
                      data.title.validate(),
                      style: primaryTextStyle(),
                      textAlign: TextAlign.center,
                    ),
                    right: 8,
                    left: 8,
                    bottom: 8,
                  )
              ],
            )
          : Stack(
              children: [
                SizedBox(
                  height: 200,
                  width: isVerticalList ? getWidth(context) : 140,
                  child: Stack(
                    children: [
                      SizedBox(
                        height: 200,
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            CachedImageWidget(
                              url: data.image.validate(),
                              height: context.height() - 20,
                              width: context.width(),
                              fit: BoxFit.cover,
                            ).cornerRadiusWithClipRRect(radius_container),
                            if (isContinueWatch && data.watchedDuration != null)
                              LinearPercentIndicator(
                                animation: false,
                                lineHeight: 2,
                                percent: data.watchedDuration!.watchedTimePercentage.toInt() / 100,
                                progressColor: context.primaryColor,
                                backgroundColor: textColorThird,
                              ).paddingSymmetric(vertical: 8),
                            if (isContinueWatch && data.watchedDuration != null)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: InkWell(
                                  onTap: () {
                                    callback?.call();
                                  },
                                  child: Icon(Icons.cancel, color: context.primaryColor, size: 20),
                                ).paddingSymmetric(horizontal: 8, vertical: 4),
                              )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Observer(
                  builder: (_) => Container(
                    height: 200,
                    width: isVerticalList ? getWidth(context) : 140,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: FractionalOffset.topCenter,
                        end: FractionalOffset.bottomCenter,
                        colors: [
                          ...List<Color>.generate(20, (index) => Colors.black.withAlpha(index * 10)),
                        ],
                      ),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: itemTitle(
                        context,
                        parseHtmlString(data.title.validate()),
                        fontSize: ts_small,
                        textAlign: TextAlign.start,
                      ),
                    ),
                  ).visible(appStore.showItemName),
                ),
              ],
            ),
    );
  }
}

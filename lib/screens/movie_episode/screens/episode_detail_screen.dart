import 'package:fl_pip/fl_pip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:streamit_flutter/components/cached_image_widget.dart';
import 'package:streamit_flutter/models/movie_episode/movie_data.dart';
import 'package:streamit_flutter/screens/movie_episode/comments/comment_widget.dart';
import 'package:streamit_flutter/components/episode_item_component.dart';
import 'package:streamit_flutter/components/loader_widget.dart';
import 'package:streamit_flutter/screens/movie_episode/components/movie_detail_like_watchlist_widget.dart';
import 'package:streamit_flutter/screens/movie_episode/components/post_restriction_component.dart';
import 'package:streamit_flutter/screens/movie_episode/components/sources_data_widget.dart';
import 'package:streamit_flutter/components/view_video/video_content_widget.dart';
import 'package:streamit_flutter/network/rest_apis.dart';
import 'package:streamit_flutter/screens/downloads/download_file_screen.dart';
import 'package:streamit_flutter/screens/movie_episode/components/video_cast_devicelist_widget.dart';
import 'package:streamit_flutter/utils/app_widgets.dart';
import 'package:streamit_flutter/utils/common.dart';
import 'package:streamit_flutter/utils/constants.dart';
import 'package:streamit_flutter/utils/html_widget.dart';
import 'package:streamit_flutter/utils/resources/colors.dart';
import 'package:streamit_flutter/utils/resources/size.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../main.dart';
import '../components/movie_url_widget.dart';

class EpisodeDetailScreen extends StatefulWidget {
  static String tag = '/EpisodeDetailScreen';
  final String? title;
  final MovieData? episode;
  final List<MovieData>? episodes;
  final int? index;
  final int? lastIndex;

  EpisodeDetailScreen({this.title, this.episode, this.episodes, this.index, this.lastIndex});

  @override
  EpisodeDetailScreenState createState() => EpisodeDetailScreenState();
}

class EpisodeDetailScreenState extends State<EpisodeDetailScreen> with WidgetsBindingObserver, TickerProviderStateMixin {
  ScrollController scrollController = ScrollController();

  bool showComments = false;
  String restrictedPlans = '';

  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  late MovieData data;
  late int episodeIndex;

  double selectedRating = 0;

  bool pipAvailable = false;

  @override
  void initState() {
    ScreenProtector.preventScreenshotOn();
    episodeIndex = widget.index.validate();
    data = widget.episode!;
    showComments = appStore.showEpisodeComment;
    WakelockPlus.enable();
    requestPipAvailability();
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    init();
  }

  Future<void> init() async {
    _controller = AnimationController(duration: Duration(milliseconds: 500), vsync: this);
    _offsetAnimation = Tween<Offset>(begin: Offset(0, 1), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.decelerate));

    afterBuildCreated(() {
      getEpisodeDetails(data.id.validate());
    });
  }

  void getEpisodeDetails(int episodeId) async {
    appStore.setLoading(true);
    await getEpisodeDetail(episodeId).then((value) {
      data = value;
      if (value.subscriptionLevels.validate().isNotEmpty) {
        value.subscriptionLevels.validate().forEach((element) {
          restrictedPlans = restrictedPlans + '${restrictedPlans.isEmpty ? '' : ','} ${element.label}';
        });
      }

      setState(() {});

      appStore.setLoading(false);
    }).catchError((e) {
      appStore.setLoading(false);

      toast(e.toString());
    });
  }

  Future<void> requestPipAvailability() async {
    pipAvailable = await FlPiP().isAvailable;
    setState(() {});
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    if (appStore.isLoading) appStore.setLoading(false);
    ScreenProtector.preventScreenshotOff();
    super.dispose();
  }

  Widget subscriptionEpisode(MovieData _episode) {
    if (data.userHasAccess.validate()) {
      return GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.delta.dy <= 0 && details.delta.dx == 0) {
            _controller.forward();
          }
          if (details.delta.dy >= 0 && details.delta.dx == 0) {
            _controller.reverse();
          }
        },
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            VideoContentWidget(
              choice: _episode.choice,
              image: _episode.image,
              urlLink: _episode.urlLink.validate().replaceAll(r'\/', '/'),
              embedContent: _episode.embedContent,
              fileLink: _episode.episodeFile.validate().isNotEmpty ? _episode.episodeFile : _episode.file.validate(),
              videoId: _episode.id.validate().toString(),
              videoDuration: _episode.runTime.validate(),
            ),
            if (appStore.hasInFullScreen)
              SlideTransition(
                position: _offsetAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Theme.of(context).scaffoldBackgroundColor],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.0, 1.0],
                      tileMode: TileMode.repeated,
                    ),
                  ),
                  child: EpisodeListWidget(
                    widget.episodes.validate(),
                    episodeIndex,
                    onEpisodeChange: (i, episode) {
                      if (appStore.hasInFullScreen) {
                        appStore.setToFullScreen(false);
                        setOrientationPortrait();
                      }
                      episodeIndex = i;
                      getEpisodeDetails(episode);
                    },
                  ),
                ),
              ),
          ],
        ),
      );
    } else {
      return PostRestrictionComponent(
        imageUrl: _episode.image.validate(),
        isPostRestricted: !data.userHasAccess.validate(),
        restrictedPlans: restrictedPlans,
        callToRefresh: () {
          init();
          appStore.setTrailerVideoPlayer(true);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        if (appStore.hasInFullScreen) {
          appStore.setToFullScreen(false);
          setOrientationPortrait();
          return Future.value(false);
        }
        return Future.value(true);
      },
      child: SafeArea(
        child: PiPBuilder(
          builder: (statusInfo) {
            return Scaffold(
                appBar: ((statusInfo?.status == PiPStatus.enabled) || (!data.userHasAccess.validate() || !appStore.isTrailerVideoPlaying))
                    ? null
                    : PreferredSize(
                        preferredSize: Size(context.width(), kToolbarHeight),
                        child: AppBar(
                          title: Text(parseHtmlString(data.title.validate()),style: boldTextStyle(size: 20)),
                          systemOverlayStyle: defaultSystemUiOverlayStyle(context),
                          surfaceTintColor: context.scaffoldBackgroundColor,
                          elevation: 0,
                        ),
                      ),
                key: ValueKey(data),
                resizeToAvoidBottomInset: true,
                body: Observer(builder: (_) {
                  return Stack(
                    children: [
                      Container(
                        width: context.width(),
                        height: context.height(),
                        child: SingleChildScrollView(
                          physics: context.width() >= 480 ? NeverScrollableScrollPhysics() : ScrollPhysics(),
                          controller: scrollController,
                          padding: EdgeInsets.only(bottom: 30,top: 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              getBoolAsync(HAS_IN_REVIEW)
                                  ? MovieURLWidget(
                                      IN_REVIEW_VIDEO,
                                      title: data.title,
                                      image: getBoolAsync(HAS_IN_REVIEW) ? IN_REVIEW_VIDEO.getYouTubeThumbnail() : data.image,
                                      videoId: data.id.toString(),
                                      videoDuration: data.runTime.validate(),
                                      videoCompletedCallback: () {},
                                    )
                                  : subscriptionEpisode(data),
                              8.height,
                              if (statusInfo!.status != PiPStatus.enabled) ...[
                                Row(
                                  children: [
                                    CachedImageWidget(
                                      url: data.image.validate(),
                                      width: 80,
                                      height: 100,
                                      fit: BoxFit.fill,
                                    ).cornerRadiusWithClipRRect(4),
                                    8.width,
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          data.title.validate(),
                                          style: primaryTextStyle(size: 18),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        4.height,
                                        itemSubTitle(
                                          context,
                                          "${data.releaseDate.validate()}",
                                          fontSize: 14,
                                          textColor: Colors.grey.shade500,
                                        ),
                                        4.height,
                                        itemSubTitle(context, data.runTime.validate(), fontSize: 14, textColor: Colors.grey.shade500),
                                        4.height,
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(12),
                                              decoration: BoxDecoration(color: cardColor, borderRadius: radius(4)),
                                              child: Icon(Icons.share_rounded, color: textSecondaryColor, size: 18),
                                            ).onTap(() {
                                              shareMovieOrEpisode(data.shareUrl.validate());
                                            }).paddingOnly(right: 8),
                                            if (data.episodeFile.validate().isNotEmpty && data.userHasAccess.validate() && !getBoolAsync(HAS_IN_REVIEW))
                                              Container(
                                                padding: EdgeInsets.all(12),
                                                decoration: BoxDecoration(color: cardColor, borderRadius: radius(4)),
                                                child: Icon(Icons.cast_rounded, color: textSecondaryColor, size: 20),
                                              ).onTap(() {
                                                VideoCastDeviceListScreen(
                                                  videoURL: data.urlLink.validate(),
                                                  videoTitle: data.title.validate(),
                                                  videoImage: data.image.validate(),
                                                ).launch(context);
                                              }).paddingOnly(right: 8),
                                            if (data.episodeFile.validate().isNotEmpty && appStore.isLogging && data.userHasAccess.validate() && !getBoolAsync(HAS_IN_REVIEW))
                                              DownloadVideoFromLinkWidget(
                                                videoName: data.title.validate(),
                                                videoLink: data.episodeFile.validate(),
                                                videoImage: data.image.validate(),
                                                videoId: data.id.validate().toString(),
                                                videoDescription: data.description.validate(),
                                                videoDuration: data.runTime.validate(),
                                              ).paddingRight(8),
                                            if (appStore.showPIP)
                                              Container(
                                                padding: EdgeInsets.all(12),
                                                decoration: BoxDecoration(color: cardColor, borderRadius: radius(4)),
                                                child: Icon(Icons.picture_in_picture_alt_rounded, color: textSecondaryColor, size: 20),
                                              ).onTap(() {
                                                if (pipAvailable) {
                                                  appStore.setPIPOn(true);
                                                  FlPiP().enable(
                                                    ios: FlPiPiOSConfig(
                                                      enablePlayback: true,
                                                      enableControls: true,
                                                      packageName: null,
                                                      path: data.episodeFile.validate(),
                                                    ),
                                                    android: FlPiPAndroidConfig(
                                                      aspectRatio: Rational.maxLandscape(),
                                                      path: data.episodeFile.validate(),
                                                    ),
                                                  );
                                                  setState(() {});
                                                } else {
                                                  toast(language?.pipNotAvailable);
                                                }
                                              }).paddingOnly(right: 8),
                                          ],
                                        ),
                                      ],
                                    ).expand(),
                                  ],
                                ).paddingOnly(left: spacing_standard, right: spacing_standard),
                                if (data.userHasAccess.validate() && !getBoolAsync(HAS_IN_REVIEW))
                                  HtmlWidget(
                                    postContent: data.description.validate(),
                                    color: textColorSecondary,
                                    fontSize: 14,
                                  ).paddingAll(8),
                                Divider(thickness: 0.1, color: Colors.grey.shade500).visible(data.sourcesList.validate().isNotEmpty && data.userHasAccess.validate()),
                                MovieDetailLikeWatchListWidget(
                                  postId: data.id.validate(),
                                  postType: PostType.EPISODE,
                                  isInWatchList: data.isInWatchList,
                                  isLiked: data.isLiked.validate(),
                                  likes: data.likes,
                                ).paddingSymmetric(horizontal: 16),
                                if (data.sourcesList.validate().isNotEmpty && data.userHasAccess.validate() && !getBoolAsync(HAS_IN_REVIEW))
                                  Text(
                                    language!.sources,
                                    style: primaryTextStyle(size: 18),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ).paddingAll(8),
                                if (data.sourcesList.validate().isNotEmpty && data.userHasAccess.validate() && !getBoolAsync(HAS_IN_REVIEW))
                                  SourcesDataWidget(
                                    sourceList: data.sourcesList,
                                    onLinkTap: (sources) async {
                                      youtubePlayerController!.pause();
                                      LiveStream().emit(PauseVideo);
                                      data.choice = sources.choice;

                                      if (sources.choice == "episode_embed") {
                                        if (sources.embedContent!.contains('<iframe')) {
                                          data.embedContent = sources.embedContent;
                                          data.choice = "episode_embed";
                                        } else if (sources.embedContent!.contains('http')) {
                                          data.urlLink = sources.embedContent;
                                          data.choice = "episode_url";
                                        }
                                      }
                                      setState(() {});
                                    },
                                  ).paddingAll(8),
                                Divider(
                                  thickness: 0.1,
                                  color: Colors.grey.shade500,
                                ).visible(data.sourcesList.validate().isNotEmpty && data.userHasAccess.validate() && !getBoolAsync(HAS_IN_REVIEW)),
                                if (showComments && data.isCommentOpen.validate() && data.userHasAccess.validate() && !getBoolAsync(HAS_IN_REVIEW))
                                  CommentWidget(
                                    postId: data.id,
                                    noOfComments: data.noOfComments,
                                    postType: PostType.EPISODE,
                                    comments: data.comments.validate(),
                                  ).paddingAll(16),
                                Divider(thickness: 0.1, color: Colors.grey.shade500).visible(widget.episodes.validate().isNotEmpty && !getBoolAsync(HAS_IN_REVIEW)),
                                headingWidViewAll(context, language!.episodes, showViewMore: false).paddingOnly(left: spacing_standard, right: spacing_standard).visible(widget.episodes.validate().isNotEmpty),
                                EpisodeListWidget(
                                  widget.episodes.validate(),
                                  episodeIndex,
                                  onEpisodeChange: (i, episode) {
                                    if (appStore.hasInFullScreen) {
                                      appStore.setToFullScreen(false);
                                      setOrientationPortrait();
                                    }
                                    episodeIndex = i;
                                    getEpisodeDetails(episode);
                                  },
                                ).visible(widget.episodes.validate().isNotEmpty),
                                8.height,
                              ]
                            ],
                          ),
                        ),
                      ),
                      LoaderWidget().visible(appStore.isLoading)
                    ],
                  );
                }));
          },
        ),
      ),
    );
  }
}

class EpisodeListWidget extends StatelessWidget {
  final List<MovieData> episodes;
  final Function(int, int)? onEpisodeChange;
  final int index;

  EpisodeListWidget(this.episodes, this.index, {this.onEpisodeChange});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: episodes.length,
      itemBuilder: (context, i) {
        MovieData episode = episodes[i];

        return EpisodeItemComponent(
          episode: episode,
          callback: () {
            onEpisodeChange?.call(i, episode.id.validate());
          },
        );
      },
    );
  }
}

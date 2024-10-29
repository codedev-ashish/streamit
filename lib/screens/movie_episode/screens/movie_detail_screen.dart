import 'dart:async';

import 'package:fl_pip/fl_pip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:html/parser.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:streamit_flutter/components/cached_image_widget.dart';
import 'package:streamit_flutter/models/movie_episode/common_data_list_model.dart';
import 'package:streamit_flutter/models/movie_episode/movie_detail_common_models.dart';
import 'package:streamit_flutter/screens/movie_episode/comments/comment_widget.dart';
import 'package:streamit_flutter/components/loader_widget.dart';
import 'package:streamit_flutter/screens/movie_episode/components/movie_detail_like_watchlist_widget.dart';
import 'package:streamit_flutter/screens/movie_episode/components/post_restriction_component.dart';
import 'package:streamit_flutter/screens/movie_episode/components/season_data_widget.dart';
import 'package:streamit_flutter/screens/movie_episode/components/sources_data_widget.dart';
import 'package:streamit_flutter/components/view_video/trailer_video_widget.dart';
import 'package:streamit_flutter/screens/movie_episode/components/upcoming_related_movie_list_widget.dart';
import 'package:streamit_flutter/components/view_video/video_content_widget.dart';
import 'package:streamit_flutter/main.dart';
import 'package:streamit_flutter/models/movie_episode/movie_data.dart';
import 'package:streamit_flutter/models/movie_episode/movie_detail_response.dart';
import 'package:streamit_flutter/network/rest_apis.dart';
import 'package:streamit_flutter/screens/cast/cast_detail_screen.dart';
import 'package:streamit_flutter/screens/downloads/download_file_screen.dart';
import 'package:streamit_flutter/screens/movie_episode/components/video_cast_devicelist_widget.dart';
import 'package:streamit_flutter/utils/app_widgets.dart';
import 'package:streamit_flutter/utils/common.dart';
import 'package:streamit_flutter/config.dart';
import 'package:streamit_flutter/utils/constants.dart';
import 'package:streamit_flutter/utils/html_widget.dart';
import 'package:streamit_flutter/utils/resources/colors.dart';
import 'package:streamit_flutter/utils/resources/size.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../components/movie_url_widget.dart';

class MovieDetailScreen extends StatefulWidget {
  final String? title;
  final CommonDataListModel movieData;
  final int? currentIndex;
  final List<CommonDataListModel>? playList;
  final VoidCallback? onRemoveFromPlaylist;

  MovieDetailScreen({this.title = "", required this.movieData, this.onRemoveFromPlaylist, this.currentIndex, this.playList});

  @override
  MovieDetailScreenState createState() => MovieDetailScreenState();
}

class MovieDetailScreenState extends State<MovieDetailScreen> {
  ScrollController scrollController = ScrollController();

  late MovieData movie;
  MovieDetailResponse? movieResponse;

  int selectedIndex = 0;

  int currentIndex = 0;
  String genre = '';

  InterstitialAd? interstitialAd;

  PostType? postType;

  bool hasResumeMovie = false;
  bool hasPopUpMessage = false;

  bool showComments = false;
  bool isError = false;
  bool hasData = false;

  String restrictedPlans = '';

  List<Map<String, List>> castCrewHeaderList = [];
  Map<String, List>? selectedData;
  bool pipAvailable = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    ScreenProtector.preventScreenshotOn();
    requestPipAvailability();
    init();
  }

  Future<void> init() async {
    movie = MovieData(image: widget.movieData.image, title: widget.movieData.title, id: widget.movieData.id, postType: widget.movieData.postType);
    currentIndex = widget.currentIndex ?? 0;

    if (widget.playList.validate().isNotEmpty) {
      CommonDataListModel data = widget.playList.validate()[currentIndex];
      movie = MovieData(image: data.image, title: data.title, id: data.id, postType: data.postType);
    }
    postType = movie.postType!;
    setState(() {});

    getDetails();

    if (adShowCount < 5) {
      adShowCount++;
    } else {
      adShowCount = 0;
      buildInterstitialAd();
    }
  }

  Future<void> requestPipAvailability() async {
    pipAvailable = await FlPiP().isAvailable;
    setState(() {});
  }

  Future<MovieDetailResponse?> getDetailAPIByType() async {
    if (widget.movieData.postType == PostType.MOVIE) {
      showComments = appStore.showMovieComments;
      setState(() {});
      return movieDetail(movie.id.validate());
    } else if (widget.movieData.postType == PostType.TV_SHOW) {
      showComments = appStore.showTVShowComments;
      setState(() {});
      return tvShowDetail(movie.id.validate());
    } else if (widget.movieData.postType == PostType.EPISODE) {
      showComments = appStore.showEpisodeComment;
      setState(() {});
      return episodeDetail(movie.id.validate());
    } else if (widget.movieData.postType == PostType.VIDEO) {
      showComments = appStore.showVideoComments;
      setState(() {});
      return getVideosDetail(movie.id.validate());
    } else {
      return null;
    }
  }

  Future<void> getDetails() async {
    appStore.setLoading(true);
    await getDetailAPIByType().then((value) {
      if (value != null) {
        movieResponse = value;
        hasData = true;
        movie = value.data ?? MovieData();
        castCrewHeaderList.clear();
        if (movie.castsList.validate().isNotEmpty) {
          castCrewHeaderList.add({'Casts': movie.castsList.validate()});
        }
        if (movie.crews.validate().isNotEmpty) {
          castCrewHeaderList.add({'Crews': movie.crews.validate()});
        }

        if (value.data?.genre != null) {
          genre = '';

          value.data!.genre!.forEach((element) {
            if (genre.isNotEmpty) {
              genre = '$genre • ${element.validate()}';
            } else {
              genre = element.validate();
            }
          });
        }

        if (value.data != null) movie = value.data!;

        if (value.data!.trailerLink.validate().isNotEmpty) {
          appStore.setTrailerVideoPlayer(true);
        }

        if (value.data!.subscriptionLevels.validate().isNotEmpty && !value.data!.userHasAccess.validate()) {
          value.data!.subscriptionLevels!.forEach((element) {
            restrictedPlans = restrictedPlans + '${restrictedPlans.isEmpty ? '' : ','} ${element.label}';
          });
        }
        setState(() {});
        appStore.setLoading(false);
      }
    }).catchError((e) {
      isError = true;
      setState(() {});
      appStore.setLoading(false);
      log('Error: ${e.toString()}');
    });
  }

  void showInterstitialAd() {
    if (interstitialAd == null) {
      log('Warning: attempt to show interstitial before loaded.');
      return;
    }
    interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) {},
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        ad.dispose();
        buildInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        ad.dispose();
        buildInterstitialAd();
      },
    );
    interstitialAd!.show();
  }

  void buildInterstitialAd() {
    InterstitialAd.load(
      adUnitId: mAdMobInterstitialId,
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          this.interstitialAd = ad;
          log('----------------Loaded------------------');
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  double roundDouble({required double value, int? places}) => ((value * 10).round().toDouble() / 10);

  Widget subscriptionWidget() {
    if (!appStore.isTrailerVideoPlaying) {
      if (movie.userHasAccess.validate()) {
        return VideoContentWidget(
          choice: movie.choice,
          image: movie.image,
          embedContent: movie.embedContent,
          urlLink: movie.urlLink.validate().replaceAll(r'\/', '/'),
          fileLink: movie.file,
          videoId: movie.id.validate().toString(),
          isUserResumeVideo: hasResumeMovie,
          videoDuration: movie.runTime.validate(),
          onMovieCompleted: () {
            if (widget.playList.validate().isNotEmpty) {
              appStore.setLoading(true);
              if (currentIndex > widget.playList.validate().length) {
                currentIndex = 0;
              }
              if (currentIndex < widget.playList.validate().length) {
                currentIndex += 1;
              }

              CommonDataListModel data = widget.playList.validate()[currentIndex];
              movie = MovieData(image: data.image, title: data.title, id: data.id, postType: data.postType);
              appStore.setLoading(false);
              setState(() {});
            } else {
              super.initState();
            }
          },
        );
      } else {
        return PostRestrictionComponent(
          imageUrl: movie.image.validate(),
          isPostRestricted: !movie.userHasAccess.validate(),
          restrictedPlans: restrictedPlans,
          callToRefresh: () {
            init();
            appStore.setTrailerVideoPlayer(true);
          },
        );
      }
    } else {
      return TrailerVideoWidget(
        url: movie.trailerLink,
        image: movie.image.validate(),
      );
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    scrollController.dispose();
    if (appStore.showAds) showInterstitialAd();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    WakelockPlus.disable();
    ScreenProtector.preventScreenshotOff();
    super.dispose();
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
      child: RefreshIndicator(
        onRefresh: () async {
          getDetails();

          getComments(postId: movie.id, page: 1, commentPerPage: postPerPage);
          return await 2.seconds.delay;
        },
        child: SafeArea(
          child: PiPBuilder(
            builder: (statusInfo) {
              return Scaffold(
                resizeToAvoidBottomInset: true,
                appBar: ((statusInfo?.status == PiPStatus.enabled) || (!movie.userHasAccess.validate() || !appStore.isTrailerVideoPlaying))
                    ? null
                    : PreferredSize(
                        preferredSize: Size(context.width(), kToolbarHeight),
                        child: AppBar(
                          systemOverlayStyle: defaultSystemUiOverlayStyle(context),
                          surfaceTintColor: context.scaffoldBackgroundColor,
                          elevation: 0,
                          actions: [
                            if (movie.file.validate().isNotEmpty && movie.userHasAccess.validate())
                              InkWell(
                                onTap: () {
                                  VideoCastDeviceListScreen(
                                    videoURL: movie.urlLink.validate(),
                                    videoTitle: widget.movieData.title.validate(),
                                    videoImage: movie.attachment.validate(),
                                  ).launch(context);
                                },
                                child: Icon(Icons.cast_rounded, color: textSecondaryColor),
                              ).paddingOnly(right: 16),
                          ],
                        ),
                      ),
                body: Stack(
                  children: [
                    if (hasData && !isError)
                      Container(
                        width: context.width(),
                        height: context.height(),
                        child: SingleChildScrollView(
                          physics: appStore.hasInFullScreen ? NeverScrollableScrollPhysics() : ScrollPhysics(),
                          controller: scrollController,
                          padding: EdgeInsets.only(bottom: 30,top: 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              getBoolAsync(HAS_IN_REVIEW)
                                  ? MovieURLWidget(
                                      IN_REVIEW_VIDEO,
                                      title: movie.title,
                                      image: movie.urlLink.getYouTubeThumbnail(),
                                      videoId: movie.id.toString(),
                                      videoDuration: movie.runTime.validate(),
                                      videoCompletedCallback: () {},
                                    )
                                  : subscriptionWidget(),
                              if (statusInfo?.status != PiPStatus.enabled) ...[
                                8.height,
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (movie.censorRating != null && movie.censorRating.validate().isNotEmpty)
                                          Container(
                                            child: Text(
                                              movie.censorRating.validate(),
                                              style: primaryTextStyle(color: Colors.black, size: 12),
                                            ),
                                            padding: EdgeInsets.only(left: 4, right: 4, top: 2, bottom: 2),
                                            decoration: BoxDecoration(color: Colors.white),
                                          ).cornerRadiusWithClipRRect(4).paddingRight(8),
                                        Container(
                                          child: Row(
                                            children: [
                                              Icon(Icons.visibility_outlined, color: Colors.black, size: 12),
                                              4.width,
                                              Text(
                                                '${movie.views.validate()}',
                                                style: primaryTextStyle(size: 12, color: Colors.black),
                                              ),
                                              4.width,
                                              Text(language!.views, style: boldTextStyle(size: 12, color: Colors.black)),
                                            ],
                                          ),
                                          padding: EdgeInsets.only(left: 4, right: 4, top: 2, bottom: 2),
                                          decoration: BoxDecoration(color: Colors.white),
                                        ).cornerRadiusWithClipRRect(4).visible(movie.postType == PostType.VIDEO),
                                        8.width.visible(movie.postType == PostType.VIDEO),
                                        itemSubTitle(
                                          context,
                                          genre,
                                          fontSize: ts_small,
                                          textColor: Colors.grey.shade500,
                                        ).expand().visible(genre.trim().isNotEmpty),
                                      ],
                                    ),
                                    8.height,
                                    Text(
                                      parseHtmlString(movie.title.validate()),
                                      style: primaryTextStyle(size: 30),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    8.height,
                                    movie.imdbRating != null && movie.imdbRating != 0.0
                                        ? Row(
                                            children: [
                                              RatingBarIndicator(
                                                rating: roundDouble(value: movie.imdbRating.toDouble() ?? 0, places: 1),
                                                itemBuilder: (context, index) => Icon(Icons.star, color: colorPrimary),
                                                itemCount: 5,
                                                itemSize: 14.0,
                                                unratedColor: Colors.white12,
                                              ),
                                              4.width,
                                              Text(
                                                '(${roundDouble(value: movie.imdbRating.toDouble() ?? 0, places: 1)})',
                                                style: primaryTextStyle(color: Colors.white, size: 12),
                                              ),
                                            ],
                                          ).visible(movie.postType == PostType.MOVIE)
                                        : SizedBox(),
                                    4.height,
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Text(
                                          movie.runTime.validate(),
                                          style: secondaryTextStyle(size: 12),
                                        ).visible(movie.runTime.validate().isNotEmpty).paddingRight(8),
                                        Text(movie.releaseDate.validate(), style: secondaryTextStyle(size: 12)).visible(movie.releaseDate.validate().isNotEmpty),
                                      ],
                                    ),
                                    20.height,
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (appStore.isTrailerVideoPlaying)
                                          InkWell(
                                            child: Container(
                                              height: 40,
                                              decoration: BoxDecoration(color: colorPrimary, borderRadius: radius(4)),
                                              padding: EdgeInsets.symmetric(vertical: 4),
                                              child: TextIcon(
                                                text: language!.streamNow,
                                                textStyle: boldTextStyle(color: Colors.white),
                                                suffix: Icon(Icons.play_arrow_rounded, size: 20, color: context.iconColor),
                                              ).center(),
                                              margin: EdgeInsets.only(right: 8),
                                            ),
                                            onTap: () {
                                              appStore.setTrailerVideoPlayer(false);
                                              setState(() {});
                                            },
                                          ).expand(),
                                        Container(
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(color: cardColor, borderRadius: radius(4)),
                                          child: Icon(Icons.share_rounded, color: textSecondaryColor, size: 18),
                                        ).onTap(() {
                                          shareMovieOrEpisode(movie.shareUrl.validate());
                                        }).paddingOnly(right: 8),
                                        if (movie.file.validate().isNotEmpty && appStore.isLogging && movie.userHasAccess.validate() && !getBoolAsync(HAS_IN_REVIEW) && !appStore.isTrailerVideoPlaying)
                                          DownloadVideoFromLinkWidget(
                                            videoName: movie.title.validate(),
                                            videoLink: movie.file.validate(),
                                            videoDescription: movie.description.validate(),
                                            videoId: movie.id.validate().toString(),
                                            videoImage: movie.image.validate(),
                                            videoDuration: movie.runTime.validate(),
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
                                                  path: movie.file.validate(),
                                                ),
                                                android: FlPiPAndroidConfig(
                                                  aspectRatio: Rational.maxLandscape(),
                                                  path: movie.file.validate(),
                                                ),
                                              );
                                              setState(() {});
                                            } else {
                                              toast(language?.pipNotAvailable);
                                            }
                                          }).paddingOnly(right: 8),
                                      ],
                                    ).visible(!getBoolAsync(HAS_IN_REVIEW)),
                                    10.height,
                                  ],
                                ).paddingSymmetric(horizontal: 16),
                                if (movie.description.validate().isNotEmpty && movie.userHasAccess.validate() && !getBoolAsync(HAS_IN_REVIEW))
                                  if (movie.description.validate().contains('href') || movie.description.validate().contains('img'))
                                    HtmlWidget(
                                      postContent: movie.description.validate(),
                                      color: textSecondaryColor,
                                      fontSize: 14,
                                    ).paddingSymmetric(horizontal: 16, vertical: 16)
                                  else
                                    ReadMoreText(
                                      parse(movie.description.validate()).body!.text,
                                      style: secondaryTextStyle(),
                                      trimLines: 3,
                                      trimMode: TrimMode.Line,
                                      trimCollapsedText: ' ...${language!.viewMore}',
                                      trimExpandedText: '  ${language!.viewLess}',
                                    ).paddingSymmetric(horizontal: 16, vertical: 16),
                                8.height,
                                MovieDetailLikeWatchListWidget(
                                  postId: movie.id.validate(),
                                  postType: movie.postType!,
                                  isInWatchList: movie.isInWatchList,
                                  isLiked: movie.isLiked.validate(),
                                  likes: movie.likes,
                                  onAction: () {
                                    widget.onRemoveFromPlaylist?.call();
                                    setState(() {});
                                  },
                                ).paddingSymmetric(horizontal: 16),
                                if (showComments && movie.isCommentOpen.validate() && movie.userHasAccess.validate() && !getBoolAsync(HAS_IN_REVIEW))
                                  CommentWidget(
                                    postId: movie.id,
                                    noOfComments: movie.noOfComments,
                                    postType: movie.postType,
                                    comments: movie.comments.validate(),
                                  ).paddingAll(16),
                                Divider(thickness: 0.1, color: Colors.grey.shade500).visible(hasData),
                                if (castCrewHeaderList.isNotEmpty) ...[
                                  16.height,
                                  Wrap(
                                    children: List.generate(
                                      castCrewHeaderList.length,
                                      (index) {
                                        bool isSelected = selectedIndex == index;
                                        selectedData = castCrewHeaderList[selectedIndex];
                                        return Container(
                                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                          decoration: boxDecorationDefault(
                                            color: context.cardColor,
                                            borderRadius: radius(24),
                                            border: Border.all(color: isSelected ? context.primaryColor : Colors.grey.shade800, width: 1),
                                            boxShadow: [],
                                          ),
                                          child: Text(castCrewHeaderList[index].keys.first, style: primaryTextStyle()),
                                        ).onTap(
                                          () {
                                            selectedIndex = index;
                                            selectedData = castCrewHeaderList[selectedIndex];
                                            setState(() {});
                                          },
                                          highlightColor: Colors.transparent,
                                          splashColor: Colors.transparent,
                                        );
                                      },
                                    ),
                                    runSpacing: 16,
                                    spacing: 16,
                                  ).paddingSymmetric(horizontal: 16),
                                  Wrap(
                                    children: selectedData!.values.map((e) {
                                      return HorizontalList(
                                        padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
                                        itemCount: e.length,
                                        itemBuilder: (context, index) {
                                          CommonModelMovieDetail data = e[index];
                                          return Column(
                                            children: [
                                              CachedImageWidget(url: data.image.validate(), fit: BoxFit.cover, width: 70, height: 70).cornerRadiusWithClipRRect(60).paddingOnly(left: 4, right: 4),
                                              4.height,
                                              Text(data.name.validate(), style: primaryTextStyle(), overflow: TextOverflow.ellipsis, maxLines: 1),
                                            ],
                                          ).onTap(() async {
                                            if (!getBoolAsync(HAS_IN_REVIEW) && youtubePlayerController != null) youtubePlayerController!.pause();
                                            await CastDetailScreen(castId: data.id.validate()).launch(context);
                                          }, borderRadius: BorderRadius.circular(defaultRadius), highlightColor: Colors.transparent);
                                        },
                                      );
                                    }).toList(),
                                  ).visible(selectedData != null),
                                ],
                                Divider(thickness: 0.1, color: Colors.grey.shade500).visible(selectedData != null),
                                if (hasData && movie.postType != PostType.TV_SHOW && movie.sourcesList.validate().isNotEmpty && movie.userHasAccess.validate() && !getBoolAsync(HAS_IN_REVIEW))
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        language!.sources,
                                        style: primaryTextStyle(size: 18),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ).paddingOnly(right: 16, left: 16, top: 16),
                                      SourcesDataWidget(
                                        sourceList: movie.sourcesList,
                                        onLinkTap: (sources) async {
                                          if (youtubePlayerController != null) youtubePlayerController!.pause();
                                          LiveStream().emit(PauseVideo);

                                          movie.choice = sources.choice;
                                          if (sources.choice == "movie_url") {
                                            movie.urlLink = sources.link;
                                          } else if (sources.choice == "movie_embed") {
                                            movie.embedContent = sources.embedContent;
                                          }
                                          appStore.setTrailerVideoPlayer(false);
                                          finish(context);
                                          await MovieDetailScreen(movieData: widget.movieData).launch(context);
                                          if (youtubePlayerController != null) youtubePlayerController!.play();
                                        },
                                      ).paddingSymmetric(horizontal: 12, vertical: 16),
                                      Divider(thickness: 0.1, color: Colors.grey.shade500),
                                    ],
                                  ),
                                if (hasData && movie.postType == PostType.TV_SHOW && movie.seasons!.count != null)
                                  SeasonDataWidget(
                                    movieSeason: movie.seasons,
                                    postId: movie.id.validate(),
                                    scrollController: scrollController,
                                    dropdownValue: movie.seasons!.data.validate()[0],
                                  ),
                                if (hasData) UpcomingRelatedMovieListWidget(snap: movieResponse),
                              ]
                            ],
                          ),
                        ),
                      ),
                    Observer(builder: (_) => LoaderWidget().visible(appStore.isLoading)).center(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_flutter/components/cached_image_widget.dart';
import 'package:streamit_flutter/components/loader_widget.dart';
import 'package:streamit_flutter/components/loading_dot_widget.dart';
import 'package:streamit_flutter/main.dart';
import 'package:streamit_flutter/models/notification_model.dart';
import 'package:streamit_flutter/network/rest_apis.dart';
import 'package:streamit_flutter/utils/common.dart';
import 'package:streamit_flutter/utils/constants.dart';
import 'package:streamit_flutter/utils/resources/colors.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<NotificationModel> notificationList = [];
  late Future<List<NotificationModel>> future;

  int mPage = 1;
  bool mIsLastPage = false;
  bool isError = false;

  @override
  void initState() {
    future = getList();

    setStatusBarColor(Colors.transparent);
    super.initState();
  }

  Future<List<NotificationModel>> getList() async {
    appStore.setLoading(true);

    await getNotifications(page: mPage).then((value) {
      if (mPage == 1) notificationList.clear();

      mIsLastPage = value.length != postPerPage;
      notificationList.addAll(value);
      setState(() {});

      appStore.setLoading(false);
    }).catchError((e) {
      isError = true;
      setState(() {});
      appStore.setLoading(false);
      toast(e.toString(), print: true);
    });

    return notificationList;
  }

  Future<void> clear() async {
    appStore.setLoading(true);
    await clearNotification().then((value) {
      notificationList.clear();

      setState(() {});

      appStore.setLoading(false);
    }).catchError((e) {
      isError = true;
      setState(() {});
      appStore.setLoading(false);
      toast(e.toString(), print: true);
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    appStore.setLoading(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget(
        language!.notifications,
        elevation: 0,
        color: Theme.of(context).cardColor,
        textColor: Colors.white,
        textSize: 22,
        actions: [
          IconButton(
            onPressed: () async {
              await showConfirmDialogCustom(
                context,
                primaryColor: colorPrimary,
                cancelable: false,
                dialogType: DialogType.DELETE,
                positiveText: language!.clear,
                title: language!.clearNotificationConfirmation,
                onAccept: (_) async {
                  finish(context);
                  clear();
                },
              );
            },
            icon: Icon(Icons.delete_outline, color: context.primaryColor),
          )
        ],
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          FutureBuilder<List<NotificationModel>>(
            future: future,
            builder: (ctx, snap) {
              if (snap.hasError) {
                return NoDataWidget(
                  imageWidget: noDataImage(),
                  title: language!.somethingWentWrong,
                ).center();
              }

              if (snap.hasData) {
                if (snap.data.validate().isEmpty) {
                  return NoDataWidget(
                    imageWidget: noDataImage(),
                    title: language!.noNotificationsFound,
                  ).center();
                } else {
                  return AnimatedListView(
                    shrinkWrap: true,
                    slideConfiguration: SlideConfiguration(delay: 80.milliseconds, verticalOffset: 300),
                    physics: AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(bottom: 50),
                    itemCount: notificationList.length,
                    itemBuilder: (context, index) {
                      NotificationModel notification = notificationList[index];

                      return ColoredBox(
                        color: notification.isSeen == 0 ? search_edittext_color : context.scaffoldBackgroundColor,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CachedImageWidget(
                              url: notification.src.validate(),
                              height: 80,
                              width: 120,
                              fit: BoxFit.cover,
                            ).cornerRadiusWithClipRRect(defaultRadius),
                            20.width,
                            Column(
                              children: [
                                Text(
                                  parseHtmlString(notification.title.validate()),
                                  style: primaryTextStyle(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(notification.runTime.validate(), style: secondaryTextStyle()),
                              ],
                              crossAxisAlignment: CrossAxisAlignment.start,
                            ).expand(),
                          ],
                        ).paddingSymmetric(vertical: 8, horizontal: 16),
                      );
                    },
                    onNextPage: () {
                      if (!mIsLastPage) {
                        mPage++;
                        future = getList();
                      }
                    },
                  );
                }
              }
              return Offstage();
            },
          ),
          Observer(
            builder: (_) {
              if (mPage == 1) {
                return LoaderWidget().center().visible(appStore.isLoading);
              } else {
                return Positioned(
                  left: 0,
                  right: 0,
                  bottom: 16,
                  child: LoadingDotsWidget(),
                ).visible(appStore.isLoading);
              }
            },
          ),
        ],
      ),
    );
  }
}

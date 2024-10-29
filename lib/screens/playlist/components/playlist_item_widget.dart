import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_flutter/components/loader_widget.dart';
import 'package:streamit_flutter/components/splash_widget.dart';
import 'package:streamit_flutter/main.dart';
import 'package:streamit_flutter/models/playlist_model.dart';
import 'package:streamit_flutter/network/rest_apis.dart';
import 'package:streamit_flutter/screens/playlist/screens/playlist_medialist_screen.dart';
import 'package:streamit_flutter/utils/common.dart';
import 'package:streamit_flutter/utils/constants.dart';
import 'package:streamit_flutter/utils/resources/colors.dart';
import 'package:streamit_flutter/utils/resources/images.dart';

class PlayListItemWidget extends StatefulWidget {
  final String playlistType;
  final VoidCallback? onPlaylistDelete;

  const PlayListItemWidget({Key? key, required this.playlistType, this.onPlaylistDelete}) : super(key: key);

  @override
  State<PlayListItemWidget> createState() => _PlayListItemWidgetState();
}

class _PlayListItemWidgetState extends State<PlayListItemWidget> {
  final _form = GlobalKey<FormState>();
  TextEditingController _playlistTitleController = TextEditingController();

  String noDataTitle = '';

  @override
  void initState() {
    super.initState();

    if (widget.playlistType == playlistMovie) {
      noDataTitle = language!.movies;
    } else if (widget.playlistType == playlistTvShows) {
      noDataTitle = language!.tVShows;
    } else {
      noDataTitle = language!.videos;
    }
    setState(() {});
  }

  void removePlaylist(BuildContext context, {required int playlistId}) async {
    Map req = {
      "id": playlistId,
      "action": "delete",
    };
    appStore.setLoading(true);
    await deletePlaylist(request: req,type: widget.playlistType).then((value) {
      widget.onPlaylistDelete?.call();
      appStore.setLoading(false);
      toast(value.message);
      finish(context);
    }).catchError((e) {
      appStore.setLoading(false);
      toast(language!.somethingWentWrong);
      log("===>>>>>Delete Playlist Error : ${e.toString()}");
    });
  }

  void editPlaylist(BuildContext context, {required int playlistId, required String postType}) async {
    Map req = {
      "id": playlistId,
      "title": _playlistTitleController.text.trim(),
      "post_type": postType,
    };
    hideKeyboard(context);
    appStore.setLoading(true);
    await createOrEditPlaylist(request: req,type: widget.playlistType).then((value) {
      widget.onPlaylistDelete?.call();
      appStore.setLoading(false);
      toast(value.message);
      finish(context);
    }).catchError((e) {
      appStore.setLoading(false);
      toast(language!.somethingWentWrong);
      log("===>>>>>Delete Playlist Error : ${e.toString()}");
    });
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PlaylistModel>>(
      future: getPlayListByType(type: widget.playlistType),
      builder: (ctx, snap) {
        if (snap.hasData) {
          if (snap.data!.validate().isNotEmpty) {
            return AnimatedListView(
              itemCount: snap.data!.length,
              padding: EdgeInsets.all(8),
              itemBuilder: (ctxx, index) {
                PlaylistModel _playlistItem = snap.data.validate()[index];

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SplashWidget(
                    borderRadius: 8,
                    backgroundColor: context.scaffoldBackgroundColor,
                    hasShadow: true,
                    padding: EdgeInsets.only(left: 16, right: 0),
                    onTap: () {
                      PlaylistMediaScreen(
                        playlistTitle: _playlistItem.postTitle,
                        playlistId: _playlistItem.iD,
                        playlistType: _playlistItem.postType,
                      ).launch(context);
                    },
                    child: Row(
                      children: [
                        Image.asset(
                          ic_playlist,
                          height: 24,
                          width: 24,
                          color: colorPrimary,
                        ),
                        16.width,
                        Text(_playlistItem.postTitle.validate(), style: primaryTextStyle(weight: FontWeight.w100)).expand(),
                        IconButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              backgroundColor: Colors.transparent,
                              builder: (bottomSheetContext) {
                                return Container(
                                  margin: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF202020),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: AnimatedPadding(
                                    duration: Duration(milliseconds: 350),
                                    padding: EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Align(
                                          alignment: Alignment.center,
                                          child: Container(
                                            width: 30,
                                            height: 3,
                                            decoration: BoxDecoration(
                                              color: Color(0xFFA8A8A8),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                          ),
                                        ),
                                        24.height,
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Image.asset(
                                              ic_playlist,
                                              height: 32,
                                              width: 32,
                                              color: colorPrimary,
                                            ),
                                            16.width,
                                            Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _playlistItem.postTitle,
                                                  style: primaryTextStyle(size: 22),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                8.height,
                                                Text(
                                                  DateFormat(dateFormatPmp).format(DateTime.parse(_playlistItem.postDate)),
                                                  style: secondaryTextStyle(size: 16),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                        16.height,
                                        Divider(color: Color(0xFFA8A8A8)),
                                        16.height,
                                        InkWell(
                                          onTap: () {
                                            finish(bottomSheetContext);
                                            _playlistTitleController.text = _playlistItem.postTitle;
                                            showDialog(
                                              context: context,
                                              builder: (dialogContext) {
                                                return Dialog(
                                                  child: Form(
                                                    key: _form,
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Text("${language!.edit} ${_playlistItem.postTitle}", style: primaryTextStyle(size: 22)),
                                                        16.height,
                                                        AppTextField(
                                                          controller: _playlistTitleController,
                                                          textFieldType: TextFieldType.NAME,
                                                          decoration: InputDecoration(
                                                            hintText: "E.g. Coffee Break",
                                                            labelText: language!.playlistTitle,
                                                            labelStyle: primaryTextStyle(color: Color(0xFFA8A8A8)),
                                                            hintStyle: primaryTextStyle(color: Color(0xFF484848)),
                                                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF696969))),
                                                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF696969))),
                                                            errorBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF696969))),
                                                            border: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF696969))),
                                                          ),
                                                          validator: (val) {
                                                            if (val.validate().isEmpty) return language!.thisFieldIsRequired;
                                                            return null;
                                                          },
                                                        ),
                                                        24.height,
                                                        Observer(
                                                          builder: (_) {
                                                            return appStore.isLoading
                                                                ? CircularProgressIndicator(strokeWidth: 2).center()
                                                                : Align(
                                                                    alignment: Alignment.centerRight,
                                                                    child: Row(
                                                                      mainAxisSize: MainAxisSize.min,
                                                                      children: [
                                                                        TextButton(
                                                                          style: ButtonStyle(
                                                                            shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                                                                          ),
                                                                          onPressed: () {
                                                                            finish(dialogContext);
                                                                          },
                                                                          child: Text(language!.cancel, style: primaryTextStyle()),
                                                                        ),
                                                                        16.width,
                                                                        TextButton(
                                                                          style: ButtonStyle(
                                                                            backgroundColor: MaterialStateProperty.all(colorPrimary),
                                                                            shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                                                                          ),
                                                                          onPressed: () {
                                                                            editPlaylist(dialogContext, playlistId: _playlistItem.iD, postType: _playlistItem.postType);
                                                                          },
                                                                          child: Text(language!.edit, style: primaryTextStyle(color: Colors.white)),
                                                                        )
                                                                      ],
                                                                    ),
                                                                  );
                                                          },
                                                        ),
                                                      ],
                                                    ).paddingAll(16),
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit_rounded, color: Color(0xFFA8A8A8)),
                                              16.width,
                                              Text(
                                                language!.editPlaylist,
                                                style: primaryTextStyle(size: 18, color: Color(0xFFA8A8A8)),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ).expand(),
                                            ],
                                          ).paddingAll(8),
                                        ),
                                        16.height,
                                        InkWell(
                                          onTap: () {
                                            finish(bottomSheetContext);
                                            showDialog(
                                              context: context,
                                              builder: (dialogContext) {
                                                return Dialog(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Text("${language!.delete} ${_playlistItem.postTitle}", style: primaryTextStyle(size: 22)),
                                                      16.height,
                                                      Text("${language!.areYouSureYouWantToDelete} ${_playlistItem.postTitle}?", style: primaryTextStyle()),
                                                      24.height,
                                                      Observer(
                                                        builder: (_) {
                                                          return appStore.isLoading
                                                              ? CircularProgressIndicator(strokeWidth: 2).center()
                                                              : Align(
                                                                  alignment: Alignment.centerRight,
                                                                  child: Row(
                                                                    mainAxisSize: MainAxisSize.min,
                                                                    children: [
                                                                      TextButton(
                                                                        style: ButtonStyle(
                                                                          shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                                                                        ),
                                                                        onPressed: () {
                                                                          finish(dialogContext);
                                                                        },
                                                                        child: Text(language!.cancel, style: primaryTextStyle()),
                                                                      ),
                                                                      16.width,
                                                                      TextButton(
                                                                        style: ButtonStyle(
                                                                          backgroundColor: MaterialStateProperty.all(colorPrimary),
                                                                          shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                                                                        ),
                                                                        onPressed: () {
                                                                          removePlaylist(dialogContext, playlistId: _playlistItem.iD);
                                                                        },
                                                                        child: Text(language!.delete, style: primaryTextStyle(color: Colors.white)),
                                                                      )
                                                                    ],
                                                                  ),
                                                                );
                                                        },
                                                      ),
                                                    ],
                                                  ).paddingAll(16),
                                                );
                                              },
                                            );
                                          },
                                          child: Row(
                                            children: [
                                              Icon(Icons.close_rounded, color: Color(0xFFA8A8A8)),
                                              16.width,
                                              Text(
                                                language!.deletePlaylist,
                                                style: primaryTextStyle(size: 18, color: Color(0xFFA8A8A8)),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ).expand(),
                                            ],
                                          ).paddingAll(8),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          icon: Icon(Icons.more_vert, color: context.iconColor),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } else {
            return NoDataWidget(
              imageWidget: noDataImage(),
              title: '${language!.noPlaylistsFoundFor} $noDataTitle',
              subTitle: '${language!.createPlaylistAndAdd} $noDataTitle',
            );
          }
        } else if (snap.hasError) {
          return NoDataWidget(
            imageWidget: noDataImage(),
            title: language!.somethingWentWrong,
          ).center();
        }
        return LoaderWidget();
      },
    );
  }
}

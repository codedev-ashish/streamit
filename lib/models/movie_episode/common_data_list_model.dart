import 'package:streamit_flutter/models/resume_video_model.dart';
import 'package:streamit_flutter/utils/constants.dart';

class CommonDataListModel {
  int? id;
  String? title;
  String? image;
  PostType? postType;
  String? characterName;
  String? releaseYear;
  String? shareUrl;
  String? runTime;
  ContinueWatchModel? watchedDuration;
  String? trailerLink;
  String? attachment;
  String? releaseDate;

  CommonDataListModel({
    this.id,
    this.title,
    this.image,
    this.postType,
    this.characterName,
    this.releaseYear,
    this.shareUrl,
    this.runTime,
    this.watchedDuration,
    this.trailerLink,
    this.attachment,
    this.releaseDate,
  });

  factory CommonDataListModel.fromJson(Map<String, dynamic> json) {
    return CommonDataListModel(
      id: json['id'],
      title: json['title'],
      image: json['image'],
      postType: json['post_type'] != null
          ? json['post_type'] == 'movie'
              ? PostType.MOVIE
              : json['post_type'] == 'episode'
                  ? PostType.EPISODE
                  : json['post_type'] == 'tv_show'
                      ? PostType.TV_SHOW
                      : json['post_type'] == 'video'
                          ? PostType.VIDEO
                          : PostType.NONE
          : PostType.NONE,
      characterName: json['character_name'],
      releaseYear: json['release_year'],
      shareUrl: json['share_url'],
      runTime: json['run_time'],
      watchedDuration: json['watched_duration'] != null ? ContinueWatchModel.fromJson(json['watched_duration']) : null,
      trailerLink: json['trailer_link'],
      attachment: json['attachment'],
      releaseDate: json['release_date'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['title'] = this.title;
    data['image'] = this.image;
    data['postType'] = this.postType.toString();
    data['character_name'] = this.characterName;
    data['release_year'] = this.releaseYear;
    data['share_url'] = this.shareUrl;
    data['run_time'] = this.runTime;
    if (this.watchedDuration != null) {
      data['watched_duration'] = this.watchedDuration!.toJson();
    }
    data['trailer_link'] = this.trailerLink;
    data['attachment'] = this.attachment;
    data['release_date'] = this.releaseDate;

    return data;
  }
}

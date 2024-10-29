import 'package:streamit_flutter/models/movie_episode/common_data_list_model.dart';

class ViewAllResponse {
  List<CommonDataListModel>? data;
  String? title;

  ViewAllResponse({this.data, this.title});

  factory ViewAllResponse.fromJson(Map<String, dynamic> json) {
    return ViewAllResponse(
      data: json['data'] != null ? (json['data'] as List).map((i) => CommonDataListModel.fromJson(i)).toList() : null,
      title: json['title'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['title'] = this.title;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class FirebaseNotificationModel {
  String? notificationId;
  String? templateId;
  String? templateName;
  String? sound;
  String? title;
  String? body;
  String? launchUrl;
  Map<String, dynamic>? additionalData;
  Map<String, dynamic>? attachments;
  bool? contentAvailable;
  bool? mutableContent;
  String? category;
  int? badge;
  int? badgeIncrement;
  String? subtitle;
  double? relevanceScore;
  String? interruptionLevel;
  int? androidNotificationId;
  String? smallIcon;
  String? largeIcon;
  String? bigPicture;
  String? smallIconAccentColor;
  String? ledColor;
  int? lockScreenVisibility;
  String? groupKey;
  String? groupMessage;
  String? fromProjectNumber;
  String? collapseId;
  int? priority;

  FirebaseNotificationModel.fromJson(Map<String, dynamic> json) {
    this.notificationId = json['notificationId'] as String;
    if (json.containsKey('contentAvailable')) this.contentAvailable = json['contentAvailable'] as bool?;
    if (json.containsKey('mutableContent')) this.mutableContent = json['mutableContent'] as bool?;
    if (json.containsKey('category')) this.category = json['category'] as String?;
    if (json.containsKey('badge')) this.badge = json['badge'] as int?;
    if (json.containsKey('badgeIncrement')) this.badgeIncrement = json['badgeIncrement'] as int?;
    if (json.containsKey('subtitle')) this.subtitle = json['subtitle'] as String?;
    if (json.containsKey('attachments')) this.attachments = json['attachments'].cast<String, dynamic>();
    if (json.containsKey('relevanceScore')) this.relevanceScore = json['relevanceScore'] as double?;
    if (json.containsKey('interruptionLevel')) this.interruptionLevel = json['interruptionLevel'] as String?;

    // Android Specific Parameters
    if (json.containsKey("smallIcon")) this.smallIcon = json['smallIcon'] as String?;
    if (json.containsKey("largeIcon")) this.largeIcon = json['largeIcon'] as String?;
    if (json.containsKey("bigPicture")) this.bigPicture = json['bigPicture'] as String?;
    if (json.containsKey("smallIconAccentColor")) this.smallIconAccentColor = json['smallIconAccentColor'] as String?;
    if (json.containsKey("ledColor")) this.ledColor = json['ledColor'] as String?;
    if (json.containsKey("lockScreenVisibility")) this.lockScreenVisibility = json['lockScreenVisibility'] as int?;
    if (json.containsKey("groupMessage")) this.groupMessage = json['groupMessage'] as String?;
    if (json.containsKey("groupKey")) this.groupKey = json['groupKey'] as String?;
    if (json.containsKey("fromProjectNumber")) this.fromProjectNumber = json['fromProjectNumber'] as String?;
    if (json.containsKey("collapseId")) this.collapseId = json['collapseId'] as String?;
    if (json.containsKey("priority")) this.priority = json['priority'] as int?;
    if (json.containsKey("androidNotificationId")) this.androidNotificationId = json['androidNotificationId'] as int?;
    this.notificationId = json['notificationId'] as String;

    if (json.containsKey('templateName')) this.templateName = json['templateName'] as String?;
    if (json.containsKey('templateId')) this.templateId = json['templateId'] as String?;
    if (json.containsKey('sound')) this.sound = json['sound'] as String?;
    if (json.containsKey('title')) this.title = json['title'] as String?;
    if (json.containsKey('body')) this.body = json['body'] as String?;
    if (json.containsKey('launchUrl')) this.launchUrl = json['launchUrl'] as String?;
    if (json.containsKey('additionalData')) this.additionalData = json['additionalData'].cast<String, dynamic>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();

    data['notificationId'] = this.notificationId;
    data['contentAvailable'] = this.contentAvailable;
    data['mutableContent'] = this.mutableContent;
    data['category'] = this.category;
    data['badge'] = this.badge;
    data['badgeIncrement'] = this.badgeIncrement;
    data['subtitle'] = this.subtitle;
    data['attachments'] = this.attachments;
    data['relevanceScore'] = this.relevanceScore;
    data['interruptionLevel'] = this.interruptionLevel;

    // Android Specific Parameters
    data['smallIcon'] = this.smallIcon;
    data['largeIcon'] = this.largeIcon;
    data['bigPicture'] = this.bigPicture;
    data['smallIconAccentColor'] = this.smallIconAccentColor;
    data['ledColor'] = this.ledColor;
    data['lockScreenVisibility'] = this.lockScreenVisibility;
    data['groupMessage'] = this.groupMessage;
    data['groupKey'] = this.groupKey;
    data['fromProjectNumber'] = this.fromProjectNumber;
    data['collapseId'] = this.collapseId;
    data['priority'] = this.priority;
    data['androidNotificationId'] = this.androidNotificationId;

    data['templateName'] = this.templateName;
    data['templateId'] = this.templateId;
    data['sound'] = this.sound;
    data['title'] = this.title;
    data['body'] = this.body;
    data['launchUrl'] = this.launchUrl;
    data['additionalData'] = this.additionalData;

    return data;
  }
}
class NotificationModel {
  NotificationModel({
    this.postId,
    this.postType,
    this.title,
    this.runTime,
    this.src,
    this.isSeen,
  });

  NotificationModel.fromJson(dynamic json) {
    postId = json['post_id'];
    postType = json['post_type'];
    title = json['title'];
    runTime = json['run_time'];
    src = json['src'];
    isSeen = json['is_seen'];
  }
  int? postId;
  String? postType;
  String? title;
  String? runTime;
  String? src;
  bool? isSeen;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['post_id'] = postId;
    map['post_type'] = postType;
    map['title'] = title;
    map['run_time'] = runTime;
    map['src'] = src;
    map['is_seen'] = isSeen;
    return map;
  }
}

class NotificationCount {
  NotificationCount({this.totalNotificationCount});

  NotificationCount.fromJson(dynamic json) {
    totalNotificationCount = json['total_notification_count'];
  }
  int? totalNotificationCount;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['total_notification_count'] = totalNotificationCount;
    return map;
  }
}

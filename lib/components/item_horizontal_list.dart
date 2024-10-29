import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_flutter/components/common_list_item_component.dart';
import 'package:streamit_flutter/main.dart';
import 'package:streamit_flutter/models/movie_episode/common_data_list_model.dart';
import 'package:streamit_flutter/network/rest_apis.dart';

// ignore: must_be_immutable
class ItemHorizontalList extends StatefulWidget {
  List<CommonDataListModel> list = [];
  EdgeInsets? padding;
  bool isContinueWatch = false;
  final VoidCallback? onListEmpty;
  final bool isTop10;

  ItemHorizontalList(this.list, {this.isContinueWatch = false, this.onListEmpty, this.padding, this.isTop10 = false});

  @override
  _ItemHorizontalListState createState() => _ItemHorizontalListState();
}

class _ItemHorizontalListState extends State<ItemHorizontalList> {
  @override
  Widget build(BuildContext context) {
    return HorizontalList(
      itemCount: widget.list.length,
      padding: widget.padding ?? EdgeInsets.symmetric(horizontal: 8),
      itemBuilder: (context, index) {
        CommonDataListModel data = widget.list[index];
        return Stack(
          children: [
            CommonListItemComponent(
              data: data,
              isLandscape: widget.isContinueWatch,
              isContinueWatch: widget.isContinueWatch,
              callback: () {
                deleteVideoContinueWatch(postId: data.id.validate()).then((value) {
                  appStore.removeFromWatchContinue(appStore.continueWatchList.firstWhere((element) => element.postId.toInt() == data.id.validate()));
                }).catchError(onError);
                widget.list.removeAt(index);
                if (widget.list.isEmpty) widget.onListEmpty?.call();
                setState(() {});
              },
            ),
            if (widget.isTop10.validate())
              Positioned(
                top: - 5,
                right: 4,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(fontSize: 50, color: Colors.white, fontWeight: FontWeight.w900),
                ),
              )
          ],
        );
      },
    );
  }
}

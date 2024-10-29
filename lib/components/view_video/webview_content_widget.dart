import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_flutter/main.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewContentWidget extends StatefulWidget {
  final Uri uri;
  const WebViewContentWidget({required this.uri});

  @override
  State<WebViewContentWidget> createState() => _WebViewContentWidgetState();
}

class _WebViewContentWidgetState extends State<WebViewContentWidget> with AutomaticKeepAliveClientMixin {
  WebViewController? _webViewController;
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  void _loadContent() {
    _webViewController = WebViewController()
      ..setBackgroundColor(Colors.black)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(widget.uri);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SizedBox(
      width: context.width(),
      height: appStore.hasInFullScreen ? context.height() - context.statusBarHeight : context.height() * 0.3,
      child: _webViewController != null ? WebViewWidget(controller: _webViewController!) : Loader(),
    );
  }
}

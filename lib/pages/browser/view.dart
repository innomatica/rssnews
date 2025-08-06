import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../shared/constant.dart';
import 'model.dart';

class BrowserView extends StatefulWidget {
  final String? query;
  final BrowserViewModel model;
  const BrowserView({super.key, required this.model, this.query});

  @override
  State<BrowserView> createState() => _BrowserViewState();
}

const isRSS =
    "document.contentType === 'application/xml' && "
    "document.querySelector('rss > channel > title').innerHTML != null &&"
    "document.querySelector('channel > item > title').innerHTML != null";

class _BrowserViewState extends State<BrowserView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          // onNavigationRequest: (request) async {
          //   _log.fine('onNavReq: $request');
          //   widget.model.fetchFeed(request.url);
          //   return NavigationDecision.navigate;
          // },
          onPageFinished: (url) async {
            // await _checkPage(url);
            if (await _controller.runJavaScriptReturningResult(isRSS) == true) {
              widget.model.fetchFeed(url);
            }
          },
        ),
      );
    // ..loadRequest(Uri.parse(defaultSearchEngineUrl));
    _load();
  }

  Future _load() async {
    if (widget.query?.startsWith('http') == true) {
      // directl URL entry for rss page
      _controller.loadRequest(Uri.parse(widget.query ?? defaultQueryUrl));
    } else {
      // keywords for search engine consumption
      final url = await widget.model.getSearchEngineUrl();
      _controller.loadRequest(Uri.parse(url + (widget.query ?? '')));
    }
  }

  final javaScript =
      "document.contentType === 'application/xml' && "
      "document.querySelector('rss > channel > title').innerHTML != null &&"
      "document.querySelector('channel > item > title').innerHTML != null";

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.model,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            leadingWidth: 100,
            leading: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.keyboard_double_arrow_left_outlined),
                  // onPressed: () => context.pop(),
                  onPressed: () => context.go('/subscribed'),
                ),
                IconButton(
                  icon: Icon(Icons.keyboard_arrow_left_rounded),
                  onPressed: () async {
                    if (await _controller.canGoBack()) {
                      _controller.goBack();
                    } else {
                      // ignore: use_build_context_synchronously
                      context.pop();
                    }
                  },
                ),
              ],
            ),
            title: Text('Browse to the RSS page'),
          ),
          body: WebViewWidget(controller: _controller),
          floatingActionButton: widget.model.found
              ? FloatingActionButton.extended(
                  onPressed: () async => await widget.model.subscribe(),
                  label: widget.model.subscribed == false
                      ? Text('Subscribe')
                      : widget.model.subscribed == true
                      ? Text('Subscribed')
                      : Text('Subscription failed'),
                )
              : null,
        );
      },
    );
  }
}

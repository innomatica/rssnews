import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rssnews/shared/widgets.dart';

import 'model.dart';

enum SearchEngine { brave, duckduckgo, ecosia, google }

extension SearchEngineExt on SearchEngine {
  String get url {
    switch (this) {
      case SearchEngine.brave:
        return "https://search.brave.com/search?q=";
      case SearchEngine.duckduckgo:
        return "https://duckduckgo.com/?q=";
      case SearchEngine.ecosia:
        return "https://ecosia.org/search?q=";
      case SearchEngine.google:
        return "https://www.google.com/search?q=";
    }
  }
}

class SubscribedView extends StatelessWidget {
  final SubscribedViewModel model;
  const SubscribedView({super.key, required this.model});

  Widget buildBody(BuildContext context) {
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        return model.channels.isNotEmpty
            ? ListView.builder(
                itemCount: model.channels.length,
                itemBuilder: (context, index) {
                  final channel = model.channels[index];
                  return Card(
                    child: ListTile(
                      // favicon
                      leading: ChannelImage(channel, width: 56, height: 56),
                      // channel title
                      title: Text(
                        channel.title ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // labels
                      subtitle: Text(
                        // channel.subtitle ?? channel.description ?? "",
                        channel.labels
                                ?.map((e) => model.labels[e - 1].title)
                                .join(" ,") ??
                            "",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () =>
                          context.go('/subscribed/channel/${channel.id}'),
                    ),
                  );
                },
              )
            : Center(
                child: Opacity(
                  opacity: 0.3,
                  child: Icon(Icons.subscriptions_rounded, size: 180),
                ),
              );
      },
    );
  }

  void _handleSearch(BuildContext context, String keyword, SearchEngine e) {
    if (keyword.isNotEmpty) {
      String url = "";
      if (keyword.contains("/")) {
        // direct url to the rss page
        url = keyword.startsWith('http') ? keyword : 'https://$keyword';
      } else {
        // query params for search
        final q = Uri.encodeQueryComponent('$keyword rss feed');
        url = '${e.url}$q';
      }
      context.push(
        Uri(path: '/browser', queryParameters: {"url": url}).toString(),
      );
      Navigator.pop(context);
    }
  }

  void _showModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final iconColor = Theme.of(context).colorScheme.tertiary;
        String keyword = '';
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 8.0,
            children: [
              // secure max width for the dialog
              SizedBox(width: double.maxFinite),
              // search web
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 0),
                title: Row(
                  spacing: 16.0,
                  children: [
                    Icon(Icons.search_rounded, color: iconColor),
                    Text('Search Web by Keyword / URL'),
                  ],
                ),
                subtitle: TextField(
                  decoration: InputDecoration(
                    suffix: MenuAnchor(
                      menuChildren: SearchEngine.values.map((e) {
                        return MenuItemButton(
                          child: Text(e.name),
                          onPressed: () {
                            _handleSearch(context, keyword, e);
                          },
                        );
                      }).toList(),
                      builder: (context, controller, _) {
                        return IconButton(
                          icon: Icon(Icons.check),
                          onPressed: () {
                            controller.isOpen
                                ? controller.close()
                                : controller.open();
                          },
                        );
                      },
                    ),
                  ),
                  onChanged: (value) => keyword = value,
                ),
              ),
              // curated list
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 0),
                title: Row(
                  spacing: 8.0,
                  children: [
                    Icon(Icons.list_rounded, color: iconColor),
                    Text('Choose from Curated List'),
                  ],
                ),
                subtitle: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Text('RssNews Favorite Feeds')],
                ),
                onTap: () {
                  context.go('/subscribed/curated');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            context.go('/');
          },
          icon: Icon(Icons.keyboard_arrow_left_rounded),
        ),
        title: Text('Channels'),
      ),
      body: buildBody(context),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _showModal(context),
      ),
    );
  }
}

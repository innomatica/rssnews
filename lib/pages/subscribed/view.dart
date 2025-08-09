import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets.dart' show FutureImage;
import 'model.dart';

class SubscribedView extends StatelessWidget {
  final SubscribedViewModel model;
  const SubscribedView({super.key, required this.model});

  Widget buildBody(BuildContext context) {
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        return ListView.builder(
          itemCount: model.channels.length,
          itemBuilder: (context, index) {
            final channel = model.channels[index];
            return Card(
              child: ListTile(
                leading: FutureImage(
                  future: model.getChannelImage(channel),
                  width: 60,
                  height: 60,
                ),

                title: Text(
                  channel.title ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  channel.description ?? channel.subtitle ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => context.go('/subscribed/channel/${channel.id}'),
              ),
            );
          },

          // }  model.channels.map((e) {
          //   return GestureDetector(
          //     onTap: () {
          //       context.go('/subscribed/channel/${e.id}');
          //     },
          //     child: GridTile(
          //       child: Column(
          //         mainAxisAlignment: MainAxisAlignment.spaceAround,
          //         children: [
          //           FutureImage(
          //             future: model.getChannelImage(e),
          //             width: 100,
          //             height: 100,
          //           ),
          //           Padding(
          //             padding: const EdgeInsets.symmetric(horizontal: .0),
          //             child: Text(
          //               e.title ?? '',
          //               maxLines: 1,
          //               overflow: TextOverflow.ellipsis,
          //             ),
          //           ),
          //         ],
          //       ),
          //     ),
          //   );
          // }).toList(),
        );
      },
    );
  }

  void showModal(BuildContext context) {
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
              // SizedBox(width: double.maxFinite),
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 0),
                title: Row(
                  spacing: 16.0,
                  children: [
                    Icon(Icons.search_rounded, color: iconColor),
                    Text('Search by Keyword / URL'),
                  ],
                ),
                subtitle: TextField(
                  decoration: InputDecoration(
                    suffix: IconButton(
                      icon: Icon(Icons.check_rounded),
                      onPressed: () {
                        debugPrint('keyword:$keyword');
                        if (keyword.isNotEmpty) {
                          if (keyword.contains("/")) {
                            // assume direct url to the rss page
                            if (!keyword.startsWith("http")) {
                              // assume https
                              keyword = "https://$keyword";
                            }
                          } else {
                            // assue query params for search
                            // keyword = keyword.replaceAll(' ', '+');
                          }
                          context.push(
                            Uri(
                              path: '/browser',
                              queryParameters: {"query": keyword},
                            ).toString(),
                          );
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                  onChanged: (value) => keyword = value,
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 0),
                title: Row(
                  spacing: 8.0,
                  children: [
                    Icon(Icons.list_rounded, color: iconColor),
                    Text('Choose from Curated List'),
                  ],
                ),
                subtitle: Text('Selected Feeds by RssNews'),
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
        onPressed: () => showModal(context),
      ),
    );
  }
}

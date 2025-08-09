import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rssnews/shared/helpers.dart';
import 'package:url_launcher/url_launcher.dart' show launchUrl;

import '../../shared/constant.dart';
import '../../shared/widgets.dart';
import 'model.dart';

class HomeView extends StatelessWidget {
  final HomeViewModel model;
  const HomeView({super.key, required this.model});

  Widget buildBody(BuildContext context) {
    final aspectRatio = MediaQuery.sizeOf(context).aspectRatio;
    final channelTextStyle = TextStyle(
      fontSize: 12,
      color: Theme.of(context).colorScheme.secondary,
    );
    final titleTextStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w700);
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        print('model.withImage:${model.withImage}');
        return ListView.separated(
          itemCount: model.episodes.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final episode = model.episodes[index];
            // print('episode: $episode');
            return ListTile(
              title: aspectRatio < 1.0
                  // portrait
                  ? Column(
                      spacing: 8.0,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // top row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Row(
                                spacing: 8.0,
                                children: [
                                  FutureImage(
                                    future: model.getChannelImage(episode),
                                    width: 16,
                                    height: 16,
                                  ),
                                  Flexible(
                                    child: Text(
                                      episode.channelTitle ?? "",
                                      overflow: TextOverflow.ellipsis,
                                      style: channelTextStyle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              mmddHHMM(episode.published),
                              style: channelTextStyle,
                            ),
                          ],
                        ),
                        // image
                        episode.imageUrl != null && model.withImage
                            ? Image.network(
                                episode.imageUrl!,
                                height: 180,
                                width: double.maxFinite,
                                fit: BoxFit.cover,
                              )
                            : SizedBox(),
                        // title
                        Text(
                          episode.title ?? '',
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: titleTextStyle,
                        ),
                      ],
                    )
                  // landscape
                  : Row(
                      spacing: 8.0,
                      children: [
                        // image
                        episode.imageUrl != null && model.withImage
                            ? Image.network(
                                episode.imageUrl!,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                              )
                            : SizedBox(width: 0, height: 0),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // icon, channel, date
                            Row(
                              spacing: 24,
                              children: [
                                Row(
                                  spacing: 8.0,
                                  children: [
                                    FutureImage(
                                      future: model.getChannelImage(episode),
                                      width: 16,
                                      height: 16,
                                    ),
                                    Text(
                                      episode.channelTitle ?? "",
                                      style: channelTextStyle,
                                    ),
                                  ],
                                ),
                                Text(
                                  mmddHHMM(episode.published),
                                  style: channelTextStyle,
                                ),
                              ],
                            ),
                            // episode title
                            // FIXME: this can overflow
                            Text(
                              episode.title ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: titleTextStyle,
                            ),
                          ],
                        ),
                      ],
                    ),
              onTap: () {
                if (episode.link != null) {
                  launchUrl(Uri.parse(episode.link!));
                }
              },
            );
          },
        );
      },
    );
  }

  Widget buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Text(
              appName,
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(appName),
        actions: [
          ListenableBuilder(
            listenable: model,
            builder: (context, _) {
              return IconButton(
                icon: model.withImage
                    ? Icon(Icons.image_not_supported_rounded)
                    : Icon(Icons.image_rounded),
                onPressed: () => model.toggleImageVisibility(),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.subscriptions_rounded),
            onPressed: () {
              context.go('/subscribed');
            },
          ),
        ],
      ),
      body: buildBody(context),
      drawer: buildDrawer(context),
    );
  }
}

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
    return RefreshIndicator(
      onRefresh: () => model.load(),
      child: ListenableBuilder(
        listenable: model,
        builder: (context, _) {
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
                                    ChannelImage(
                                      episode,
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
                          // content
                          Flexible(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // icon, channel, date
                                Row(
                                  spacing: 24,
                                  children: [
                                    Row(
                                      spacing: 8.0,
                                      children: [
                                        ChannelImage(
                                          episode,
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
                                // Row > Flexible: limit the width
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        episode.title ?? '',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: titleTextStyle,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          appName,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.primary,
            shadows: [
              Shadow(
                color: Colors.white54,
                blurRadius: 10.0,
                // offset: Offset(2.0, 2.0),
              ),
            ],
          ),
        ),
        actions: [
          ListenableBuilder(
            listenable: model,
            builder: (context, _) {
              return Row(
                children: [
                  // label selector
                  DropdownButton<int>(
                    value: model.selectedLabelId,
                    underline: SizedBox(),
                    items: model.labels.map((e) {
                      return DropdownMenuItem(
                        value: e.id,
                        child: Text(
                          e.title,
                          style: TextStyle(color: labelColor[e.color]),
                        ),
                      );
                    }).toList(),
                    onChanged: (int? value) {
                      model.selectLabel(value);
                    },
                  ),
                  // image visibility
                  IconButton(
                    icon: model.withImage
                        ? Icon(Icons.image_not_supported_rounded)
                        : Icon(Icons.image_rounded),
                    onPressed: () => model.toggleImageVisibility(),
                  ),
                ],
              );
            },
          ),
          // subscriptions
          IconButton(
            icon: Icon(Icons.subscriptions_rounded),
            onPressed: () {
              context.go('/subscribed');
            },
          ),
        ],
      ),
      body: buildBody(context),
      drawer: SidePanel(model: model),
    );
  }
}

class SidePanel extends StatefulWidget {
  final HomeViewModel model;
  const SidePanel({super.key, required this.model});

  @override
  State<SidePanel> createState() => _SidePanelState();
}

class _SidePanelState extends State<SidePanel> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Text(
              'About',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
          ListTile(
            title: Text('Search Parameters'),
            subtitle: Padding(
              padding: const EdgeInsets.only(left: 24.0),
              child: Column(
                children: [
                  // TextFormField(
                  //   key: _minBitratekey,
                  //   controller: _minBitrateCtrl,
                  //   decoration: InputDecoration(
                  //     labelText: 'Minimum bitrate',
                  //     suffixText: 'kbps',
                  //   ),
                  //   onChanged: (value) =>
                  //       _minBitratekey.currentState?.validate(),
                  //   validator: (value) {
                  //     return (value != null && int.tryParse(value) == null)
                  //         ? 'Use integer numbers only'
                  //         : null;
                  //   },
                  // ),
                  // TextFormField(
                  //   key: _maxReturnsKey,
                  //   controller: _maxReturnsCtrl,
                  //   decoration: InputDecoration(
                  //     labelText: 'Maximum count',
                  //     suffixText: 'stations',
                  //   ),
                  //   onChanged: (value) =>
                  //       _maxReturnsKey.currentState?.validate(),
                  //   validator: (value) {
                  //     return (value != null && int.tryParse(value) == null)
                  //         ? 'Use integer numbers only'
                  //         : null;
                  //   },
                  // ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.0),
          ListTile(
            title: Text('App version'),
            subtitle: Text(appVersion),
            onTap: () => launchUrl(Uri.parse(sourceRepository)),
          ),
          ListTile(
            title: Text('Source repository'),
            subtitle: Text('github'),
            onTap: () => launchUrl(Uri.parse(sourceRepository)),
          ),
          ListTile(
            title: Text('Developer'),
            subtitle: Text('innomatic'),
            onTap: () => launchUrl(Uri.parse(developerWebsite)),
          ),
        ],
      ),
    );
  }
}

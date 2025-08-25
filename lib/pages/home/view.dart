import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rssnews/shared/helpers.dart';
import 'package:url_launcher/url_launcher.dart' show launchUrl;

import '../../shared/constants.dart';
import '../../shared/qrcodeimg.dart' show QrCodeImage;
import '../../shared/widgets.dart';
import 'model.dart';

class HomeView extends StatefulWidget {
  final HomeViewModel model;
  const HomeView({super.key, required this.model});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late ScrollController _controller;

  @override
  initState() {
    super.initState();
    _controller = ScrollController();
  }

  @override
  dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget buildBody(BuildContext context) {
    final aspectRatio = MediaQuery.sizeOf(context).aspectRatio;
    final channelTextStyle = TextStyle(
      fontSize: 12,
      color: Theme.of(context).colorScheme.secondary,
    );
    final titleTextStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w700);
    return RefreshIndicator(
      onRefresh: () => widget.model.refresh(),
      child: widget.model.episodes.isNotEmpty
          ? ListView.separated(
              controller: _controller,
              itemCount: widget.model.episodes.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final episode = widget.model.episodes[index];
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
                            episode.imageUrl != null && widget.model.withImage
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
                            episode.imageUrl != null && widget.model.withImage
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
            )
          : Center(
              child: Image.asset(
                assetImageNewspaper,
                width: 180,
                height: 180,
                opacity: AlwaysStoppedAnimation(0.3),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.model,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title:
                // label selector
                DropdownButton<int>(
                  value: widget.model.selectedLabelId,
                  underline: SizedBox(),
                  items: widget.model.labels.map((e) {
                    return DropdownMenuItem(
                      value: e.id,
                      child: Text(
                        e.title,
                        style: TextStyle(color: labelColor[e.color]),
                      ),
                    );
                  }).toList(),
                  onChanged: (int? value) async {
                    await widget.model.selectLabel(value);
                    _controller.jumpTo(_controller.position.minScrollExtent);
                  },
                ),
            actions: [
              // image visibility
              IconButton(
                icon: widget.model.withImage
                    ? Icon(Icons.image_not_supported_rounded)
                    : Icon(Icons.image_rounded),
                onPressed: () => widget.model.toggleImageVisibility(),
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
          drawer: SidePanel(model: widget.model),
          floatingActionButton: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              return _controller.position.pixels < 100
                  ? SizedBox()
                  : Opacity(
                      opacity: 0.6,
                      child: FloatingActionButton(
                        onPressed: () => _controller.animateTo(
                          _controller.position.minScrollExtent,
                          duration: Duration(milliseconds: 700),
                          curve: Curves.fastOutSlowIn,
                        ),
                        child: Icon(Icons.arrow_upward_rounded),
                      ),
                    );
            },
          ),
        );
      },
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
  int displayPeriod = defaultDisplayPeriod;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    super.dispose();
    _dispose();
  }

  Future _init() async {
    setState(() {
      displayPeriod = widget.model.displayPeriod;
    });
  }

  Future _dispose() async {
    await widget.model.setDisplayPeriod(displayPeriod);
  }

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
              'Settings',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
          ListTile(
            title: Text('Episode display period'),
            subtitle: Row(
              children: [
                Text('show news back to'),
                SizedBox(width: 8),
                DropdownButton<int>(
                  value: displayPeriod,
                  underline: SizedBox(),
                  items: displayPeriods.map((e) {
                    return DropdownMenuItem(
                      value: e,
                      child: Text(e.toString()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      displayPeriod = value ?? displayPeriod;
                    });
                  },
                ),
                SizedBox(width: 4),
                Text('days'),
              ],
            ),
          ),
          Divider(indent: 8.0, endIndent: 8.0),
          ListTile(
            title: Text('App version'),
            subtitle: Text(appVersion),
            onTap: () => launchUrl(Uri.parse(sourceRepository)),
            contentPadding: EdgeInsets.only(left: 16.0, right: 8.0),
            trailing: IconButton(
              onPressed: () {
                if (mounted) context.pop();
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text(
                        "Download $appName",
                        style: TextStyle(color: Colors.grey),
                      ),
                      backgroundColor: Colors.white,
                      contentPadding: EdgeInsets.all(32.0),
                      content: Column(
                        spacing: 16.0,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          QrCodeImage(data: releaseUrl),
                          Text(
                            releaseUrl,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              icon: Icon(Icons.qr_code_2_rounded, size: 32.0),
            ),
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

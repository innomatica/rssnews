import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart' show launchUrl;

import '../../shared/constant.dart';
import 'model.dart';

class HomeView extends StatelessWidget {
  final HomeViewModel model;
  const HomeView({super.key, required this.model});

  Widget buildBody(BuildContext context) {
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        return ListView.separated(
          itemCount: model.episodes.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final episode = model.episodes[index];
            return ListTile(
              title: Text(episode.title ?? ''),
              subtitle: Text(
                episode.subtitle ?? episode.description ?? '',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
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
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {},
      //   child: Icon(Icons.add),
      // ),
    );
  }
}

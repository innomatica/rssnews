import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:rssnews/pages/home/view.dart';
import 'package:rssnews/pages/channels/model.dart';

import '../pages/browser/model.dart';
import '../pages/browser/view.dart';
import '../pages/channel/model.dart';
import '../pages/channel/view.dart';
import '../pages/episode/view.dart';
import '../pages/favorites/model.dart';
import '../pages/favorites/view.dart';
import '../pages/home/model.dart';
import '../pages/channels/view.dart';

final router = GoRouter(
  initialLocation: "/",
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        return HomeView(model: context.read<HomeViewModel>()..load());
      },
      routes: [
        GoRoute(
          path: 'episode',
          builder: (context, state) {
            return EpisodeView();
          },
        ),
        GoRoute(
          path: 'channels',
          builder: (context, state) {
            return ChannelsView(
              model: context.read<ChannelsViewModel>()..load(),
            );
          },
          routes: [
            GoRoute(
              path: 'browser',
              builder: (context, state) {
                return BrowserView(
                  model: context.read<BrowserViewModel>(),
                  query: state.uri.queryParameters['query'],
                );
              },
            ),
            GoRoute(
              path: 'channel',
              builder: (context, state) {
                return ChannelView(model: context.read<ChannelViewModel>());
              },
            ),
            GoRoute(
              path: 'favorites',
              builder: (context, state) {
                return FavoritesView(model: context.read<FavoritesViewModel>());
              },
            ),
          ],
        ),
      ],
    ),
  ],
);

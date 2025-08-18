import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:rssnews/pages/home/view.dart';
import 'package:rssnews/pages/subscribed/model.dart';

import '../pages/browser/model.dart';
import '../pages/browser/view.dart';
import '../pages/channel/model.dart';
import '../pages/channel/view.dart';
import '../pages/curated/model.dart';
import '../pages/curated/view.dart';
import '../pages/home/model.dart';
import '../pages/subscribed/view.dart';

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
          path: 'browser',
          builder: (context, state) {
            return BrowserView(
              model: context.read<BrowserViewModel>(),
              url: state.uri.queryParameters['url'],
            );
          },
        ),
        GoRoute(
          path: 'subscribed',
          builder: (context, state) {
            return SubscribedView(
              model: context.read<SubscribedViewModel>()..load(),
            );
          },
          routes: [
            GoRoute(
              path: 'channel/:id',
              builder: (context, state) {
                return ChannelView(
                  model: context.read<ChannelViewModel>()
                    ..load(int.parse(state.pathParameters["id"] ?? '0')),
                );
              },
            ),
            GoRoute(
              path: 'curated',
              builder: (context, state) {
                return CuratedView(
                  model: context.read<CuratedViewModel>()..load(),
                );
              },
            ),
          ],
        ),
      ],
    ),
  ],
);

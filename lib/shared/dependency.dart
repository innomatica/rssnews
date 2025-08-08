import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart' show SingleChildWidget;
import 'package:rssnews/data/service/local/storage.dart';

import '../data/repository/feed.dart';
import '../data/service/local/sqflite.dart';
import '../pages/browser/model.dart';
import '../pages/channel/model.dart';
import '../pages/curated/model.dart';
import '../pages/home/model.dart';
import '../pages/subscribed/model.dart';

List<SingleChildWidget> get providers => [
  Provider(create: (context) => DatabaseService()),
  Provider(create: (context) => StorageService()),
  Provider(
    create: (context) => FeedRepository(
      dbSrv: context.read<DatabaseService>(),
      stSrv: context.read<StorageService>(),
    ),
  ),
  ChangeNotifierProvider(
    create: (context) =>
        BrowserViewModel(feedRepo: context.read<FeedRepository>()),
  ),
  ChangeNotifierProvider(
    create: (context) =>
        ChannelViewModel(feedRepo: context.read<FeedRepository>()),
  ),
  ChangeNotifierProvider(
    create: (context) =>
        CuratedViewModel(feedRepo: context.read<FeedRepository>()),
  ),
  ChangeNotifierProvider(
    create: (context) =>
        HomeViewModel(feedRepo: context.read<FeedRepository>()),
  ),
  ChangeNotifierProvider(
    create: (context) =>
        SubscribedViewModel(feedRepo: context.read<FeedRepository>()),
  ),
];

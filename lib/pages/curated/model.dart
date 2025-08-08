import 'package:flutter/material.dart';
import 'package:logging/logging.dart' show Logger;
import 'package:rssnews/data/repository/feed.dart';

import '../../models/feedinfo.dart';

class CuratedViewModel extends ChangeNotifier {
  final FeedRepository _feedRepo;
  CuratedViewModel({required FeedRepository feedRepo}) : _feedRepo = feedRepo;

  final _curated = <FeedInfo>[];
  // ignore: unused_field
  final _logger = Logger("CuratedViewModel");

  List<FeedInfo> get curated => _curated;

  Future load() async {
    _curated.clear();
    _curated.addAll(await _feedRepo.getSampleFeedInfo());
    // _logger.fine('curated:$_curated');
    notifyListeners();
  }
}

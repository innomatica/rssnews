import 'package:flutter/material.dart';
import 'package:logging/logging.dart' show Logger;

import '../../data/repository/feed.dart';
import '../../models/feed.dart';
import '../../shared/constant.dart';

class BrowserViewModel extends ChangeNotifier {
  final FeedRepository _feedRepo;
  BrowserViewModel({required FeedRepository feedRepo}) : _feedRepo = feedRepo;

  // ignore: unused_field
  final _logger = Logger("BrowserViewModel");
  Feed? _feed;
  bool? _subscribed;

  bool get found => _feed != null;
  bool get subscribed => _subscribed == true;

  Future fetchFeed(String url) async {
    _feed = await _feedRepo.fetchFeed(url);
    // TODO: check if already subscribed
    _subscribed = false;
    _logger.fine('url: $url, feed: $_feed');
    notifyListeners();
  }

  Future subscribe() async {
    if (_feed != null) {
      _subscribed = await _feedRepo.subscribe(_feed!);
      _logger.fine('subscribed: $_subscribed');
    }
    notifyListeners();
  }

  Future<String> getSearchEngineUrl() async {
    final settings = await _feedRepo.getSettings();
    return settings?.searchEngineUrl ?? defaultQueryUrl;
  }
}

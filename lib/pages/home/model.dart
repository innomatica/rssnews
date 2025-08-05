import 'package:flutter/material.dart';
import 'package:logging/logging.dart' show Logger;

import '../../data/repository/feed.dart';
import '../../models/episode.dart';

class HomeViewModel extends ChangeNotifier {
  final FeedRepository _feedRepo;

  HomeViewModel({required FeedRepository feedRepo}) : _feedRepo = feedRepo;

  final _episodes = <Episode>[];
  final _logger = Logger('HomeViewModel');

  List<Episode> get episodes => _episodes;

  Future load() async {
    _episodes.clear();
    _episodes.addAll(await _feedRepo.getEpisodes());
    _logger.fine('episodes:$_episodes');
    notifyListeners();
  }
}

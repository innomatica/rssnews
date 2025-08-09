import 'package:flutter/material.dart';
import 'package:logging/logging.dart' show Logger;

import '../../data/repository/feed.dart';
import '../../models/episode.dart';

class HomeViewModel extends ChangeNotifier {
  final FeedRepository _feedRepo;

  HomeViewModel({required FeedRepository feedRepo}) : _feedRepo = feedRepo;

  final _episodes = <Episode>[];
  final _logger = Logger('HomeViewModel');
  bool _withImage = true;

  List<Episode> get episodes => _episodes;
  bool get withImage => _withImage;

  set withImage(bool value) {
    if (_withImage != value) {
      _withImage = value;
      notifyListeners();
    }
  }

  void toggleImageVisibility() {
    print('withImage:$_withImage');
    _withImage = !_withImage;
    notifyListeners();
  }

  Future load() async {
    _episodes.clear();
    _episodes.addAll(await _feedRepo.getEpisodes());
    _logger.fine('episodes:$_episodes');
    notifyListeners();
  }

  Future<ImageProvider> getChannelImage(Episode episode) async {
    return await _feedRepo.getChannelImage(episode);
  }
}

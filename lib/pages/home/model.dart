import 'package:flutter/material.dart';
import 'package:logging/logging.dart' show Logger;
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;

import '../../data/repository/feed.dart';
import '../../models/episode.dart';
import '../../models/label.dart';
import '../../shared/constant.dart';

class HomeViewModel extends ChangeNotifier {
  final FeedRepository _feedRepo;

  HomeViewModel({required FeedRepository feedRepo}) : _feedRepo = feedRepo;

  final _logger = Logger('HomeViewModel');
  List<Episode> _episodes = [];
  List<Label> _labels = [];
  bool _withImage = true;
  int _selectedLabelId = 0;
  SharedPreferences? prefs;

  List<Episode> get episodes => _selectedLabelId == 0
      ? _episodes
      : _episodes
            .where((e) => e.labels?.contains(_selectedLabelId) == true)
            .toList();
  List<Label> get labels => _labels;
  bool get withImage => _withImage;
  final _defaultLabel = Label(id: 0, title: 'All Categories', color: 0);
  int get selectedLabelId => _selectedLabelId;

  set withImage(bool value) {
    if (_withImage != value) {
      _withImage = value;
      notifyListeners();
    }
  }

  void toggleImageVisibility() {
    _withImage = !_withImage;
    notifyListeners();
  }

  Future load() async {
    prefs = await SharedPreferences.getInstance();
    _selectedLabelId = prefs!.getInt(prefsKeySelLabelId) ?? _defaultLabel.id!;
    _episodes = await _feedRepo.getEpisodes();
    _logger.fine('episodes:$_episodes');
    _labels = [_defaultLabel, ...await _feedRepo.getLabels()];
    _logger.fine('labels:$_labels');
    notifyListeners();
  }

  Future selectLabel(int? id) async {
    if (id != null && id >= 0 && id < _labels.length) {
      _selectedLabelId = id;

      notifyListeners();

      await prefs?.setInt(prefsKeySelLabelId, id);
    }
  }
  // Future<ImageProvider> getChannelImage(Episode episode) async {
  //   return await _feedRepo.getChannelImage(episode);
  // }

  // Image getChannelImg(Episode episode, {double? width, double? height}) =>
  //     _feedRepo.getChannelImg(episode, width: width, height: height);
}

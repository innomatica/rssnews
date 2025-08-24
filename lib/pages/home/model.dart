import 'package:flutter/material.dart';
import 'package:logging/logging.dart' show Logger;
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;

import '../../data/repository/feed.dart';
import '../../models/episode.dart';
import '../../models/label.dart';
import '../../shared/constants.dart';

class HomeViewModel extends ChangeNotifier {
  final FeedRepository _feedRepo;

  HomeViewModel({required FeedRepository feedRepo}) : _feedRepo = feedRepo;

  final _defaultLabel = Label(id: 0, title: 'All Categories', color: 0);

  List<Episode> _episodes = [];
  List<Label> _labels = [];
  bool _withImage = true;
  int _selectedLabelId = 0;
  int _displayPeriod = defaultDisplayPeriod;
  // SharedPreferences? _spref;
  // ignore: unused_field
  final _logger = Logger('HomeViewModel');

  List<Episode> get episodes => _selectedLabelId == 0
      ? _episodes
      : _episodes
            .where((e) => e.labels?.contains(_selectedLabelId) == true)
            .toList();
  List<Label> get labels => _labels;
  bool get withImage => _withImage;
  int get selectedLabelId => _selectedLabelId;
  int get displayPeriod => _displayPeriod;

  set withImage(bool value) {
    if (_withImage != value) {
      _withImage = value;
      notifyListeners();
    }
  }

  Future _getEpisodes() async {
    _episodes = await _feedRepo.getEpisodes(period: _displayPeriod);
  }

  Future load() async {
    _logger.fine('load');
    final spref = await SharedPreferences.getInstance();
    _displayPeriod = spref.getInt(pKeyDisplayPeriod) ?? defaultDisplayPeriod;
    _selectedLabelId = spref.getInt(pKeySelectedLabelId) ?? _defaultLabel.id!;
    _labels = [_defaultLabel, ...await _feedRepo.getLabels()];
    // _logger.fine('labels:$_labels');
    await _feedRepo.refreshFeeds(force: false);
    await _getEpisodes();
    // _logger.fine('episodes:$_episodes');
    notifyListeners();
  }

  Future refresh() async {
    _logger.fine('refresh');
    await _feedRepo.refreshFeeds(force: true);
    await _getEpisodes();
    notifyListeners();
  }

  Future selectLabel(int? id) async {
    if (id != null && id >= 0 && id < _labels.length) {
      final spref = await SharedPreferences.getInstance();
      await spref.setInt(pKeySelectedLabelId, id);
      _selectedLabelId = id;
      notifyListeners();
    }
  }

  void toggleImageVisibility() {
    _withImage = !_withImage;
    notifyListeners();
  }

  // Settings

  Future setDisplayPeriod(int value) async {
    final spref = await SharedPreferences.getInstance();
    await spref.setInt(pKeyDisplayPeriod, value);
    // _displayPeriod = value;
    load();
  }
}

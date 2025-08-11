import 'package:flutter/material.dart';
import 'package:logging/logging.dart' show Logger;
import 'package:rssnews/data/repository/feed.dart';

import '../../models/channel.dart';
import '../../models/label.dart';

class SubscribedViewModel extends ChangeNotifier {
  final FeedRepository _feedRepo;

  SubscribedViewModel({required FeedRepository feedRepo})
    : _feedRepo = feedRepo;

  final _channels = <Channel>[];
  final _labels = <Label>[];
  // ignore: unused_field
  final _logger = Logger("SubscribedViewModel");

  List<Channel> get channels => _channels;
  List<Label> get labels => _labels;

  Future load() async {
    _channels.clear();
    _channels.addAll(await _feedRepo.getChannels());
    _logger.fine('load.channels: $_channels');
    _labels.clear();
    _labels.addAll(await _feedRepo.getLabels());
    _logger.fine('load.labels: $_labels');
    notifyListeners();
  }
}

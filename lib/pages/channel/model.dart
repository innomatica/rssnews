import 'package:flutter/material.dart';
import 'package:logging/logging.dart' show Logger;

import '../../data/repository/feed.dart';
import '../../models/channel.dart';
import '../../models/label.dart';

class ChannelViewModel extends ChangeNotifier {
  final FeedRepository _feedRepo;
  ChannelViewModel({required FeedRepository feedRepo}) : _feedRepo = feedRepo;
  Channel? _channel;
  List<Label> _labels = [];
  final _logger = Logger("ChannelViewModel");

  Channel? get channel => _channel;
  List<Label> get labels => _labels;

  Future load(int channelId) async {
    _channel = await _feedRepo.getChannel(channelId);
    _logger.fine('load.channel:$_channel');
    _labels = (await _feedRepo.getLabels())..sort((a, b) => a.id! - b.id!);
    _logger.fine('load.labels: $_labels');
    notifyListeners();
  }

  Future delete() async {
    if (_channel != null && _channel!.id != null) {
      await _feedRepo.deleteChannel(_channel!.id!);
    }
  }

  Future update(Map<String, String> data) async {
    // print('update:$_channel');
    if (_channel?.id != null) {
      await _feedRepo.updateChannel(_channel!.id!, {
        "title": data["title"],
        "subtitle": data["subtitle"],
        "link": data["link"],
        "image_url": data["imageUrl"],
      });
    }
  }

  Future toggleLabel(int? labelId) async {
    if (_channel != null && labelId != null) {
      if (_channel!.labels?.contains(labelId) == true) {
        await _feedRepo.removeLabelFromChannel(_channel!.id!, labelId);
      } else {
        await _feedRepo.addLabelToChannel(_channel!.id!, labelId);
      }
      _channel = await _feedRepo.getChannel(_channel!.id);
      notifyListeners();
    }
  }

  Future updateLabels() async {
    for (final label in labels) {
      // _logger.fine('label:$label');
      await _feedRepo.updateLabel(label);
    }
    notifyListeners();
  }
}

import 'package:flutter/material.dart';
import 'package:logging/logging.dart' show Logger;

import '../../data/repository/feed.dart';
import '../../models/channel.dart';

class ChannelViewModel extends ChangeNotifier {
  final FeedRepository _feedRepo;
  ChannelViewModel({required FeedRepository feedRepo}) : _feedRepo = feedRepo;
  Channel? _channel;
  final _logger = Logger("ChannelViewModel");

  Channel? get channel => _channel;

  Future load(int channelId) async {
    _channel = await _feedRepo.getChannel(channelId);
    _logger.fine('channel:$_channel');
    notifyListeners();
  }

  Future delete() async {
    if (_channel != null && _channel!.id != null) {
      await _feedRepo.deleteChannel(_channel!.id!);
    }
  }
}

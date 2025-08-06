import 'package:flutter/material.dart';
import 'package:logging/logging.dart' show Logger;
import 'package:rssnews/data/repository/feed.dart';

import '../../models/channel.dart';

class SubscribedViewModel extends ChangeNotifier {
  final FeedRepository _feedRepo;

  SubscribedViewModel({required FeedRepository feedRepo})
    : _feedRepo = feedRepo;

  final _channels = <Channel>[];
  final _logger = Logger("ChannelsViewModel");

  List<Channel> get channels => _channels;

  Future load() async {
    _channels.clear();
    _channels.addAll(await _feedRepo.getChannels());
    _logger.fine('load: $_channels');
    notifyListeners();
  }

  Future<ImageProvider> getChannelImage(Channel channel) async {
    return _feedRepo.getChannelImage(channel);
  }
}

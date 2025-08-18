import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:rssnews/shared/constants.dart';

import '../models/channel.dart' show Channel;
import '../models/episode.dart' show Episode;

class ChannelImage extends StatelessWidget {
  final dynamic item;
  final double? width;
  final double? height;
  final double? opacity;
  ChannelImage(
    this.item, {
    super.key,
    // required this.item,
    this.width,
    this.height,
    this.opacity,
  });

  final _logger = Logger("ChannelImage");

  @override
  Widget build(BuildContext context) {
    try {
      return item is Channel && item.imageUrl != null
          ? Image.network(
              item.imageUrl!,
              width: width,
              height: height,
              fit: BoxFit.cover,
              opacity: AlwaysStoppedAnimation(opacity ?? 1.0),
            )
          : item is Episode && item.channelImageUrl != null
          ? Image.network(
              item.channelImageUrl!,
              width: width,
              height: height,
              fit: BoxFit.cover,
              opacity: AlwaysStoppedAnimation(opacity ?? 1.0),
            )
          : Image.asset(
              assetImageNewspaper,
              width: width,
              height: height,
              fit: BoxFit.cover,
              opacity: AlwaysStoppedAnimation(opacity ?? 1.0),
            );
    } catch (e) {
      _logger.warning(e.toString());
      return Image.asset(
        assetImageNewspaper,
        width: width,
        height: height,
        fit: BoxFit.cover,
        opacity: AlwaysStoppedAnimation(opacity ?? 1.0),
      );
    }
  }
}

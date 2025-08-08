import 'dart:convert' show utf8, jsonDecode;

import 'package:flutter/material.dart'
    show ImageProvider, FileImage, NetworkImage, AssetImage;
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart' show Logger;
import 'package:xml/xml.dart';

import '../../models/channel.dart';
import '../../models/episode.dart';
import '../../models/feed.dart';
import '../../models/feedinfo.dart';
import '../../models/settings.dart';
import '../../shared/constant.dart';
import '../../shared/helpers.dart';
import '../service/local/sqflite.dart';
import '../service/local/storage.dart';

class FeedRepository {
  final DatabaseService _dbSrv;
  final StorageService _stSrv;
  FeedRepository({
    required DatabaseService dbSrv,
    required StorageService stSrv,
  }) : _dbSrv = dbSrv,
       _stSrv = stSrv;

  final _logger = Logger('FeedRespository');

  // Feed

  Future<Feed?> fetchFeed(String url) async {
    // for testing replace url here
    // url = 'https://feeds.simplecast.com/EmVW7VGp'; // radiolab
    _logger.fine('fetch-url:$url');
    final res = await http.get(Uri.parse(url));
    _logger.fine('content-type:${res.headers['content-type']}');
    if (res.statusCode == 200 &&
        res.headers['content-type']?.contains("xml") == true) {
      final document = XmlDocument.parse(utf8.decode(res.bodyBytes));
      // first children
      final children = document.childElements;
      if (children.isNotEmpty) {
        final root = children.first;
        // rss or atom
        if (root.name.toString() == 'rss') {
          return Feed.fromRss(root, url);
        } else if (root.name.toString() == 'feed') {
          return Feed.fromAtom(root, url);
        }
        _logger.severe('unknown feed format');
        // throw Exception('unknown feed format');
      }
    }
    return null;

    // try {
    //   final res = await http.get(Uri.parse(url));
    //   if (res.statusCode == 200) {
    //     final document = XmlDocument.parse(utf8.decode(res.bodyBytes));
    //     // first children
    //     final children = document.childElements;
    //     if (children.isNotEmpty) {
    //       final root = children.first;
    //       // rss or atom
    //       if (root.name.toString() == 'rss') {
    //         return Feed.fromRss(root, url);
    //       } else if (root.name.toString() == 'feed') {
    //         return Feed.fromAtom(root, url);
    //       }
    //       _logger.severe('unknown feed format');
    //       // throw Exception('unknown feed format');
    //     }
    //   }
    //   _logger.severe('{res.statusCode} encountered');
    //   // throw Exception('{res.statusCode} encountered');
    // } catch (e) {
    //   _logger.severe(e.toString);
    //   // throw Exception(e.toString);
    // }
    // return null;
  }

  Future<Feed?> getFeed(String url) async {
    final channel = await getChannelByUrl(url);
    if (channel != null) {
      final episodes = await getEpisodesByChannel(channel.id!);
      return Feed(channel: channel, episodes: episodes);
    }
    return null;
  }

  // Channel

  // Subscription

  Future<bool> subscribe(Feed feed) async {
    _logger.fine('subscrib');
    if (await createChannel(feed.channel) > 0) {
      // read back
      final channel = await getChannelByUrl(feed.channel.url);
      // _log.fine('channel:$channel');
      if (channel != null) {
        // download thumbnail
        await _downloadResource(
          channel.id!,
          channel.imageUrl ??
              "https://www.google.com/s2/favicons?domain=${channel.url}&sz=128",
          channelImgFname,
        );
        // save episodes
        final refDate = DateTime.now().subtract(
          Duration(days: maxRetentionDays),
        );
        for (final episode in feed.episodes) {
          // _log.fine('episode:$episode');
          // save only up to maxRetentionDays ago
          if (episode.published?.isBefore(refDate) != true) {
            episode.channelId = channel.id;
            await createEpisode(episode);
          }
        }
        return true;
      }
    }
    return false;
  }

  Future unsubscribe(int channelId) async {
    _logger.fine('unsubscribe');
    await deleteChannel(channelId);
  }

  // Channel

  Future<List<Channel>> getChannels() async {
    try {
      final rows = await _dbSrv.queryAll("SELECT * FROM channels");
      return rows.map((e) => Channel.fromSqlite(e)).toList();
    } on Exception {
      rethrow;
    }
  }

  Future<Channel?> getChannel(int? id) async {
    try {
      if (id != null) {
        final row = await _dbSrv.query("SELECT * FROM channels WHERE id = ?", [
          id,
        ]);
        return row != null ? Channel.fromSqlite(row) : null;
      }
      return null;
    } on Exception {
      rethrow;
    }
  }

  Future<Channel?> getChannelByUrl(String url) async {
    try {
      final row = await _dbSrv.query("SELECT * FROM channels WHERE url = ?", [
        url,
      ]);
      return row != null ? Channel.fromSqlite(row) : null;
    } on Exception {
      rethrow;
    }
  }

  Future<int> createChannel(Channel channel) async {
    try {
      final data = channel.toSqlite();
      data.remove('id');
      final args = List.filled(data.length, '?').join(',');
      final sets = data.keys.map((e) => '$e = ?').join(',');
      return await _dbSrv.insert(
        "INSERT INTO channels(${data.keys.join(',')}) VALUES($args)"
        " ON CONFLICT(url) DO UPDATE SET $sets",
        [...data.values, ...data.values],
      );
    } on Exception {
      rethrow;
    }
  }

  Future<int> updateChannel(int channelId, Map<String, Object> data) async {
    // _log.fine('updateChannel: $data');
    try {
      final sets = data.keys.map((e) => '$e = ?').join(',');
      return await _dbSrv.update("UPDATE channels SET $sets WHERE id = ?", [
        ...data.values,
        channelId,
      ]);
    } on Exception {
      rethrow;
    }
  }

  Future deleteChannel(int channelId) async {
    try {
      await _dbSrv.delete("DELETE FROM episodes WHERE channel_id = ?", [
        channelId,
      ]);
      await _dbSrv.delete("DELETE FROM channels WHERE id = ?", [channelId]);
      await _stSrv.deleteDirectory(channelId);
    } on Exception {
      rethrow;
    }
  }

  // FIXME
  /*
  Future purgeChannel(int? channelId) async {
    try {
      if (channelId != null) {
        _log.fine('purgeChannel');
        final episodes = await getEpisodesByChannel(channelId);
        final refDate = DateTime.now().subtract(
          Duration(days: maxRetentionDays),
        );
        for (final episode in episodes) {
          // delete expired episodes and its local media data
          if (episode.published?.isBefore(refDate) == true) {
            await deleteEpisode(episode.guid);
            await _stSrv.deleteFile(channelId, episode.mediaFname);
            if (episode.imageFname != null) {
              await _stSrv.deleteFile(channelId, episode.imageFname!);
            }
          }
          // delete local media data of played episode
          if (episode.played == true) {
            await _stSrv.deleteFile(channelId, episode.mediaFname);
          }
        }
      }
    } on Exception {
      rethrow;
    }
  }
*/

  // Episode

  Future<List<Episode>> getEpisodes({
    int period = 90,
    bool force = false,
  }) async {
    // FIXME
    // await refreshData(force: force);
    final start = yymmdd(DateTime.now().subtract(Duration(days: period)));
    try {
      final rows = await _dbSrv.queryAll(
        """
      SELECT episodes.*, channels.title as channel_title, 
        channels.image_url as channel_image_url 
      FROM episodes 
      INNER JOIN channels ON channels.id=episodes.channel_id
      WHERE DATE(episodes.published) > ?
      ORDER BY episodes.published DESC""",
        [start],
      );
      return rows.map((e) => Episode.fromSqlite(e)).toList();
    } on Exception {
      rethrow;
    }
  }

  Future<List<Episode>> getEpisodesByChannel(
    int channelId, {
    int period = 90,
  }) async {
    final start = yymmdd(DateTime.now().subtract(Duration(days: period)));
    try {
      final rows = await _dbSrv.queryAll(
        """
      SELECT episodes.*, channels.title as channel_title, 
        channels.image_url as channel_image_url 
      FROM episodes 
      INNER JOIN channels ON channels.id=episodes.channel_id
      WHERE channel_id = ? 
        AND DATE(episodes.published) > ?
      ORDER BY episodes.published DESC""",
        [channelId, start],
      );
      return rows.map((e) => Episode.fromSqlite(e)).toList();
    } on Exception {
      rethrow;
    }
  }

  Future<Episode?> getEpisodeByGuid(String? guid) async {
    try {
      final row = await _dbSrv.query(
        """
      SELECT episodes.*, channels.title as channel_title, 
        channels.image_url as channel_image_url 
      FROM episodes 
      INNER JOIN channels ON channels.id=episodes.channel_id
      WHERE guid = ?""",
        [guid],
      );
      return row != null ? Episode.fromSqlite(row) : null;
    } on Exception {
      rethrow;
    }
  }

  Future<int> createEpisode(Episode episode) async {
    try {
      final data = episode.toSqlite();
      data.remove('id');
      final args = List.filled(data.length, '?').join(',');
      final sets = data.keys.map((e) => '$e = ?').join(',');
      return await _dbSrv.insert(
        "INSERT INTO episodes(${data.keys.join(',')}) VALUES($args)"
        " ON CONFLICT(guid) DO UPDATE SET $sets",
        [...data.values, ...data.values],
      );
    } on Exception {
      rethrow;
    }
  }

  Future<int> updateEpisode(int episodeId, Map<String, Object?> data) async {
    try {
      final sets = data.keys.map((e) => '$e = ?').join(',');
      return await _dbSrv.update("UPDATE episodes SET $sets WHERE id = ?", [
        ...data.values,
        episodeId,
      ]);
    } on Exception {
      rethrow;
    }
  }

  Future deleteEpisode(String guid) async {
    try {
      await _dbSrv.delete("DELETE FROM episodes WHERE guid = ?", [guid]);
    } on Exception {
      rethrow;
    }
  }

  // Settings

  Future<Settings?> getSettings() async {
    try {
      final row = await _dbSrv.query("SELECT * from settings");
      return row != null ? Settings.fromSqlite(row) : null;
    } on Exception {
      rethrow;
    }
  }

  // Resources

  Future<bool> _downloadResource(
    int channelId,
    String url,
    String fname,
  ) async {
    bool flag = false;
    final client = http.Client();
    final req = http.Request('GET', Uri.parse(url));
    final res = await client.send(req);
    if (res.statusCode == 200) {
      _logger.fine('downloading: $url to $fname');
      final file = await _stSrv.getFile(channelId, fname);
      if (file != null) {
        await file.create(recursive: true);
        final sink = file.openWrite();
        await res.stream.pipe(sink);
        flag = true;
      }
    }
    client.close();
    return flag;
  }

  Future<ImageProvider> getChannelImage(dynamic chnOrEps) async {
    final file = await _stSrv.getFile(
      chnOrEps is Channel ? chnOrEps.id : chnOrEps.channelId,
      channelImgFname,
    );
    return file != null && file.existsSync()
        ? FileImage(file) // thumbnail found in the local
        : chnOrEps.imageUrl != null
        ? NetworkImage(chnOrEps.imageUrl.toString()) // has valid imageUrl
        : AssetImage(defaultChannelImage); // fallback image
  }

  // feed data
  Future<List<FeedInfo>> getSampleFeedInfo() async {
    final ret = <FeedInfo>[];
    final client = http.Client();
    for (final file in curatedFeedFiles) {
      final res = await client.get(Uri.parse(file['url']!));
      final info = FeedInfo(category: file['title'] as String, items: []);
      // _logger.fine('res:$res');
      if (res.statusCode == 200) {
        final fInfoItems = jsonDecode(res.body)['data'];
        for (final fInfoItem in fInfoItems) {
          // _logger.fine('fInfoItem:$fInfoItem');
          info.items.add(
            FeedInfoItem(
              title: fInfoItem['title'],
              website: fInfoItem['website'],
              description: fInfoItem['description'],
              language: fInfoItem['language'],
              keywords: fInfoItem['keywords'].join(","),
              feedUrl: fInfoItem['feedUrl'],
              favicon: fInfoItem['favicon'],
            ),
          );
        }
      }
      ret.add(info);
    }
    client.close();
    return ret;
  }

  // new
}

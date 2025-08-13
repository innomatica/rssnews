import 'dart:convert' show utf8, jsonDecode;

import 'package:html_unescape/html_unescape_small.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart' show Logger;
import 'package:xml/xml.dart';

import '../../models/channel.dart';
import '../../models/episode.dart';
import '../../models/feed.dart';
import '../../models/feedinfo.dart';
import '../../models/label.dart';
// import '../../models/settings.dart';
// import '../../shared/constant.dart';
// import '../../shared/helpers.dart';
import '../service/local/sqflite.dart';

class FeedRepository {
  final DatabaseService _dbSrv;
  FeedRepository({required DatabaseService dbSrv}) : _dbSrv = dbSrv;

  final _unesc = HtmlUnescape();
  final _logger = Logger('FeedRespository');

  // Feed

  Future<Feed?> fetchFeed(String url) async {
    // for testing replace url here
    // url = 'https://feeds.simplecast.com/EmVW7VGp'; // radiolab
    _logger.fine('fetch-url:$url');
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200 &&
          res.headers['content-type']?.contains("xml") == true) {
        final document = XmlDocument.parse(
          _unesc.convert(utf8.decode(res.bodyBytes)),
        );
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
      } else {
        _logger.fine('${res.statusCode}: ${res.headers['content-type']}');
      }
    } catch (e) {
      _logger.severe(e.toString);
      // throw Exception(e.toString);
    }
    return null;
  }

  // // not used
  // Future<Feed?> getFeed(String url) async {
  //   final channel = await getChannelByUrl(url);
  //   if (channel != null) {
  //     final episodes = await getEpisodesByChannel(channel.id!);
  //     return Feed(channel: channel, episodes: episodes);
  //   }
  //   return null;
  // }

  // Subscription

  Future<bool> subscribe(Feed feed) async {
    _logger.fine('subscribe');
    return await createChannel(feed.channel) > 0;
    /*
    if (await createChannel(feed.channel) > 0) {
      // read back
      final channel = await getChannelByUrl(feed.channel.url);
      // _log.fine('channel:$channel');
      if (channel != null) {
        // save episodes
        final refDate = DateTime.now().subtract(
          Duration(days: maxRetentionDays),
        );
        for (final episode in feed.episodes) {
          // save only up to maxRetentionDays ago
          if (episode.published?.isBefore(refDate) != true) {
            episode.channelId = channel.id;
            final idx = await createEpisode(episode);
            _logger.fine('episode:$idx - $episode');
          }
        }
        return true;
      }
    }
    return false;
    */
  }

  Future unsubscribe(int channelId) async {
    _logger.fine('unsubscribe');
    await deleteChannel(channelId);
  }

  // Channel

  Future<List<Channel>> getChannels() async {
    try {
      final rows = await _dbSrv.queryAll(
        """SELECT channels.*, group_concat(channel_label.label_id) as labels
        FROM channels LEFT JOIN channel_label 
        ON channels.id = channel_label.channel_id
        GROUP BY channels.id
        """,
      );
      return rows.map((e) => Channel.fromSqlite(e)).toList();
    } on Exception {
      rethrow;
    }
  }

  Future<Channel?> getChannel(int? id) async {
    try {
      if (id != null) {
        final row = await _dbSrv.query(
          """SELECT channels.*, group_concat(channel_label.label_id) as labels
        FROM channels LEFT JOIN channel_label 
        ON channels.id = channel_label.channel_id
        WHERE channels.id = ?
        GROUP BY channels.id
        """,
          [id],
        );

        return row != null ? Channel.fromSqlite(row) : null;
      }
      return null;
    } on Exception {
      rethrow;
    }
  }

  Future<Channel?> getChannelByUrl(String url) async {
    try {
      final row = await _dbSrv.query(
        """SELECT channels.*, group_concat(channel_label.label_id) as labels
        FROM channels LEFT JOIN channel_label 
        ON channels.id = channel_label.channel_id
        WHERE channels.url = ?
        GROUP BY channels.id
        """,
        [url],
      );
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

  Future<int> updateChannel(int channelId, Map<String, Object?> data) async {
    _logger.fine('updateChannel: $data');
    try {
      final sets = data.keys.map((e) => '$e = ?').join(',');
      final idx = await _dbSrv.update(
        "UPDATE channels SET $sets WHERE id = ?",
        [...data.values, channelId],
      );
      return idx;
    } on Exception {
      rethrow;
    }
  }

  Future deleteChannel(int channelId) async {
    try {
      // await _dbSrv.delete("DELETE FROM episodes WHERE channel_id = ?", [
      //   channelId,
      // ]);
      await _dbSrv.delete("DELETE FROM channels WHERE id = ?", [channelId]);
    } on Exception {
      rethrow;
    }
  }

  // Episode

  // // not used
  // Future<List<Episode>> getEpisodes({
  //   int period = 90,
  //   bool force = false,
  // }) async {
  //   final start = yymmdd(DateTime.now().subtract(Duration(days: period)));
  //   try {
  //     final rows = await _dbSrv.queryAll(
  //       """
  //     SELECT episodes.*, channels.title as channel_title,
  //       channels.image_url as channel_image_url,
  //       group_concat(channel_label.label_id) as labels
  //     FROM episodes
  //     INNER JOIN channels ON channels.id = episodes.channel_id
  //     LEFT JOIN channel_label ON channels.id = channel_label.channel_id
  //     WHERE DATE(episodes.published) > ?
  //     GROUP BY episodes.id
  //     ORDER BY episodes.published DESC
  //     """,
  //       [start],
  //     );
  //     return rows.map((e) => Episode.fromSqlite(e)).toList()
  //       ..sort((a, b) => b.published!.compareTo(a.published!));
  //   } on Exception {
  //     rethrow;
  //   }
  // }

  Future<List<Episode>> fetchEpisodes() async {
    final episodes = <Episode>[];

    final channels = await getChannels();
    for (final channel in channels) {
      final feed = await fetchFeed(channel.url);
      if (feed != null) {
        for (final item in feed.episodes) {
          item.channelTitle = channel.title;
          item.channelImageUrl = channel.imageUrl;
          item.labels = channel.labels;
          episodes.add(item);
        }
      }
    }
    return episodes..sort((a, b) => b.published.compareTo(a.published));
  }

  // // not used
  // Future<List<Episode>> getEpisodesByChannel(
  //   int channelId, {
  //   int period = 90,
  // }) async {
  //   final start = yymmdd(DateTime.now().subtract(Duration(days: period)));
  //   try {
  //     final rows = await _dbSrv.queryAll(
  //       """
  //     SELECT episodes.*, channels.title as channel_title,
  //       channels.image_url as channel_image_url,
  //       group_concat(channel_label.label_id) as labels
  //     FROM episodes
  //     INNER JOIN channels ON channels.id = episodes.channel_id
  //     LEFT JOIN channel_label ON channels.id = channel_label.channel_id
  //     WHERE channel_id = ?
  //       AND DATE(episodes.published) > ?
  //     GROUP BY episodes.id
  //     ORDER BY episodes.published DESC""",
  //       [channelId, start],
  //     );
  //     return rows.map((e) => Episode.fromSqlite(e)).toList();
  //   } on Exception {
  //     rethrow;
  //   }
  // }

  // // not used
  // Future<Episode?> getEpisodeByGuid(String? guid) async {
  //   try {
  //     final row = await _dbSrv.query(
  //       """
  //     SELECT episodes.*, channels.title as channel_title,
  //       channels.image_url as channel_image_url,
  //       group_concat(channel_label.label_id) as labels
  //     FROM episodes
  //     INNER JOIN channels ON channels.id = episodes.channel_id
  //     LEFT JOIN channel_label ON channels.id = chanel_label.channel_id
  //     WHERE guid = ?
  //     GROUP BY episode.id""",
  //       [guid],
  //     );
  //     return row != null ? Episode.fromSqlite(row) : null;
  //   } on Exception {
  //     rethrow;
  //   }
  // }

  // // not used
  // Future<int> createEpisode(Episode episode) async {
  //   try {
  //     final data = episode.toSqlite();
  //     data.remove('id');
  //     final args = List.filled(data.length, '?').join(',');
  //     final sets = data.keys.map((e) => '$e = ?').join(',');
  //     return await _dbSrv.insert(
  //       "INSERT INTO episodes(${data.keys.join(',')}) VALUES($args)"
  //       " ON CONFLICT(guid) DO UPDATE SET $sets",
  //       [...data.values, ...data.values],
  //     );
  //   } on Exception {
  //     rethrow;
  //   }
  // }

  // // not used
  // Future<int> updateEpisode(int episodeId, Map<String, Object?> data) async {
  //   try {
  //     final sets = data.keys.map((e) => '$e = ?').join(',');
  //     return await _dbSrv.update("UPDATE episodes SET $sets WHERE id = ?", [
  //       ...data.values,
  //       episodeId,
  //     ]);
  //   } on Exception {
  //     rethrow;
  //   }
  // }

  // // not used
  // Future deleteEpisode(String guid) async {
  //   try {
  //     await _dbSrv.delete("DELETE FROM episodes WHERE guid = ?", [guid]);
  //   } on Exception {
  //     rethrow;
  //   }
  // }

  // Settings

  // // not used
  // Future<Settings?> getSettings() async {
  //   try {
  //     final row = await _dbSrv.query("SELECT * from settings");
  //     return row != null ? Settings.fromSqlite(row) : null;
  //   } on Exception {
  //     rethrow;
  //   }
  // }

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

  // labels

  Future<List<Label>> getLabels() async {
    final rows = await _dbSrv.queryAll("SELECT * FROM labels");
    return rows.map((e) => Label.fromSqlite(e)).toList();
  }

  Future<bool> updateLabel(Label label) async {
    if (label.id != null) {
      // only change title
      final count = await _dbSrv.update(
        """UPDATE labels SET title = ? WHERE id = ?""",
        [label.title, label.id],
      );
      return count == 1;
    }
    return false;
  }

  Future<bool> addLabelToChannel(int channelId, int labelId) async {
    final count = await _dbSrv.insert(
      """INSERT INTO channel_label (channel_id, label_id)
      VALUES (?, ?) ON CONFLICT DO NOTHING""",
      [channelId, labelId],
    );
    return count == 1;
  }

  Future<bool> removeLabelFromChannel(int channelId, int labelId) async {
    final count = await _dbSrv.delete(
      """DELETE FROM channel_label WHERE channel_id = ? AND label_id = ?""",
      [channelId, labelId],
    );
    return count == 1;
  }
}

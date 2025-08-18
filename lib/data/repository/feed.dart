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
import '../../shared/constants.dart';
import '../../shared/helpers.dart';
import '../service/local/sqflite.dart';

class FeedRepository {
  final DatabaseService _dbSrv;
  FeedRepository({required DatabaseService dbSrv}) : _dbSrv = dbSrv;

  final _unesc = HtmlUnescape();
  // ignore: unused_field
  final _logger = Logger('FeedRespository');

  // Feed

  Future<Feed?> fetchFeed(String url) async {
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
          } else if (root.name.toString() == 'rdf:RDF') {
            return Feed.fromRdf(root, url);
          }
          _logger.severe('unknown feed format');
          // throw Exception('unknown feed format');
        }
      } else {
        // http error or non xlm document
        _logger.fine('${res.statusCode}: ${res.headers['content-type']}');
      }
    } catch (e) {
      _logger.severe(e.toString);
      // throw Exception(e.toString);
    }
    return null;
  }

  Future<bool> subscribe(Feed feed) async {
    _logger.fine('subscribe');
    if (await createChannel(feed.channel) > 0) {
      // save episodes
      final refDate = DateTime.now().subtract(
        Duration(days: dataRetentionPeriod),
      );
      for (final episode in feed.episodes) {
        _logger.fine('episode:$refDate - $episode');
        // save only up to maxRetentionDays ago
        if (episode.published.isBefore(refDate) != true) {
          episode.channelId = feed.channel.id;
          await createEpisode(episode);
        }
      }
      return true;
    }
    return false;
  }

  Future unsubscribe(int channelId) async {
    _logger.fine('unsubscribe');
    try {
      await _dbSrv.delete("DELETE FROM episodes WHERE channel_id = ?", [
        channelId,
      ]);
      await _dbSrv.delete("DELETE FROM channels WHERE id = ?", [channelId]);
    } on Exception catch (e) {
      // rethrow;
      _logger.severe(e.toString());
    }
  }

  Future refreshFeeds({bool force = false}) async {
    _logger.fine('updateFeeds: $force');
    final channels = await getChannels();
    for (final channel in channels) {
      final today = DateTime.now();

      // published date is more than a period ago
      bool pubExpected =
          channel.published != null &&
          today.isAfter(
            channel.published!.add(
              Duration(days: channel.period ?? defaultUpdatePeriod),
            ),
          );

      // checked date is more than a period ago
      bool chkRequired =
          channel.checked != null &&
          today.isAfter(
            channel.checked!.add(
              Duration(days: channel.period ?? defaultUpdatePeriod),
            ),
          );

      _logger.fine(
        'channel:${channel.id} pubExpected:$pubExpected, chkRequired:$chkRequired',
      );

      if (force || (pubExpected && chkRequired)) {
        _logger.fine('pub:${channel.published}, chk:${channel.checked}');
        await refreshChannel(channel);
      }
    }
  }

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

  Future<int> createChannel(Channel channel) async {
    // print('createChannel:$channel');
    try {
      final data = channel.toSqlite();
      // data.remove('id');
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

  Future<bool> refreshChannel(Channel channel) async {
    _logger.fine('refreshChannel: ${channel.id}');
    final feed = await fetchFeed(channel.url);
    if (feed != null) {
      // overwrite channel id
      feed.channel.id = channel.id;
      // mark checked
      await updateChannel(channel.id, {
        "checked": DateTime.now().toIso8601String(),
      });
      // reference date
      final refDate = DateTime.now().subtract(
        Duration(days: dataRetentionPeriod),
      );
      for (final episode in feed.episodes) {
        // inject channel id field
        episode.channelId = channel.id;
        // _log.fine('episode:${episode.guid}.${episode.published}');
        // update only back to reference date
        if (episode.published.isBefore(refDate) != true) {
          // _log.fine('create:${episode.title}');
          await _refreshEpisode(episode);
        }
      }
      // remove expired episodes and their data
      await _purgeEpisodes(channel.id);
      return true;
    }
    return false;
  }

  // Episode

  Future<List<Episode>> getEpisodes({int period = defaultDisplayPeriod}) async {
    final start = yymmdd(DateTime.now().subtract(Duration(days: period)));
    print('start:$start');
    try {
      final rows = await _dbSrv.queryAll(
        """
      SELECT episodes.*, channels.title as channel_title,
        channels.image_url as channel_image_url,
        group_concat(channel_label.label_id) as labels
      FROM episodes
      INNER JOIN channels ON channels.id = episodes.channel_id
      LEFT JOIN channel_label ON channel_label.channel_id = episodes.channel_id
      WHERE DATE(episodes.published) > ?
      GROUP BY episodes.id
      ORDER BY episodes.published DESC
      """,
        [start],
      );
      return rows.map((e) => Episode.fromSqlite(e)).toList();
    } on Exception {
      rethrow;
    }
  }

  Future<List<Episode>> fetchEpisodes() async {
    final episodes = <Episode>[];

    final channels = await getChannels();
    for (final channel in channels) {
      final feed = await fetchFeed(channel.url);
      if (feed != null) {
        for (final item in feed.episodes) {
          item.channelUrl = channel.url;
          item.channelTitle = channel.title;
          item.channelImageUrl = channel.imageUrl;
          item.labels = channel.labels;
          episodes.add(item);
        }
      }
    }
    return episodes..sort((a, b) => b.published.compareTo(a.published));
  }

  Future<List<Episode>> getEpisodesByChannel(
    int channelId, {
    int period = defaultDisplayPeriod,
  }) async {
    final start = yymmdd(DateTime.now().subtract(Duration(days: period)));
    try {
      final rows = await _dbSrv.queryAll(
        """
      SELECT episodes.*, channels.title as channel_title,
        channels.image_url as channel_image_url,
        group_concat(channel_label.label_id) as labels
      FROM episodes
      INNER JOIN channels ON channels.id = episodes.channel_id
      LEFT JOIN channel_label ON channel_label.channel_id = episodes.channel_id
      WHERE episodes.channel_id = ?
        AND DATE(episodes.published) > ?
      GROUP BY episodes.id
      ORDER BY episodes.published DESC""",
        [channelId, start],
      );
      return rows.map((e) => Episode.fromSqlite(e)).toList();
    } on Exception {
      rethrow;
    }
  }

  Future<int> createEpisode(Episode episode) async {
    print('createEpisode:$episode');
    try {
      final data = episode.toSqlite();
      // data.remove('id');
      final args = List.filled(data.length, '?').join(',');
      final sets = data.keys.map((e) => '$e = ?').join(',');
      return await _dbSrv.insert(
        "INSERT INTO episodes(${data.keys.join(',')}) VALUES($args)"
        " ON CONFLICT(guid) DO UPDATE SET $sets",
        [...data.values, ...data.values],
      );
    } on Exception catch (e) {
      _logger.severe(e.toString());
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

  // Internal use

  Future _refreshEpisode(Episode episode) async {
    final data = episode.toSqlite();
    // fields that have to be retained
    data.remove('liked');
    data.remove('played');
    try {
      _logger.fine('upsert episode:${episode.id}');
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

  Future _purgeEpisodes(int? channelId) async {
    try {
      if (channelId != null) {
        _logger.fine('purgeChannel');
        final episodes = await getEpisodesByChannel(channelId);
        final refDate = DateTime.now().subtract(
          Duration(days: dataRetentionPeriod),
        );
        for (final episode in episodes) {
          // delete expired episodes and its local media data
          if (episode.published.isBefore(refDate) == true) {
            await _dbSrv.delete("DELETE FROM episodes WHERE guid = ?", [
              episode.guid,
            ]);
          }
        }
      }
    } on Exception {
      rethrow;
    }
  }
}

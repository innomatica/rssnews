import 'package:flutter/material.dart';
import 'package:rssnews/data/repository/feed.dart';

class CuratedViewModel extends ChangeNotifier {
  final FeedRepository _feedRepo;
  CuratedViewModel({required FeedRepository feedRepo}) : _feedRepo = feedRepo;

  Future load() async {
    await _feedRepo.getSampleFeedInfo();
  }
}

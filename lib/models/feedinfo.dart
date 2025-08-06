import 'dart:convert';

const sampleFeedInfo = [
  {
    'title': 'Community',
    'url':
        'https://raw.githubusercontent.com/innomatica/rssnews/refs/heads/master/data/feeds/community.json',
  },
  {
    'title': 'Gadgets',
    'url':
        'https://raw.githubusercontent.com/innomatica/rssnews/refs/heads/master/data/feeds/gadgets.json',
  },
  {
    'title': 'Government',
    'url':
        'https://raw.githubusercontent.com/innomatica/rssnews/refs/heads/master/data/feeds/government.json',
  },
  {
    'title': 'Korean',
    'url':
        'https://raw.githubusercontent.com/innomatica/rssnews/refs/heads/master/data/feeds/korean.json',
  },
  {
    'title': 'News',
    'url':
        'https://raw.githubusercontent.com/innomatica/rssnews/refs/heads/master/data/feeds/news.json',
  },
  {
    'title': 'Science',
    'url':
        'https://raw.githubusercontent.com/innomatica/rssnews/refs/heads/master/data/feeds/science.json',
  },
  {
    'title': 'Technology',
    'url':
        'https://raw.githubusercontent.com/innomatica/rssnews/refs/heads/master/data/feeds/technology.json',
  },
];

class FeedInfo {
  String title;
  String website;
  String description;
  String language;
  String keywords;
  String feedUrl;
  String favicon;

  FeedInfo({
    required this.title,
    required this.website,
    required this.description,
    required this.language,
    required this.keywords,
    required this.feedUrl,
    required this.favicon,
  });

  factory FeedInfo.fromJson(String data) {
    final decoded = jsonDecode(data);
    return FeedInfo(
      title: decoded['title'],
      website: decoded['website'],
      description: decoded['description'],
      language: decoded['language'],
      keywords: decoded['keywords'],
      feedUrl: decoded['feedUrl'],
      favicon: decoded['favicon'],
    );
  }
}

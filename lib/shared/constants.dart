import 'package:flutter/material.dart' show Colors;

const appName = "RssNews";
const appVersion = '1.0.5+6';
const appId = 'com.innomatic.rssnews';

const developerWebsite = 'https://innomatic.ca';
const sourceRepository = 'https://github.com/innomatica/rssnews';
const releaseUrl = 'https://github.com/innomatica/rssnews/releases';

// stock images
const assetImageNewspaper = 'assets/images/newspaper.png';
const assImageRssIcon = 'assets/images/rss.png';

// search engine
const ecosiaQueryUrl = 'https://ecosia.org/search?q=';
const duckduckgoQueryUrl = 'https://duckduckgo.com/?q=';
const braveSearchQueryUrl = 'https://search.brave.com/search?q=';
const defaultQueryUrl = ecosiaQueryUrl;

// retention days
const displayPeriods = [1, 2, 3, 7, 14, 28];
const defaultDisplayPeriod = 7;
const pKeyDisplayPeriod = "displayPeriod";
final dataRetentionPeriod = displayPeriods.last;

// feed update period
// const defaultUpdatePeriod = 1;
// const updatePeriods = [1, 2, 3, 4, 5, 6, 7];

// label colors
const labelColor = [
  Colors.white,
  Colors.amber,
  Colors.blue,
  Colors.brown,
  Colors.cyan,
  Colors.green,
  Colors.indigo,
  Colors.lime,
  Colors.orange,
  Colors.pink,
  Colors.purple,
  Colors.red,
  Colors.teal,
  Colors.yellow,
];

const pKeySelectedLabelId = 'selLabelId';

// feed update period
const defaultUpdatePeriod = 1;

// channel thumbnail image file name
const chnImgFname = 'thumbnail';

// application document directory path
late final String appDocPath;

// image size
const faviconSizeSmall = 12.0;
const faviconSizeLarge = 24.0;

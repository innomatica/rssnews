const appName = "RssNews";
const appVersion = '1.0.0+1';
const appId = 'com.innomatic.rssnews';

const developerWebsite = 'https://innomatic.ca';
const sourceRepository = 'https://github.com/innomatica/rssnews';

// stock images
const defaultChannelImage = 'assets/images/newspaper.png';
const defaultFeedImage = 'assets/images/rss.png';

// search engine
const ecosiaQueryUrl = 'https://ecosia.org/search?q=';
const duckduckgoQueryUrl = 'https://duckduckgo.com/?q=';
const braveSearchQueryUrl = 'https://search.brave.com/search?q=';
const defaultQueryUrl = ecosiaQueryUrl;

// retention days
const retentionDays = [30, 60, 90, 180];
const defaultRetentionDays = 90;
final maxRetentionDays = retentionDays.last;

// feed update period
const defaultUpdatePeriod = 1;
const updatePeriods = [1, 2, 3, 4, 5, 6, 7];

// channel thumbnail image file name
const channelImgFname = 'thumbnail';

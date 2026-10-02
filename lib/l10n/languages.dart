/// One selectable site language. Each has a matching
/// `assets/i18n/<code>.json` translation file.
class SiteLanguage {
  final String code;
  final String englishName;
  final String nativeName;
  final bool isRtl;

  const SiteLanguage(this.code, this.englishName, this.nativeName, {this.isRtl = false});
}

const Map<String, SiteLanguage> kLanguages = {
  'en': SiteLanguage('en', 'English', 'English'),
  'zh': SiteLanguage('zh', 'Chinese (Mandarin)', '中文'),
  'hi': SiteLanguage('hi', 'Hindi', 'हिन्दी'),
  'es': SiteLanguage('es', 'Spanish', 'Español'),
  'ar': SiteLanguage('ar', 'Arabic', 'العربية', isRtl: true),
  'fr': SiteLanguage('fr', 'French', 'Français'),
  'bn': SiteLanguage('bn', 'Bengali', 'বাংলা'),
  'pt': SiteLanguage('pt', 'Portuguese', 'Português'),
  'ru': SiteLanguage('ru', 'Russian', 'Русский'),
  'id': SiteLanguage('id', 'Indonesian', 'Bahasa Indonesia'),
  'ur': SiteLanguage('ur', 'Urdu', 'اردو', isRtl: true),
  'de': SiteLanguage('de', 'German', 'Deutsch'),
  'ja': SiteLanguage('ja', 'Japanese', '日本語'),
  'mr': SiteLanguage('mr', 'Marathi', 'मराठी'),
  'vi': SiteLanguage('vi', 'Vietnamese', 'Tiếng Việt'),
  'te': SiteLanguage('te', 'Telugu', 'తెలుగు'),
  'ha': SiteLanguage('ha', 'Hausa', 'Hausa'),
  'tr': SiteLanguage('tr', 'Turkish', 'Türkçe'),
  'pa': SiteLanguage('pa', 'Punjabi', 'ਪੰਜਾਬੀ'),
  'sw': SiteLanguage('sw', 'Swahili', 'Kiswahili'),
  'ta': SiteLanguage('ta', 'Tamil', 'தமிழ்'),
  'gu': SiteLanguage('gu', 'Gujarati', 'ગુજરાતી'),
  'kn': SiteLanguage('kn', 'Kannada', 'ಕನ್ನಡ'),
  'or': SiteLanguage('or', 'Odia', 'ଓଡ଼ିଆ'),
  'ml': SiteLanguage('ml', 'Malayalam', 'മലയാളം'),
};

/// Top 20 most spoken languages worldwide by total speakers (approx.
/// Ethnologue ranking; regional dialects such as Egyptian Arabic and
/// Nigerian Pidgin are folded into their written standard / skipped).
const List<String> kGlobalTop20 = [
  'en',
  'zh',
  'hi',
  'es',
  'ar',
  'fr',
  'bn',
  'pt',
  'ru',
  'id',
  'ur',
  'de',
  'ja',
  'mr',
  'vi',
  'te',
  'ha',
  'tr',
  'pa',
  'sw',
];

/// Top 10 most spoken languages in India (Census of India ranking).
const List<String> kIndiaTop10 = ['hi', 'bn', 'mr', 'te', 'ta', 'gu', 'ur', 'kn', 'or', 'ml'];

const String kDefaultLanguage = 'en';

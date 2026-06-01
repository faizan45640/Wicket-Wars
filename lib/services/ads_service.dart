import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'app_logger.dart';

class AdsService {
  const AdsService._();

  static const String androidBannerTestUnit =
      'ca-app-pub-3940256099942544/6300978111';

  static Future<void> initialize() async {
    if (kIsWeb) return;
    await MobileAds.instance.initialize();
    AppLogger.info('Google Mobile Ads initialized');
  }
}

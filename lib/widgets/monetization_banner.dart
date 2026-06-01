import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ads_service.dart';
import '../services/app_logger.dart';
import '../theme/game_colors.dart';

class MonetizationBanner extends StatefulWidget {
  const MonetizationBanner({super.key});

  @override
  State<MonetizationBanner> createState() => _MonetizationBannerState();
}

class _MonetizationBannerState extends State<MonetizationBanner> {
  BannerAd? _ad;
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) return;
    _ad = BannerAd(
      adUnitId: AdsService.androidBannerTestUnit,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          AppLogger.info('Test banner ad loaded');
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          AppLogger.warning('Test banner ad failed: $error');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (kIsWeb || ad == null || !_loaded) {
      return Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: GameColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: GameColors.cardBorder),
        ),
        child: const Text(
          'Sponsored slot',
          style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w700),
        ),
      );
    }
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}

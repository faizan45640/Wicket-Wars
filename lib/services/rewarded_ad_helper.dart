import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'app_logger.dart';

class RewardedAdHelper {
  const RewardedAdHelper._();

  /// Google's official Android rewarded test unit.
  static const String androidRewardedTestUnit =
      'ca-app-pub-3940256099942544/5224354917';

  /// Loads and shows a single rewarded ad. Completes with `true` when the user
  /// earns the reward, `false` otherwise. On web (no ad SDK) it returns `true`
  /// so the reward flow stays demoable.
  static Future<bool> showRewardedAd() async {
    if (kIsWeb) return true;
    final completer = Completer<bool>();
    await RewardedAd.load(
      adUnitId: androidRewardedTestUnit,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          var earned = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete(earned);
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              AppLogger.warning('Rewarded ad show failed: $error');
              ad.dispose();
              if (!completer.isCompleted) completer.complete(false);
            },
          );
          ad.show(
            onUserEarnedReward: (_, __) {
              earned = true;
            },
          );
        },
        onAdFailedToLoad: (error) {
          AppLogger.warning('Rewarded ad failed to load: $error');
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );
    return completer.future;
  }
}

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/constants/app_constants.dart';
import '../../core/logger/app_logger.dart';

class AdService {
  static const String _tag = 'AdService';

  bool _isInitialized = false;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      AppLogger.i('Google Mobile Ads SDK initialized successfully.', _tag);
    } catch (e) {
      AppLogger.e('Failed to initialize AdMob: $e', tag: _tag);
    }
  }

  String get bannerAdUnitId {
    if (kDebugMode) {
      return AppConstants.adMobBannerId;
    }
    return Platform.isAndroid ? AppConstants.adMobBannerId : AppConstants.adMobBannerId;
  }

  String get interstitialAdUnitId {
    if (kDebugMode) {
      return AppConstants.adMobInterstitialId;
    }
    return Platform.isAndroid ? AppConstants.adMobInterstitialId : AppConstants.adMobInterstitialId;
  }

  String get rewardedAdUnitId {
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544/5224354917';
    }
    return 'ca-app-pub-3940256099942544/5224354917';
  }

  void loadInterstitialAd({bool isPremium = false}) {
    if (isPremium || !_isInitialized) return;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          AppLogger.i('Interstitial ad loaded.', _tag);
        },
        onAdFailedToLoad: (error) {
          AppLogger.w('Interstitial ad failed to load: $error', _tag);
          _interstitialAd = null;
        },
      ),
    );
  }

  void showInterstitialAd({bool isPremium = false, VoidCallback? onAdClosed}) {
    if (isPremium || _interstitialAd == null) {
      onAdClosed?.call();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        onAdClosed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        onAdClosed?.call();
      },
    );

    _interstitialAd!.show();
  }

  void loadRewardedAd({bool isPremium = false}) {
    if (isPremium || !_isInitialized) return;

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          AppLogger.i('Rewarded ad loaded.', _tag);
        },
        onAdFailedToLoad: (error) {
          AppLogger.w('Rewarded ad failed to load: $error', _tag);
          _rewardedAd = null;
        },
      ),
    );
  }

  void showRewardedAd({
    bool isPremium = false,
    required Function(RewardItem) onEarnedReward,
    VoidCallback? onAdClosed,
  }) {
    if (isPremium || _rewardedAd == null) {
      onAdClosed?.call();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        onAdClosed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        onAdClosed?.call();
      },
    );

    _rewardedAd!.show(onUserEarnedReward: (_, reward) {
      onEarnedReward(reward);
    });
  }
}

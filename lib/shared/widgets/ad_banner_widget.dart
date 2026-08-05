import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../config/injection/injection_container.dart';
import '../../services/monetization/ad_service.dart';
import '../../services/monetization/billing_service.dart';

class AdBannerWidget extends StatefulWidget {
  final bool isNativeStyle;

  const AdBannerWidget({super.key, this.isNativeStyle = false});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  late BillingService _billingService;

  @override
  void initState() {
    super.initState();
    _billingService = sl<BillingService>();
    _loadAdIfNeeded();
  }

  void _loadAdIfNeeded() {
    if (_billingService.isPremium) return;

    final adService = sl<AdService>();
    _bannerAd = BannerAd(
      adUnitId: adService.bannerAdUnitId,
      size: widget.isNativeStyle ? AdSize.mediumRectangle : AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() => _isAdLoaded = true);
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerAd = null;
          if (mounted) {
            setState(() => _isAdLoaded = false);
          }
        },
      ),
    );

    _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_billingService.isPremium || !_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

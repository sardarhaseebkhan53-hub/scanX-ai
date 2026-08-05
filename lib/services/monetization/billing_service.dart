import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../core/constants/app_constants.dart';
import '../../core/logger/app_logger.dart';

class BillingService {
  static const String _tag = 'BillingService';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isPremium = false;
  bool get isPremium => _isPremium;

  final StreamController<bool> _premiumStatusController = StreamController<bool>.broadcast();
  Stream<bool> get premiumStatusStream => _premiumStatusController.stream;

  List<ProductDetails> _availableProducts = [];
  List<ProductDetails> get availableProducts => _availableProducts;

  Future<void> init() async {
    try {
      final bool available = await _iap.isAvailable();
      if (!available) {
        AppLogger.w('Google Play Billing store is not available on this device.', _tag);
        return;
      }

      _subscription = _iap.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => _subscription?.cancel(),
        onError: (error) => AppLogger.e('Purchase stream error: $error', tag: _tag),
      );

      await _loadProducts();
    } catch (e) {
      AppLogger.w('Play Billing initialization fallback: $e', _tag);
    }
  }

  Future<void> _loadProducts() async {
    try {
      const Set<String> ids = {
        AppConstants.monthlySubscriptionId,
        AppConstants.annualSubscriptionId,
        AppConstants.lifetimePurchaseId,
      };

      final ProductDetailsResponse response = await _iap.queryProductDetails(ids);
      if (response.error == null) {
        _availableProducts = response.productDetails;
        AppLogger.i('Loaded ${_availableProducts.length} Play Store billing products.', _tag);
      }
    } catch (e) {
      AppLogger.w('Error querying Play Store billing products: $e', _tag);
    }
  }

  Future<bool> buyProduct(ProductDetails product) async {
    try {
      final PurchaseParam param = PurchaseParam(productDetails: product);
      return _iap.buyNonConsumable(purchaseParam: param);
    } catch (e) {
      AppLogger.e('Buy product failed: $e', tag: _tag);
      return false;
    }
  }

  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
      AppLogger.w('Restore purchases failed: $e', _tag);
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final p in purchases) {
      if (p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored) {
        _setPremiumStatus(true);
        if (p.pendingCompletePurchase) {
          _iap.completePurchase(p);
        }
      }
    }
  }

  void _setPremiumStatus(bool status) {
    _isPremium = status;
    _premiumStatusController.add(status);
    AppLogger.i('Premium status changed to: $status', _tag);
  }

  void dispose() {
    _subscription?.cancel();
    _premiumStatusController.close();
  }
}

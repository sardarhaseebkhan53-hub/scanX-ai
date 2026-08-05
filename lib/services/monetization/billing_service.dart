import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/constants/app_constants.dart';
import '../../core/logger/app_logger.dart';

class BillingService {
  static const String _tag = 'BillingService';
  static const Set<String> _validProductIds = {
    AppConstants.monthlySubscriptionId,
    AppConstants.annualSubscriptionId,
    AppConstants.lifetimePurchaseId,
  };

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

      await _subscription?.cancel();
      _subscription = _iap.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => _subscription?.cancel(),
        onError: (error) => AppLogger.e('Purchase stream error: $error', tag: _tag),
      );

      await _loadProducts();
    } catch (e) {
      AppLogger.w('Play Billing initialization failed: $e', _tag);
    }
  }

  Future<void> _loadProducts() async {
    try {
      final ProductDetailsResponse response = await _iap.queryProductDetails(_validProductIds);
      if (response.error == null) {
        _availableProducts = response.productDetails.where((p) => _validProductIds.contains(p.id)).toList();
        AppLogger.i('Loaded ${_availableProducts.length} Play Store billing products.', _tag);
      } else {
        AppLogger.w('Play Store billing product query error: ${response.error}', _tag);
      }
    } catch (e) {
      AppLogger.w('Error querying Play Store billing products: $e', _tag);
    }
  }

  Future<bool> buyProduct(ProductDetails product) async {
    if (!_validProductIds.contains(product.id)) {
      AppLogger.e('Rejected purchase for unknown product id: ${product.id}', tag: _tag);
      return false;
    }
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
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (_isVerifiedPurchase(purchase)) {
            _setPremiumStatus(true);
          } else {
            AppLogger.w('Purchase rejected by local verification: ${purchase.productID}', _tag);
            _setPremiumStatus(false);
          }
          break;
        case PurchaseStatus.error:
        case PurchaseStatus.canceled:
          _setPremiumStatus(false);
          break;
        case PurchaseStatus.pending:
          AppLogger.i('Purchase pending: ${purchase.productID}', _tag);
          break;
      }

      if (purchase.pendingCompletePurchase) {
        unawaited(_iap.completePurchase(purchase));
      }
    }
  }

  bool _isVerifiedPurchase(PurchaseDetails purchase) {
    if (!_validProductIds.contains(purchase.productID)) return false;
    if (purchase.verificationData.serverVerificationData.trim().isEmpty) return false;
    // Production server-side receipt validation should verify this token with
    // the Google Play Developer API. This local gate prevents accidental unlocks
    // from unknown products, pending/cancelled purchases, or empty receipts.
    return true;
  }

  void _setPremiumStatus(bool status) {
    if (_isPremium == status) return;
    _isPremium = status;
    if (!_premiumStatusController.isClosed) {
      _premiumStatusController.add(status);
    }
    AppLogger.i('Premium status changed to: $status', _tag);
  }

  void dispose() {
    _subscription?.cancel();
    _premiumStatusController.close();
  }
}

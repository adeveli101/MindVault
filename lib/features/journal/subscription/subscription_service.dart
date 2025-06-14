// ignore_for_file: depend_on_referenced_packages, unused_import

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class SubscriptionService {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final StreamController<List<PurchaseDetails>> _purchaseStreamController = StreamController<List<PurchaseDetails>>.broadcast();
  final SharedPreferences _prefs;
  static const String _subscriptionKey = 'is_subscribed';
  static const String _purchaseTokenKey = 'purchase_token';
  
  // Subscription product IDs
  static const String _subscriptionProductId = 'mindvault_sub';

  SubscriptionService(this._prefs) {
    // Satın alma stream'ini dinle
    _inAppPurchase.purchaseStream.listen(
      (purchaseDetailsList) {
        _purchaseStreamController.add(purchaseDetailsList);
        _handlePurchaseUpdates(purchaseDetailsList);
      },
      onDone: () {
        _purchaseStreamController.close();
      },
      onError: (error) {
        debugPrint('Purchase stream error: $error');
      },
    );
  }

  Stream<List<PurchaseDetails>> get purchaseStream => _purchaseStreamController.stream;

  Future<bool> isSubscribed() async {
    try {
      // Önce local storage'dan kontrol et
      final isSubscribed = _prefs.getBool(_subscriptionKey) ?? false;
      if (!isSubscribed) return false;

      // Satın alma token'ı varsa doğrula
      final purchaseToken = _prefs.getString(_purchaseTokenKey);
      if (purchaseToken != null) {
        // TODO: Server-side verification yapılmalı
        // Şimdilik token varsa true dönüyoruz
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error checking subscription status: $e');
      return false;
    }
  }

  Future<Map<String, String?>> loadProductDetails() async {
    try {
      final bool available = await _inAppPurchase.isAvailable();
      if (!available) {
        debugPrint('Store not available');
        return {};
      }

      final Set<String> ids = {_subscriptionProductId};
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(ids);

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Products not found: [33m${response.notFoundIDs}[0m');
      }

      final Map<String, String?> prices = {};
      for (var product in response.productDetails) {
        // Since only one product is returned, use its price for all plans
        prices['mindvault-sub-weekly'] = product.price;
        prices['subs'] = product.price;
        prices['free-premium'] = product.price;
      }

      return prices;
    } catch (e) {
      debugPrint('Error loading product details: $e');
      return {};
    }
  }

  Future<bool> purchaseSubscription(String productId) async {
    try {
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails({productId});
      if (response.productDetails.isEmpty) {
        debugPrint('Product not found: $productId');
        return false;
      }

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: response.productDetails.first,
      );

      return await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('Error purchasing subscription: $e');
      return false;
    }
  }

  Future<void> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      rethrow;
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // Satın alma başarılı, token'ı kaydet
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
        await _prefs.setString(_purchaseTokenKey, purchaseDetails.purchaseID ?? '');
        await _prefs.setBool(_subscriptionKey, true);
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // Satın alma hatası, token'ı temizle
        await _prefs.remove(_purchaseTokenKey);
        await _prefs.setBool(_subscriptionKey, false);
      }
    }
  }

  Future<void> _verifyPurchase(String purchaseToken) async {
    // TODO: Implement server-side verification
    // Bu kısım backend entegrasyonu gerektiriyor
    // Şimdilik sadece token'ın varlığını kontrol ediyoruz
    return;
  }
} 
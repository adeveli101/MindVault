// ignore_for_file: depend_on_referenced_packages, unused_import

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionService {
  static const String _productId = 'mindvault_sub';
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final SharedPreferences _prefs;
  
  SubscriptionService(this._prefs);
  
  // Subscription durumunu kontrol et
  Future<bool> isSubscribed() async {
    return _prefs.getBool('is_subscribed') ?? false;
  }
  
  // Ürün detaylarını yükle
  Future<ProductDetails?> loadProductDetails() async {
    final Set<String> kIds = <String>{_productId};
    
    final ProductDetailsResponse response = 
        await _inAppPurchase.queryProductDetails(kIds);
    
    if (response.notFoundIDs.isNotEmpty) {
      if (kDebugMode) {
        print('Ürün bulunamadı: ${response.notFoundIDs}');
      }
      return null;
    }
    
    if (response.productDetails.isEmpty) {
      if (kDebugMode) {
        print('Ürün detayları boş');
      }
      return null;
    }
    
    return response.productDetails.first;
  }
  
  // Subscription satın al
  Future<bool> purchaseSubscription() async {
    final product = await loadProductDetails();
    if (product == null) return false;
    
    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: product,
    );
    
    try {
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Satın alma hatası: $e');
      }
      return false;
    }
  }
  
  // Satın alma işlemlerini dinle
  Stream<List<PurchaseDetails>> get purchaseStream => 
      _inAppPurchase.purchaseStream;
      
  // Subscription durumunu kaydet
  Future<void> saveSubscriptionStatus(bool isSubscribed) async {
    await _prefs.setBool('is_subscribed', isSubscribed);
  }
} 
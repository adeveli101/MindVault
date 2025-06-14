import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import 'subscription_service.dart';

// Events
abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();

  @override
  List<Object> get props => [];
}

class LoadSubscriptionStatus extends SubscriptionEvent {}

class PurchaseSubscription extends SubscriptionEvent {
  final String productId;

  const PurchaseSubscription(this.productId);

  @override
  List<Object> get props => [productId];
}

class RestorePurchases extends SubscriptionEvent {}

// States
abstract class SubscriptionState extends Equatable {
  const SubscriptionState();

  @override
  List<Object> get props => [];
}

class SubscriptionInitial extends SubscriptionState {}

class SubscriptionLoading extends SubscriptionState {}

class SubscriptionLoaded extends SubscriptionState {
  final bool isSubscribed;
  final Map<String, String?> prices;

  const SubscriptionLoaded({
    required this.isSubscribed,
    required this.prices,
  });

  @override
  List<Object> get props => [isSubscribed, prices];
}

class SubscriptionError extends SubscriptionState {
  final String message;

  const SubscriptionError(this.message);

  @override
  List<Object> get props => [message];
}

// Bloc
class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final SubscriptionService _subscriptionService;
  StreamSubscription<List<PurchaseDetails>>? _purchaseStreamSubscription;

  SubscriptionBloc(this._subscriptionService) : super(SubscriptionInitial()) {
    on<LoadSubscriptionStatus>(_onLoadSubscriptionStatus);
    on<PurchaseSubscription>(_onPurchaseSubscription);
    on<RestorePurchases>(_onRestorePurchases);

    // Satın alma stream'ini dinle
    _purchaseStreamSubscription = _subscriptionService.purchaseStream.listen(
      (purchaseDetailsList) {
        for (final purchaseDetails in purchaseDetailsList) {
          if (purchaseDetails.status == PurchaseStatus.purchased ||
              purchaseDetails.status == PurchaseStatus.restored) {
            add(LoadSubscriptionStatus());
          } else if (purchaseDetails.status == PurchaseStatus.error) {
            add(LoadSubscriptionStatus());
          }
        }
      },
      onError: (error) {
        debugPrint('Purchase stream error: $error');
        add(LoadSubscriptionStatus());
      },
    );
  }

  Future<void> _onLoadSubscriptionStatus(
    LoadSubscriptionStatus event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      emit(SubscriptionLoading());
      final isSubscribed = await _subscriptionService.isSubscribed();
      final prices = await _subscriptionService.loadProductDetails();
      emit(SubscriptionLoaded(isSubscribed: isSubscribed, prices: prices));
    } catch (e) {
      debugPrint('Error loading subscription status: $e');
      emit(SubscriptionError('Failed to load subscription status'));
    }
  }

  Future<void> _onPurchaseSubscription(
    PurchaseSubscription event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      emit(SubscriptionLoading());
      final success = await _subscriptionService.purchaseSubscription(event.productId);
      if (!success) {
        emit(SubscriptionError('Failed to initiate purchase'));
      }
    } catch (e) {
      debugPrint('Error purchasing subscription: $e');
      emit(SubscriptionError('Failed to purchase subscription'));
    }
  }

  Future<void> _onRestorePurchases(
    RestorePurchases event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      emit(SubscriptionLoading());
      await _subscriptionService.restorePurchases();
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      emit(SubscriptionError('Failed to restore purchases'));
    }
  }

  @override
  Future<void> close() {
    _purchaseStreamSubscription?.cancel();
    return super.close();
  }
} 
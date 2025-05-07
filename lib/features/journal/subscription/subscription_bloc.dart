import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mindvault/features/journal/subscription/subscription_service.dart';

// Events
abstract class SubscriptionEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoadSubscriptionStatus extends SubscriptionEvent {}
class PurchaseSubscription extends SubscriptionEvent {}
class UpdateSubscriptionStatus extends SubscriptionEvent {
  final bool isSubscribed;
  
  UpdateSubscriptionStatus(this.isSubscribed);
  
  @override
  List<Object> get props => [isSubscribed];
}

// States
abstract class SubscriptionState extends Equatable {
  @override
  List<Object> get props => [];
}

class SubscriptionInitial extends SubscriptionState {}
class SubscriptionLoading extends SubscriptionState {}
class SubscriptionLoaded extends SubscriptionState {
  final bool isSubscribed;
  final String? price;
  final String? description;
  
  SubscriptionLoaded({
    required this.isSubscribed,
    this.price,
    this.description,
  });
  
  @override
  List<Object> get props => [isSubscribed, price ?? '', description ?? ''];
}
class SubscriptionError extends SubscriptionState {
  final String message;
  
  SubscriptionError(this.message);
  
  @override
  List<Object> get props => [message];
}

// BLoC
class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final SubscriptionService _subscriptionService;
  
  SubscriptionBloc(this._subscriptionService) : super(SubscriptionInitial()) {
    on<LoadSubscriptionStatus>(_onLoadSubscriptionStatus);
    on<PurchaseSubscription>(_onPurchaseSubscription);
    on<UpdateSubscriptionStatus>(_onUpdateSubscriptionStatus);
  }
  
  Future<void> _onLoadSubscriptionStatus(
    LoadSubscriptionStatus event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());
    try {
      final isSubscribed = await _subscriptionService.isSubscribed();
      final productDetails = await _subscriptionService.loadProductDetails();
      
      emit(SubscriptionLoaded(
        isSubscribed: isSubscribed,
        price: productDetails?.price,
        description: productDetails?.description,
      ));
    } catch (e) {
      emit(SubscriptionError(e.toString()));
    }
  }
  
  Future<void> _onPurchaseSubscription(
    PurchaseSubscription event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());
    try {
      final success = await _subscriptionService.purchaseSubscription();
      if (success) {
        await _subscriptionService.saveSubscriptionStatus(true);
        emit(SubscriptionLoaded(isSubscribed: true));
      } else {
        emit(SubscriptionError('Satın alma işlemi başarısız oldu'));
      }
    } catch (e) {
      emit(SubscriptionError(e.toString()));
    }
  }
  
  void _onUpdateSubscriptionStatus(
    UpdateSubscriptionStatus event,
    Emitter<SubscriptionState> emit,
  ) {
    emit(SubscriptionLoaded(isSubscribed: event.isSubscribed));
  }
} 
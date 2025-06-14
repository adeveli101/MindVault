// lib/features/journal/bloc_auth/auth_bloc.dart

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mindvault/features/journal/bloc_auth/auth_service.dart';

// State ve Event dosyalarını part olarak ekle
part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc({required AuthService authService})
      : _authService = authService,
        super(AuthInitial()) { // Başlangıç durumu AuthInitial
    // Olay dinleyicilerini kaydet
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<UnlockWithPin>(_onUnlockWithPin);
    on<UnlockWithBiometrics>(_onUnlockWithBiometrics);
    on<SetupPin>(_onSetupPin);
    on<RemovePin>(_onRemovePin);
    on<ToggleBiometrics>(_onToggleBiometrics);
    on<LockApp>(_onLockApp);

    // Uygulama başlarken durumu hemen kontrol etmesi için ilk eventi ekle
    add(CheckAuthStatus());
  }

  Future<void> _onCheckAuthStatus(
      CheckAuthStatus event, Emitter<AuthState> emit) async {
    // print("AuthBloc: Checking Auth Status..."); // Debug
    emit(AuthInProgress()); // Kontrol başladığında işlem sürüyor durumu
    await Future.delayed(const Duration(milliseconds: 100)); // Küçük bir gecikme (opsiyonel)
    try {
      final bool isPinSet = await _authService.isPinSet();
      if (isPinSet) {
        final bool canCheck = await _authService.canCheckBiometrics();
        final bool isEnabled = await _authService.isBiometricsEnabled();
        // print("AuthBloc: PIN is set. Emitting AuthLocked (canCheck: $canCheck, isEnabled: $isEnabled)"); // Debug
        emit(AuthLocked(canCheckBiometrics: canCheck, biometricsEnabled: isEnabled));
      } else {
        // print("AuthBloc: PIN is not set. Emitting AuthSetupRequired."); // Debug
        // PIN yoksa, kurulum gerekli durumu veya direkt kilitsiz durumu (uygulama mantığına göre)
        // Şimdilik kurulum gerekli diyelim. Ayarlardan etkinleştirilecek.
        emit(AuthSetupRequired());
      }
    } catch (e) {
      // print("AuthBloc: Error during CheckAuthStatus: $e"); // Debug
      emit(AuthFailure("Kimlik durumu kontrol edilemedi: ${e.toString()}"));
    }
  }

  Future<void> _onUnlockWithPin(
      UnlockWithPin event, Emitter<AuthState> emit) async {
    emit(AuthInProgress());
    try {
      final bool success = await _authService.verifyPin(event.pin);
      if (success) {
        emit(AuthUnlocked());
      } else {
        emit(const AuthFailure("Girilen PIN hatalı."));
        // Hata gösterildikten kısa süre sonra tekrar kilitli state'e dön
        await Future.delayed(const Duration(milliseconds: 800));
        // Tekrar kilitli duruma dönerken güncel biyometrik bilgilerini al
        final bool canCheck = await _authService.canCheckBiometrics();
        final bool isEnabled = await _authService.isBiometricsEnabled();
        emit(AuthLocked(canCheckBiometrics: canCheck, biometricsEnabled: isEnabled));
      }
    } catch (e) {
      // Rate limiting hatası veya diğer hatalar
      emit(AuthFailure(e.toString()));
      await Future.delayed(const Duration(milliseconds: 800));
      add(CheckAuthStatus());
    }
  }

  Future<void> _onUnlockWithBiometrics(
      UnlockWithBiometrics event, Emitter<AuthState> emit) async {
    // print("AuthBloc: Attempting unlock with biometrics..."); // Debug
    // Sadece kilitli ve biyometrik açıksa işlem yap
    if (state is AuthLocked && (state as AuthLocked).biometricsEnabled) {
      emit(AuthInProgress());
      try {
        final bool success = await _authService.authenticateWithBiometrics(
            "Uygulama kilidini açmak için kimliğinizi doğrulayın");
        if (success) {
          // print("AuthBloc: Biometrics successful. Emitting AuthUnlocked."); // Debug
          emit(AuthUnlocked());
        } else {
          // print("AuthBloc: Biometrics failed or cancelled. Emitting AuthLocked."); // Debug
          // Başarısız olursa sadece kilitli ekrana geri dön (PIN denenebilir)
          // Mevcut state'deki bilgileri koruyarak emit edelim
          emit(state);
        }
      } catch (e) {
        // print("AuthBloc: Error during UnlockWithBiometrics: $e"); // Debug
        emit(AuthFailure("Biyometrik doğrulama sırasında hata: ${e.toString()}"));
        await Future.delayed(const Duration(milliseconds: 800));
        emit(state); // Hata sonrası kilitli ekrana dön
      }
    } else {
      // print("AuthBloc: UnlockWithBiometrics ignored (not locked or biometrics not enabled)."); // Debug
    }
  }

  Future<void> _onSetupPin(SetupPin event, Emitter<AuthState> emit) async {
    // print("AuthBloc: Setting up new PIN..."); // Debug
    emit(AuthInProgress());
    try {
      await _authService.setPin(event.newPin);
      // print("AuthBloc: PIN setup successful. Emitting AuthLocked."); // Debug
      // Başarıyla ayarlandıktan sonra kilitli duruma geç
      final bool canCheck = await _authService.canCheckBiometrics();
      // Yeni PIN ayarlandığında biyometriği otomatik kapat (kullanıcı sonra açabilir)
      await _authService.setBiometricsEnabled(false);
      emit(AuthLocked(canCheckBiometrics: canCheck, biometricsEnabled: false));
    } catch (e) {
      // print("AuthBloc: Error during SetupPin: $e"); // Debug
      emit(AuthFailure("PIN ayarlanamadı: ${e.toString()}"));
      // Hata sonrası durumu tekrar kontrol et (muhtemelen hala PIN yoktur)
      await Future.delayed(const Duration(milliseconds: 800));
      add(CheckAuthStatus());
    }
  }

  Future<void> _onRemovePin(RemovePin event, Emitter<AuthState> emit) async {
    // print("AuthBloc: Removing PIN..."); // Debug
    emit(AuthInProgress());
    try {
      await _authService.removePin();
      // print("AuthBloc: PIN removed successfully. Emitting AuthSetupRequired."); // Debug
      emit(AuthSetupRequired()); // PIN kalktı, kurulum gerekli
    } catch (e) {
      // print("AuthBloc: Error during RemovePin: $e"); // Debug
      emit(AuthFailure("PIN kaldırılamadı: ${e.toString()}"));
      // Hata sonrası durumu tekrar kontrol et (muhtemelen hala PIN vardır)
      await Future.delayed(const Duration(milliseconds: 800));
      add(CheckAuthStatus());
    }
  }

  Future<void> _onToggleBiometrics(
      ToggleBiometrics event, Emitter<AuthState> emit) async {
    // print("AuthBloc: Toggling biometrics to ${event.enable}..."); // Debug
    // Sadece Kilitli durumdaysa veya PIN ayarlı ama kilit açılmışsa (Ayarlar ekranında) mantıklı
    // ve cihaz destekliyorsa
    final bool canCheck = await _authService.canCheckBiometrics();
    if(!canCheck) {
      // print("AuthBloc: Cannot toggle biometrics, device doesn't support it."); // Debug
      // İsteğe bağlı: Kullanıcıya cihazın desteklemediği bilgisini verebilirsin
      // emit(AuthFailure("Cihazınız biyometrik doğrulamayı desteklemiyor."));
      // await Future.delayed(const Duration(milliseconds: 800));
      emit(state); // Mevcut durumu koru
      return;
    }

    // PIN ayarlı olmalı
    final bool isPinCurrentlySet = await _authService.isPinSet();
    if (!isPinCurrentlySet){
      // print("AuthBloc: Cannot toggle biometrics, PIN not set."); // Debug
      emit(state); // Mevcut durumu koru
      return;
    }


    // Geçici işlem durumu (opsiyonel, çok hızlı olabilir)
    // emit(AuthInProgress());
    try {
      await _authService.setBiometricsEnabled(event.enable);
      // print("AuthBloc: Biometrics toggled. Re-checking status..."); // Debug
      // Ayar değiştiği için AuthLocked state'ini güncel bilgilerle tekrar emit et
      // Veya daha basiti, durumu komple yeniden kontrol et
      add(CheckAuthStatus());
    } catch (e) {
      // print("AuthBloc: Error during ToggleBiometrics: $e"); // Debug
      emit(AuthFailure("Biyometrik ayarı değiştirilemedi: ${e.toString()}"));
      await Future.delayed(const Duration(milliseconds: 800));
      add(CheckAuthStatus()); // Hata sonrası durumu tekrar kontrol et
    }
  }

  void _onLockApp(LockApp event, Emitter<AuthState> emit) async {
    // print("AuthBloc: Locking app..."); // Debug
    // Kilitlemek için PIN'in ayarlı olması gerekir
    final bool isPinSet = await _authService.isPinSet();
    if (isPinSet) {
      final bool canCheck = await _authService.canCheckBiometrics();
      final bool isEnabled = await _authService.isBiometricsEnabled();
      emit(AuthLocked(canCheckBiometrics: canCheck, biometricsEnabled: isEnabled));
    } else {
      // print("AuthBloc: Cannot lock app, PIN not set."); // Debug
      // PIN ayarlı değilse kilitleyemez, belki uyarı verilebilir
      emit(AuthSetupRequired()); // Veya mevcut state korunur
    }
  }
}
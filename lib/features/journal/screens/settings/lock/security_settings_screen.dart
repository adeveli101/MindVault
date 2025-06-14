// lib/features/journal/screens/settings/lock/security_settings_screen.dart

// ignore_for_file: use_build_context_synchronously, unused_local_variable

import 'package:flutter/foundation.dart'; // kDebugMode için
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindvault/features/journal/bloc_auth/auth_bloc.dart';
import 'package:mindvault/features/journal/bloc_auth/auth_service.dart'; // AuthService import edildi
import 'package:mindvault/features/journal/screens/settings/lock/pinsetup_screen.dart';
import 'package:mindvault/features/journal/screens/themes/themed_background.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {

  bool _canCheckBiometrics = false;
  bool _isCheckingBiometrics = true;

  @override
  void initState() {
    super.initState();
    // initState içinde async işlem yapmaktan kaçınmak için post frame callback kullan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) { // Callback içinde mounted kontrolü önemli
        _checkBiometricCapability();
      }
    });
  }

  // Biyometrik yeteneğini kontrol et
  Future<void> _checkBiometricCapability() async {
    // initState sonrası context güvenli olmalı, ama yine de try-finally kullanalım
    if (!mounted) return; // Metot başında da kontrol
    final authService = context.read<AuthService>(); // BlocProvider'dan al
    bool canCheck = false;
    try {
      canCheck = await authService.canCheckBiometrics();
    } catch (e, stackTrace) {
      if (kDebugMode) { print("SecuritySettingsScreen: Error checking biometric capability: $e\n$stackTrace"); }
      // Hata durumunda kullanıcıya bilgi verilebilir
      if(mounted){
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            const SnackBar(content: Text('Biyometrik durumu kontrol edilemedi.'))
        );
      }
    } finally {
      // setState öncesi SON mounted kontrolü
      if (mounted) {
        setState(() {
          _canCheckBiometrics = canCheck;
          _isCheckingBiometrics = false;
        });
      }
    }
  }


  // PIN girişi dialogu
  Future<String?> _showPinEntryDialog(BuildContext context) {
    // Async gap öncesi gerekli değişkenleri al
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final pinController = TextEditingController();
    final pinFocusNode = FocusNode();

    // Pinput temalarını dialog içinde tanımla (context bağımlı)
    final defaultPinTheme = PinTheme(
        width: 45, height: 50,
        textStyle: TextStyle(fontSize: 20, color: colorScheme.onSurface),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outlineVariant)
        )
    );
    final focusedPinTheme = defaultPinTheme.copyWith(
        decoration: defaultPinTheme.decoration!.copyWith(
            border: Border.all(color: colorScheme.primary, width: 2)
        )
    );

    // Dialog açıldığında odaklanma
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // FocusNode dispose edilmiş olabilir mi diye kontrol etmek iyi olabilir
      if (pinFocusNode.context != null) {
        pinFocusNode.requestFocus();
      }
    });

    // context kullanımını showDialog builder içindeki `dialogContext` ile yap
    return showDialog<String>(
      context: context, // Ana context'i kullan
      barrierDismissible: true,
      builder: (dialogContext) { // Farklı bir context adı kullan
        return AlertDialog(
          title: Text(l10n.pinVerification),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.enterCurrentPin),
              const SizedBox(height: 20),
              Pinput(
                controller: pinController,
                focusNode: pinFocusNode,
                length: 6,
                obscureText: true, obscuringCharacter: '●',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: focusedPinTheme,
                // Hata durumunu burada yönetmek yerine dialog dışında handle edelim
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
                child: Text(l10n.cancel, style: TextStyle(color: Theme.of(dialogContext).colorScheme.secondary)), // dialogContext kullan
                onPressed: () => Navigator.of(dialogContext).pop(null) // dialogContext kullan
            ),
            TextButton(
                child: Text(l10n.verify),
                onPressed: () {
                  // Navigator'u dialogContext ile kullan
                  if (pinController.text.isNotEmpty) {
                    Navigator.of(dialogContext).pop(pinController.text);
                  } else {
                    HapticFeedback.lightImpact(); // Boş PIN için geri bildirim
                  }
                }
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          backgroundColor: Theme.of(dialogContext).colorScheme.surfaceContainerHigh, // dialogContext kullan
        );
      },
    ).whenComplete(() {
      // FocusNode'u dialog kapanınca dispose et
      pinFocusNode.dispose();
    });
  }

  // Genel kimlik doğrulama (Önce Biyometrik, sonra PIN)
  Future<bool> _promptForAuthentication(BuildContext context, {String reason = "Ayarı değiştirmek için kimliğinizi doğrulayın"}) async {
    // Async işlem öncesi gerekli nesneleri GÜVENLİ şekilde al
    // ScaffoldMessenger ve Navigator state değişikliklerine duyarlı olabilir, dikkatli kullan
    final authService = context.read<AuthService>(); // Bu genellikle güvenli
    bool authenticated = false;

    if (!mounted) return false; // İlk kontrol

    // Önce biyometrik durumu KONTROL ET (AuthService üzerinden)
    final bool isBioEnabled = await authService.isBiometricsEnabled();
    final bool canUseBio = await authService.canCheckBiometrics();

    // await sonrası mounted kontrolü ŞART!
    if (!mounted) return false;

    // Biyometrik mümkün ve etkinse, önce onu dene
    if (canUseBio && isBioEnabled) {
      if (kDebugMode) { print("SecuritySettingsScreen: Prompting Biometrics for confirmation."); }
      try {
        authenticated = await authService.authenticateWithBiometrics(reason);
        // Tekrar mounted kontrolü (çok nadir ama teorik olarak mümkün)
        if (!mounted) return false;
        if (authenticated) return true; // Biyometrik başarılıysa hemen çık
      } catch (e) {
        if (kDebugMode) { print("SecuritySettingsScreen: Biometric auth error: $e"); }
        // Biyometrik hata verirse PIN'e geçebiliriz
      }
    }

    // Biyometrik başarısız/kullanılamaz/kapalı ise PIN sor
    if (kDebugMode) { print("SecuritySettingsScreen: Prompting PIN for confirmation."); }

    // Dialog'u göstermeden önce context'in hala geçerli olduğunu varsayıyoruz
    // Ancak dialog'un kendisi bir async beklemeye neden olur.
    final String? pin = await _showPinEntryDialog(context);

    // Dialog kapandıktan sonra mounted kontrolü KESİNLİKLE GEREKLİ!
    if (!mounted) return false;

    if (pin != null && pin.isNotEmpty) {
      final bool isValid = await authService.verifyPin(pin);

      // PIN kontrolü sonrası son mounted kontrolü
      if (!mounted) return false;

      if (!isValid) {
        // ScaffoldMessenger'ı tekrar güvenli almayı dene
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(
              content: const Text('Girilen PIN hatalı!'),
              backgroundColor: Theme.of(context).colorScheme.error,
            )
        );
        HapticFeedback.heavyImpact();
      }
      return isValid;
    }

    // Kullanıcı iptal etti veya boş PIN girdi
    return false;
  }


  // PIN kaldırma onayı dialogu
  Future<bool> _showRemovePinConfirmationDialog(BuildContext context) async {
    // Bu dialog daha basit, async gap öncesi sadece theme alalım
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // Dialog'un kendisi async işlem, sonrası için mounted kontrolü gerekli olacak
    final result = await showDialog<bool>(
      context: context, // Ana context
      builder: (dialogContext) => AlertDialog( // İç context
        title: Text(l10n.removePin),
        content: Text(l10n.removePinConfirmation),
        actions: <Widget>[
          TextButton(
              child: Text(l10n.cancel, style: TextStyle(color: Theme.of(dialogContext).colorScheme.secondary)), // dialogContext kullan
              onPressed: () => Navigator.of(dialogContext).pop(false) // dialogContext kullan
          ),
          TextButton(
              child: Text(l10n.removeLock, style: TextStyle(color: Theme.of(dialogContext).colorScheme.error)), // dialogContext kullan
              onPressed: () => Navigator.of(dialogContext).pop(true) // dialogContext kullan
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        backgroundColor: Theme.of(dialogContext).colorScheme.surfaceContainerHigh, // dialogContext kullan
      ),
    );
    // Dialog sonrası kullanıcı true/false/null dönebilir, null ise false kabul et
    return result ?? false;
  }

  // --- Async Yardımcı Metotlar (use_build_context_synchronously önlemleriyle) ---

  // Kilit Açma/Kapama Toggle
  Future<void> _handleToggleLock(BuildContext context, bool enable) async {
    // Async gap öncesi Bloc'u al
    final authBloc = context.read<AuthBloc>();
    // Navigator push için context o an geçerli olmalı
    final navigator = Navigator.of(context); // KULLANILMAYACAK - push içinde context kullanılacak

    if (enable) { // Etkinleştirme (Doğrudan PIN setup ekranına git)
      // Push işlemi sync, context o an geçerli
      if(mounted){ // Yine de kontrol edelim
        Navigator.push( context, // Güncel context'i kullan
          MaterialPageRoute( builder: (_) => const PinSetupScreen(isChangePin: false)),
        );
      }
    } else { // Devre Dışı Bırakma (Önce kimlik doğrula, sonra onayla)
      bool userAuthenticated = await _promptForAuthentication(context, reason: "Uygulama kilidini kaldırmak için kimliğinizi doğrulayın");

      // await sonrası mounted ŞART!
      if (!mounted) return;

      if (userAuthenticated) {
        bool confirmRemove = await _showRemovePinConfirmationDialog(context); // Context hala geçerli varsayılıyor

        // İkinci await sonrası tekrar mounted ŞART!
        if (!mounted) return;

        if (confirmRemove) {
          // Bloc event'ini gönder (context.read güvenli)
          authBloc.add(RemovePin());
        }
      }
    }
  }

  // PIN Değiştirme
  Future<void> _handleChangePin(BuildContext context) async {
    // Navigator push için context o an geçerli olmalı
    bool userAuthenticated = await _promptForAuthentication(context, reason: "PIN kodunuzu değiştirmek için kimliğinizi doğrulayın");

    // await sonrası mounted ŞART!
    if (!mounted) return;

    if (userAuthenticated) {
      // Push işlemi sync, context o an geçerli
      Navigator.push( context, // Güncel context'i kullan
        MaterialPageRoute(builder: (_) => const PinSetupScreen(isChangePin: true)),
      );
    }
  }

  // Biyometrik Toggle
  Future<void> _handleToggleBiometrics(BuildContext context, bool enable) async {
    // Async gap öncesi Bloc'u al
    final authBloc = context.read<AuthBloc>();

    // Önce kimlik doğrula
    bool userAuthenticated = await _promptForAuthentication(context, reason: "Biyometrik ayarını değiştirmek için kimliğinizi doğrulayın");

    // await sonrası mounted ŞART!
    if (!mounted) return;

    if (userAuthenticated) {
      // Bloc event'ini gönder (context.read güvenli)
      authBloc.add(ToggleBiometrics(enable));
    } else {
      // Eğer kimlik doğrulama başarısız olursa, Switch'in durumu eski haline dönmeli.
      // Bloc state'ini dinleyerek veya burada setState ile manuel düzeltme yapılabilir.
      // Şimdilik Bloc state'inin güncellemesini bekliyoruz.
      if (kDebugMode) print("SecuritySettingsScreen: Biometric toggle cancelled due to failed authentication.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context)!;

    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
            title: Text(l10n.securitySettings),
            backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
            leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () {
                  if(Navigator.canPop(context)) Navigator.pop(context);
                }
            )
        ),
        // BlocListener yerine BlocConsumer kullanarak hem dinleme hem build yapalım
        body: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            // Hata mesajlarını göster (mounted kontrolüne gerek yok, listener içinde context geçerli)
            if (state is AuthFailure) {
              if (kDebugMode) { print("SecuritySettingsScreen: Received AuthFailure: ${state.message}"); }
              ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                  SnackBar( content: Text(state.message), backgroundColor: colorScheme.error,)
              );
            }
            // PIN kaldırıldıysa ve SetupRequired state'ine geçildiyse bilgi verilebilir
            if (state is AuthSetupRequired){
              // Bu state PIN kaldırıldığında veya ilk kurulumda gelir.
              // Sadece PIN kaldırıldığında mesaj göstermek için önceki state'i bilmek gerekebilir.
              // Şimdilik mesaj göstermeyelim.
            }
          },
          builder: (context, state) {
            // State'e göre UI durumunu belirle
            // PIN ayarlı mı? (Locked veya Unlocked durumları PIN'in varlığını gösterir)
            final bool isPinSet = state is AuthLocked || state is AuthUnlocked;
            // Biyometrik etkin mi? (Sadece Locked state'inde bu bilgi var, ama AuthService'den de alınabilir)
            // Bloc state'inden almak daha tutarlı
            final bool isBiometricsCurrentlyEnabled = (state is AuthLocked && state.biometricsEnabled);


            // Biyometrik yeteneği kontrol ediliyorsa yükleniyor göster
            if (_isCheckingBiometrics) {
              return const Center(child: CircularProgressIndicator());
            }

            // Ana Ayarlar Listesi
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
              children: [
                // --- Uygulama Kilidi (PIN) ---
                ListTile(
                  leading: Icon(
                    isPinSet ? Icons.lock_person_rounded : Icons.lock_open_rounded,
                    color: isPinSet ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  ),
                  title: Text(l10n.appLock, style: textTheme.titleMedium),
                  subtitle: Text(isPinSet ? l10n.enabled : l10n.disabled),
                  trailing: Switch(
                    value: isPinSet,
                    // onChanged içinde async işlem olduğu için yardımcı metot kullan
                    onChanged: (value) => _handleToggleLock(context, value),
                    activeColor: colorScheme.primary,
                  ),
                  contentPadding: const EdgeInsets.only(left: 16, right: 5, top: 4, bottom: 4), // Padding ayarlandı
                  // ListTile'a tıklamak yerine sadece Switch ile etkileşim daha net olabilir
                  // onTap: () => _handleToggleLock(context, !isPinSet),
                ),
                _buildDivider(),

                // --- PIN Değiştir ---
                // Sadece PIN ayarlıysa etkin ve tıklanabilir
                ListTile(
                  leading: Icon(
                    Icons.password_rounded,
                    color: colorScheme.secondary.withOpacity(isPinSet ? 1.0 : 0.5),
                  ),
                  title: Text(
                    l10n.changePin,
                    style: textTheme.titleMedium?.copyWith(
                        color: isPinSet ? null : colorScheme.onSurface.withOpacity(0.5)
                    ),
                  ),
                  trailing: isPinSet
                      ? Icon(Icons.arrow_forward_ios_rounded, size: 16, color: colorScheme.onSurfaceVariant)
                      : null,
                  enabled: isPinSet,
                  onTap: isPinSet ? () => _handleChangePin(context) : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // Dikey padding ayarlandı
                ),
                _buildDivider(),

                // --- Biyometrik Giriş ---
                // Cihaz destekliyorsa ve PIN ayarlıysa SwitchListTile göster
                if (_canCheckBiometrics)
                  SwitchListTile(
                    title: Text(l10n.biometricLogin,
                      style: textTheme.titleMedium?.copyWith(
                          color: isPinSet ? null : colorScheme.onSurface.withOpacity(0.5)
                      ),
                    ),
                    subtitle: Text(isPinSet
                        ? (isBiometricsCurrentlyEnabled ? l10n.enabled : l10n.disabled)
                        : l10n.enablePinFirst
                    ),
                    value: isPinSet && isBiometricsCurrentlyEnabled, // Değer, PIN varsa ve etkinse true
                    // Değiştirme işlemi sadece PIN ayarlıysa mümkün
                    onChanged: isPinSet
                        ? (value) => _handleToggleBiometrics(context, value)
                        : null,
                    secondary: Icon(
                      Icons.fingerprint_rounded,
                      color: isPinSet
                          ? (isBiometricsCurrentlyEnabled ? colorScheme.primary : colorScheme.onSurfaceVariant)
                          : colorScheme.onSurfaceVariant.withOpacity(0.5), // PIN yoksa soluk
                    ),
                    activeColor: colorScheme.primary,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // Padding ayarlandı
                  )
                // Cihaz desteklemiyorsa (ama PIN ayarlı olabilir) bilgi ver
                else
                  ListTile(
                    leading: Icon(Icons.fingerprint_rounded, color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
                    title: Text(l10n.biometricLogin, style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant.withOpacity(0.7))),
                    subtitle: Text(l10n.deviceNotSupported, style: textTheme.bodySmall),
                    enabled: false,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // Dikey padding ayarlandı
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Ayırıcı Widget
  Widget _buildDivider() => Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16, color: Theme.of(context).dividerColor.withOpacity(0.3));
}
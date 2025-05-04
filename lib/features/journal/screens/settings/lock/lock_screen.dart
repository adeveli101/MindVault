// lib/features/journal/screens/settings/lock/lock_screen.dart

import 'package:flutter/foundation.dart'; // kDebugMode için
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindvault/features/journal/bloc_auth/auth_bloc.dart';
import 'package:mindvault/features/journal/screens/themes/themed_background.dart';
import 'package:pinput/pinput.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _pinController = TextEditingController();
  final _pinFocusNode = FocusNode();

  PinTheme? defaultPinTheme;
  PinTheme? focusedPinTheme;
  PinTheme? submittedPinTheme;
  PinTheme? errorPinTheme;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // PIN alanına odaklan
      if (mounted) _pinFocusNode.requestFocus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Temaları context'e bağlı olarak ayarla
    _setupPinThemes(context);
  }

  void _setupPinThemes(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Temalar zaten ayarlandıysa tekrar ayarlama
    if (defaultPinTheme != null) return;

    defaultPinTheme = PinTheme(
      width: 48, // Yatay alanı azaltmak için küçültüldü
      height: 53, // Yatay alanı azaltmak için küçültüldü
      textStyle: TextStyle(fontSize: 20, color: colorScheme.onSurface), // Font boyutu küçültüldü
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10), // Köşe yuvarlaklığı azaltıldı
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.7)),
      ),
    );
    focusedPinTheme = defaultPinTheme!.copyWith(
      decoration: defaultPinTheme!.decoration!.copyWith(
        border: Border.all(color: colorScheme.primary, width: 2),
      ),
    );
    submittedPinTheme = defaultPinTheme;
    errorPinTheme = defaultPinTheme!.copyWith(
      decoration: defaultPinTheme!.decoration!.copyWith(
        border: Border.all(color: colorScheme.error, width: 2),
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  void _submitPin(String pin) {
    if (kDebugMode) { print("LockScreen: Submitting PIN via pinput: $pin"); }
    _pinFocusNode.unfocus();
    // Bloc event'i gönderirken context.read kullanmak genellikle güvenlidir.
    context.read<AuthBloc>().add(UnlockWithPin(pin));
  }

  void _tryBiometrics() {
    if (kDebugMode) { print("LockScreen: Biometric unlock button pressed."); }
    context.read<AuthBloc>().add(UnlockWithBiometrics());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // onPopInvoked yerine PopScope kullanımı
    return PopScope(
      canPop: false, // Geri tuşuyla çıkışı engelle
      onPopInvokedWithResult: (didPop, result) {
        if (kDebugMode) { print("LockScreen: Pop attempted (didPop: $didPop). Blocked."); }
        // Geri tuşuna basıldığında bir şey yapmaya gerek yok (canPop: false yeterli)
      },
      child: ThemedBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthFailure) {
                if (kDebugMode) { print("LockScreen: Received AuthFailure: ${state.message}"); }
                // Güvenli context kullanımı
                final messenger = ScaffoldMessenger.maybeOf(context);
                if(mounted){ // setState olmasa da kontrol etmek iyi olabilir
                  _pinController.clear();
                  _pinFocusNode.requestFocus();
                  HapticFeedback.heavyImpact();
                  messenger?.showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: colorScheme.error,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
              // AuthUnlocked -> main.dart/HomeGate ele alacak
            },
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                // Biyometrik bilgilerini state'ten alalım (AuthLocked veya AuthFailure olabilir)
                final bool canCheckBiometrics = state is AuthLocked ? state.canCheckBiometrics : (state is AuthFailure ? false : false); // Fallback
                final bool isBiometricsEnabled = state is AuthLocked ? state.biometricsEnabled : false; // Fallback

                // Temaların oluşturulduğundan emin ol (nadiren null olabilir)
                if (defaultPinTheme == null) _setupPinThemes(context);

                return SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 28.0), // Yatay padding azaltıldı
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon( Icons.lock_person_rounded, size: 55, color: colorScheme.primary), // Boyut ayarlandı
                          const SizedBox(height: 18),
                          Text( 'Güvenlik Kilidi', style: textTheme.headlineSmall?.copyWith(color: colorScheme.primary)),
                          const SizedBox(height: 8),
                          Text(
                            'Devam etmek için ${canCheckBiometrics && isBiometricsEnabled ? "PIN girin veya biyometriği kullanın" : "PIN kodunuzu girin"}.',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 35),

                          // PIN Girişi (pinput)
                          Padding(
                            // Pinput zaten kendi içinde boşluk bırakabilir, gerekirse bu padding azaltılabilir
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Pinput(
                              controller: _pinController,
                              focusNode: _pinFocusNode,
                              length: 6,
                              obscureText: true,
                              obscuringCharacter: '●',
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              defaultPinTheme: defaultPinTheme ?? const PinTheme(), // Null check
                              focusedPinTheme: focusedPinTheme,
                              submittedPinTheme: submittedPinTheme,
                              errorPinTheme: errorPinTheme,
                              pinAnimationType: PinAnimationType.scale,
                              onCompleted: _submitPin,
                              errorTextStyle: const TextStyle(fontSize: 0, height: 0), // Hata state'ini BlocListener yönetecek
                            ),
                          ),
                          const SizedBox(height: 25),

                          // Biyometrik Butonu
                          if (canCheckBiometrics)
                            AnimatedOpacity(
                              opacity: isBiometricsEnabled ? 1.0 : 0.4,
                              duration: const Duration(milliseconds: 300),
                              child: IconButton(
                                iconSize: 50, // Boyut ayarlandı
                                tooltip: isBiometricsEnabled ? 'Biyometrik ile Aç' : 'Biyometrik Etkin Değil',
                                onPressed: isBiometricsEnabled ? _tryBiometrics : null,
                                icon: Icon(
                                  Icons.fingerprint_rounded,
                                  color: isBiometricsEnabled ? colorScheme.secondary : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          else // Desteklemiyorsa boşluk
                            const SizedBox(height: 60), // IconButton yüksekliği kadar yaklaşık boşluk

                          const SizedBox(height: 30),
                          // TODO: PIN Unuttum?
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
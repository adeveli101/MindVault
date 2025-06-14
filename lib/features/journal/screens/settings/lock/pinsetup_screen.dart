// lib/features/journal/screens/settings/lock/pinsetup_screen.dart

import 'package:flutter/foundation.dart'; // kDebugMode için
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindvault/features/journal/bloc_auth/auth_bloc.dart';
import 'package:mindvault/features/journal/screens/themes/themed_background.dart';
import 'package:pinput/pinput.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PinSetupScreen extends StatefulWidget {
  final bool isChangePin;

  const PinSetupScreen({super.key, required this.isChangePin});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _pinFocusNode = FocusNode();
  final _confirmPinFocusNode = FocusNode();
  bool _isLoading = false;
  String? _confirmPinErrorText; // Hata mesajını state'te tutalım

  PinTheme? defaultPinTheme;
  PinTheme? focusedPinTheme;
  PinTheme? submittedPinTheme;
  PinTheme? errorPinTheme;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _pinFocusNode.requestFocus();
    });
    // Controller'ları dinleyerek hata durumunu yönetelim
    _confirmPinController.addListener(_validateConfirmPin);
    _pinController.addListener(_validateConfirmPin); // İlk pin değişince de kontrol et
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setupPinThemes(context);
  }

  void _setupPinThemes(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    if (defaultPinTheme != null) return;

    defaultPinTheme = PinTheme(
      width: 50, // Yatay alanı azaltmak için küçültüldü
      height: 55, // Yatay alanı azaltmak için küçültüldü
      textStyle: TextStyle(fontSize: 20, color: colorScheme.onSurface), // Font küçültüldü
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
    );
    focusedPinTheme = defaultPinTheme!.copyWith(
      decoration: defaultPinTheme!.decoration!.copyWith(
        border: Border.all(color: colorScheme.primary, width: 2),
      ),
    );
    // Submitted theme, focus kaybedince normal gibi görünsün
    submittedPinTheme = defaultPinTheme;
    errorPinTheme = defaultPinTheme!.copyWith(
      decoration: defaultPinTheme!.decoration!.copyWith(
        border: Border.all(color: colorScheme.error, width: 2),
      ),
    );
  }

  @override
  void dispose() {
    _pinController.removeListener(_validateConfirmPin);
    _confirmPinController.removeListener(_validateConfirmPin);
    _pinController.dispose();
    _confirmPinController.dispose();
    _pinFocusNode.dispose();
    _confirmPinFocusNode.dispose();
    super.dispose();
  }

  // PIN onaylama alanını dinamik olarak validate et
  void _validateConfirmPin() {
    final pin = _pinController.text;
    final confirmPin = _confirmPinController.text;
    setState(() {
      if (confirmPin.isNotEmpty && pin.length == 6 && confirmPin != pin) {
        _confirmPinErrorText = 'PIN\'ler eşleşmiyor.';
      } else {
        _confirmPinErrorText = null; // Hata yok veya henüz kontrol edilmedi
      }
    });
  }


  void _submitPin() {
    _pinFocusNode.unfocus();
    _confirmPinFocusNode.unfocus();

    if (_isLoading) return;

    // Manuel validate et
    bool isPinValid = _pinController.text.length == 6;
    bool isConfirmPinValid = _confirmPinController.text.length == 6;
    bool doPinsMatch = _pinController.text == _confirmPinController.text;

    // Hata durumlarını state'e yansıt (validator yerine)
    setState(() {
      // _validateConfirmPin zaten eşleşme hatasını ayarlar
      if (!isPinValid || !isConfirmPinValid || !doPinsMatch) {
        // Form key validate() çağırmaya gerek yok, Pinput kendi hata temasını gösterebilir (errorPinTheme)
        // ama biz özel hata mesajı için _confirmPinErrorText kullanıyoruz.
        HapticFeedback.heavyImpact();
        if (kDebugMode) { print("PinSetupScreen: Form invalid on submit."); }
      }
    });


    if (isPinValid && isConfirmPinValid && doPinsMatch) {
      if (kDebugMode) { print("PinSetupScreen: Form valid, dispatching SetupPin event."); }
      setState(() { _isLoading = true; });
      context.read<AuthBloc>().add(SetupPin(_pinController.text));
    }
  }

  // İlk PIN alanı tamamlandığında ikinciye odaklan
  void _onPinChanged(String pin) {
    if (pin.length == 6) {
      _confirmPinFocusNode.requestFocus();
    }
    // İkinci alanın validasyonunu tetikle (listener zaten yapıyor)
  }

  // İkinci PIN alanı tamamlandığında submit etmeyi dene
  void _onConfirmPinCompleted(String pin) {
    _submitPin();
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context)!;
    final String title = widget.isChangePin ? l10n.changePinTitle : l10n.createPin;
    final String buttonText = widget.isChangePin ? l10n.changePin : l10n.createPin;

    if (defaultPinTheme == null) _setupPinThemes(context);

    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(title),
          backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
          leading: IconButton( icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => Navigator.maybePop(context)),
        ),
        body: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (mounted) {
              setState(() { _isLoading = state is AuthInProgress; });

              if (state is AuthLocked) {
                if (kDebugMode) { print("PinSetupScreen: Received AuthLocked state (PIN set/changed successfully). Popping screen."); }
                if (Navigator.canPop(context)) Navigator.pop(context);
                ScaffoldMessenger.maybeOf(context)?.showSnackBar( 
                  SnackBar( 
                    content: Text(widget.isChangePin ? l10n.pinSuccessfullyChanged : l10n.pinSuccessfullySet),
                    backgroundColor: Colors.green[700]
                  )
                );
              } else if (state is AuthFailure) {
                if (kDebugMode) { print("PinSetupScreen: Received AuthFailure state: ${state.message}"); }
                ScaffoldMessenger.maybeOf(context)?.showSnackBar( 
                  SnackBar( 
                    content: Text(l10n.pinCouldNotBeSet(state.message)),
                    backgroundColor: colorScheme.error
                  )
                );
                _pinController.clear();
                _confirmPinController.clear();
                _pinFocusNode.requestFocus();
              }
            }
          },
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon( Icons.pin_rounded, size: 45, color: colorScheme.primary),
                    const SizedBox(height: 14),
                    Text( 
                      widget.isChangePin ? l10n.changePinDescription : l10n.createPinDescription,
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium
                    ),
                    const SizedBox(height: 28),

                    Pinput(
                      controller: _pinController,
                      focusNode: _pinFocusNode,
                      length: 6,
                      obscureText: true, obscuringCharacter: '●',
                      keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      defaultPinTheme: defaultPinTheme ?? const PinTheme(),
                      focusedPinTheme: focusedPinTheme,
                      submittedPinTheme: submittedPinTheme,
                      errorPinTheme: errorPinTheme,
                      pinAnimationType: PinAnimationType.fade,
                      onChanged: _onPinChanged,
                      errorTextStyle: const TextStyle(fontSize: 0, height: 0),
                      forceErrorState: _pinController.text.isNotEmpty && _pinController.text.length != 6,
                    ),
                    const SizedBox(height: 20),

                    Pinput(
                      controller: _confirmPinController,
                      focusNode: _confirmPinFocusNode,
                      length: 6,
                      obscureText: true, obscuringCharacter: '●',
                      keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      defaultPinTheme: defaultPinTheme ?? const PinTheme(),
                      focusedPinTheme: focusedPinTheme,
                      submittedPinTheme: submittedPinTheme,
                      errorPinTheme: errorPinTheme,
                      pinAnimationType: PinAnimationType.fade,
                      onCompleted: _onConfirmPinCompleted,
                      errorTextStyle: const TextStyle(fontSize: 0, height: 0),
                      forceErrorState: _confirmPinErrorText != null || (_confirmPinController.text.isNotEmpty && _confirmPinController.text.length != 6),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: _confirmPinErrorText != null ? 20 : 18,
                      alignment: Alignment.center,
                      child: _confirmPinErrorText != null
                          ? Text( l10n.pinsDoNotMatch, style: textTheme.bodySmall?.copyWith(color: colorScheme.error),)
                          : null,
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitPin,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(10)),
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                      child: _isLoading
                          ? SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: colorScheme.onPrimary))
                          : Text(buttonText, style: textTheme.titleMedium?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
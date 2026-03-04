import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/auth_provider.dart';
import '../../config/app_theme.dart';
import '../home/home_screen.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  final _otpFocusNode = FocusNode();
  
  bool _isOtpSent = false;
  bool _isLoading = false;
  int _resendCooldown = 0;
  int _otpAttempts = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _phoneFocusNode.dispose();
    _otpFocusNode.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  /// Démarre le timer de cooldown pour le renvoi d'OTP
  void _startResendTimer() {
    setState(() => _resendCooldown = 60);
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        timer.cancel();
      }
    });
  }

  /// Garde uniquement les chiffres (max 9) et formate en XX XXX XX XX
  static const _senegalPrefixes = ['70', '71', '76', '77', '78'];

  String _formatPhoneNumber(String value) {
    final digits = value.replaceAll(RegExp(r'[^\d]'), '').substring(0, 9);
    if (digits.isEmpty) return '';
    if (digits.length <= 2) return digits;
    if (digits.length <= 5) return '${digits.substring(0, 2)} ${digits.substring(2)}';
    if (digits.length <= 7) return '${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5)}';
    return '${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5, 7)} ${digits.substring(7)}';
  }

  /// Retourne les 9 chiffres bruts pour envoi API (sans espaces)
  String _phoneDigits(String value) => value.replaceAll(RegExp(r'[^\d]'), '').substring(0, 9);

  /// Retourne un message d'erreur user-friendly
  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('network') || errorStr.contains('connection')) {
      return 'Problème de connexion internet. Vérifiez votre réseau.';
    } else if (errorStr.contains('invalid-phone') || errorStr.contains('invalid')) {
      return 'Numéro de téléphone invalide.';
    } else if (errorStr.contains('too-many-requests')) {
      return 'Trop de tentatives. Réessayez dans quelques minutes.';
    } else if (errorStr.contains('code-expired')) {
      return 'Le code a expiré. Demandez un nouveau code.';
    }
    
    return 'Une erreur est survenue. Veuillez réessayer.';
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final phoneNumber = _phoneDigits(_phoneController.text);
      await context.read<AuthProvider>().signInWithPhone(phoneNumber);

      if (!mounted) return;

      setState(() {
        _isOtpSent = true;
        _isLoading = false;
        _otpAttempts = 0;
      });

      _startResendTimer();

      // Auto-focus sur le champ OTP
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _otpFocusNode.requestFocus();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code OTP envoyé ! Vérifiez votre téléphone.'),
          backgroundColor: AppTheme.primaryGreen,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getErrorMessage(e)),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _verifyOTP() async {
    if (!_formKey.currentState!.validate()) return;

    // Limiter les tentatives
    if (_otpAttempts >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trop de tentatives. Demandez un nouveau code.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      _reset();
      return;
    }

    setState(() {
      _isLoading = true;
      _otpAttempts++;
    });

    try {
      final phone = _phoneDigits(_phoneController.text);
      final token = _otpController.text.trim();

      await context.read<AuthProvider>().verifyOTP(phone: phone, token: token);

      if (!mounted) return;

      // Haptic feedback de succès
      HapticFeedback.mediumImpact();

      // Navigation vers l'écran d'accueil
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      // Haptic feedback d'erreur
      HapticFeedback.vibrate();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Code incorrect (${_otpAttempts}/5). ${_getErrorMessage(e)}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

 // Remplacer la méthode _reset par :
void _reset() {
  Navigator.pushReplacementNamed(context, '/auth-method');
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo/Illustration
                Hero(
                  tag: 'phone_icon',
                  child: Container(
                    width: 120,
                    height: 120,
                    margin: const EdgeInsets.only(bottom: 32),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.phone_android,
                      size: 60,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),

                // Titre
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _isOtpSent ? 'Entrez le code OTP' : 'Connectez-vous',
                    key: ValueKey(_isOtpSent),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _isOtpSent
                        ? 'Nous avons envoyé un code à\n${_formatPhoneNumber(_phoneController.text)}'
                        : 'Entrez votre numéro de téléphone pour continuer',
                    key: ValueKey(_isOtpSent ? 'otp' : 'phone'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 32),

                // Champ téléphone (9 chiffres, préfixes 70, 71, 76, 77, 78)
                if (!_isOtpSent)
                  TextFormField(
                    controller: _phoneController,
                    focusNode: _phoneFocusNode,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Numéro de téléphone',
                      hintText: '77 123 45 67',
                      prefixIcon: Icon(Icons.phone),
                      helperText: '9 chiffres (70, 71, 76, 77, 78)',
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11), // 9 chiffres affichés en XX XXX XX XX
                      TextInputFormatter.withFunction((old, new_) {
                        final digits = new_.text.replaceAll(RegExp(r'[^\d]'), '').substring(0, 9);
                        final formatted = digits.isEmpty ? '' : _formatPhoneNumber(digits);
                        return TextEditingValue(
                          text: formatted,
                          selection: TextSelection.collapsed(offset: formatted.length),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      final digits = value.replaceAll(RegExp(r'[^\d]'), '').substring(0, 9);
                      final formatted = _formatPhoneNumber(digits);
                      if (formatted != value) {
                        _phoneController.value = TextEditingValue(
                          text: formatted,
                          selection: TextSelection.collapsed(offset: formatted.length),
                        );
                      }
                    },
                    validator: (value) {
                      final digits = value == null ? '' : value.replaceAll(RegExp(r'[^\d]'), '');
                      if (digits.isEmpty) return 'Veuillez entrer un numéro';
                      if (digits.length != 9) return '9 chiffres requis (ex: 77 123 45 67)';
                      final prefix = digits.substring(0, 2);
                      if (!_senegalPrefixes.contains(prefix)) {
                        return 'Préfixe invalide. Utilisez 70, 71, 76, 77 ou 78.';
                      }
                      return null;
                    },
                  ),

                // Champ OTP
                if (_isOtpSent) ...[
                  TextFormField(
                    controller: _otpController,
                    focusNode: _otpFocusNode,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    decoration: InputDecoration(
                      labelText: 'Code OTP',
                      hintText: '123456',
                      prefixIcon: const Icon(Icons.lock),
                      helperText: _otpAttempts > 0 
                          ? 'Tentative ${_otpAttempts}/5' 
                          : 'Code à 6 chiffres',
                      helperStyle: TextStyle(
                        color: _otpAttempts >= 3 ? Colors.orange : null,
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    onFieldSubmitted: (_) => _verifyOTP(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer le code OTP';
                      }
                      if (value.length != 6) {
                        return 'Le code OTP doit contenir 6 chiffres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Boutons de gestion OTP
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: _reset,
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: const Text('Changer de numéro'),
                      ),
                      TextButton.icon(
                        onPressed: _resendCooldown > 0 ? null : _sendOTP,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: Text(
                          _resendCooldown > 0 
                              ? 'Renvoyer (${_resendCooldown}s)'
                              : 'Renvoyer le code',
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 32),

                // Bouton principal
                ElevatedButton(
                  onPressed: _isLoading ? null : (_isOtpSent ? _verifyOTP : _sendOTP),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _isOtpSent ? 'Vérifier le code' : 'Envoyer le code',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),

                const SizedBox(height: 24),

                // Info box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isOtpSent
                              ? 'Le code expire dans 5 minutes. N\'avez-vous rien reçu ?'
                              : 'Vous recevrez un code de vérification par SMS',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
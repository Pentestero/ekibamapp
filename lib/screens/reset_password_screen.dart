import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provisions/services/auth_service.dart';
import 'package:provisions/screens/home_page.dart'; // Assuming HomePage is the main logged-in screen
import 'package:provisions/screens/auth_screen.dart'; // Import the AuthScreen

class ResetPasswordScreen extends StatefulWidget {
  final String? accessToken;
  const ResetPasswordScreen({super.key, this.accessToken});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String? _errorMessage;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _newPasswordController.text) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

  Future<void> _resetPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Supabase's updateUser automatically uses the session from the access_token
      // if it's set in the URL (which main.dart will handle before navigating here).
      // So we don't need to pass the accessToken directly to updateUser.
      await AuthService.instance.updateUserPassword(
        _newPasswordController.text,
      );

      if (mounted) {
        // After successful password reset, redirect to home or login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Votre mot de passe a été réinitialisé avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        // After password reset, user is automatically logged in with the new password
        // The StreamBuilder in main.dart should catch this and redirect to HomePage.
        // For safety, we can navigate to AuthScreen and let StreamBuilder handle it.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => AuthScreen()), // Navigate to AuthScreen
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Une erreur inattendue est survenue.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Réinitialiser le mot de passe'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: !_isNewPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Nouveau mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_isNewPasswordVisible ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _isNewPasswordVisible = !_isNewPasswordVisible),
                    ),
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Confirmer le nouveau mot de passe',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                    ),
                  ),
                  validator: _validateConfirmPassword,
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Réinitialiser'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

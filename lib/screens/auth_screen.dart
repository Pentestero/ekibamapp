import 'package:flutter/material.dart';
import 'package:provisions/screens/signin_screen.dart';
import 'package:provisions/screens/signup_screen.dart';
import 'package:provisions/widgets/app_brand.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface, // Use theme background color
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 600) {
            // Desktop/Wide screen layout
            return Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      image: const DecorationImage(
                        image: AssetImage('assets/images/EKIBAM.jpg'), // Use your app's background image
                        fit: BoxFit.cover,
                        opacity: 0.3,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppBrand(
                            height: 80, // Larger logo for desktop
                            showText: true,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Gérez vos approvisionnements\nsimplement et efficacement',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400), // Max width for form on desktop
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: _buildAuthButtons(context),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            // Mobile/Narrow screen layout
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: _buildAuthButtons(context),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildAuthButtons(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (MediaQuery.of(context).size.width < 600) ...[ // Only show AppBrand on mobile layout
          const AppBrand(),
          const SizedBox(height: 16),
          Text(
            'Gérez vos approvisionnements simplement',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 48),
        ],
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignUpScreen()));
          },
          child: const Text('S\'inscrire'),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignInScreen()));
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
            side: BorderSide(color: Theme.of(context).colorScheme.primary),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: const Text('Se connecter'),
        ),
      ],
    );
  }
}

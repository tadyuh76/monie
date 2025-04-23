import 'package:flutter/material.dart';
import 'package:monie/core/widgets/app_logo.dart';
import 'package:monie/core/widgets/theme_toggle.dart';

class AuthPageScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final bool showLogo;
  final bool showBackButton;

  const AuthPageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.showLogo = true,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        automaticallyImplyLeading: showBackButton,
        actions: const [ThemeToggle()],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                if (showLogo) ...[
                  const SizedBox(height: 24),
                  const AppLogo(),
                  const SizedBox(height: 32),
                ],
                child,
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/session_controller.dart';
import '../widgets/reset_password_sheet.dart';
import '../widgets/server_config_bottom_sheet.dart';

/// Full-screen authentication view allowing users to sign in, register,
/// or configure their self-hosted LoreKeeper server URL.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegistering = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final controller = ref.read(sessionControllerProvider.notifier);

    bool success;
    if (_isRegistering) {
      success = await controller.register(email: email, password: password);
    } else {
      success = await controller.login(email: email, password: password);
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isRegistering ? 'Account created successfully!' : 'Signed in successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    }
  }

  void _showServerConfigSheet(BuildContext context) {
    final controller = ref.read(sessionControllerProvider.notifier);
    ServerConfigBottomSheet.show(context, controller);
  }

  void _showForgotPasswordSheet(BuildContext context) {
    final controller = ref.read(sessionControllerProvider.notifier);
    ResetPasswordSheet.show(
      context,
      controller,
      initialEmail: _emailController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sessionAsync = ref.watch(sessionControllerProvider);
    final isLoading = sessionAsync.isLoading;
    final errorMessage = sessionAsync.value?.errorMessage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LoreKeeper Cloud'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Server Connection Settings',
            icon: const Icon(Icons.dns_outlined),
            onPressed: () => _showServerConfigSheet(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.md),
                // Hero Branding Badge
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    ),
                    child: Icon(
                      Icons.cloud_sync_rounded,
                      size: 38,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  _isRegistering ? 'Create your Account' : 'Welcome to LoreKeeper',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _isRegistering
                      ? 'Back up your books, notes, and reading stats to your private cloud'
                      : 'Sign in to access your cloud library and sync reading progress',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppTypography.sm,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Tab Switcher Pill
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isRegistering = false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: !_isRegistering ? colorScheme.surface : Colors.transparent,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                              boxShadow: !_isRegistering
                                  ? [
                                      BoxShadow(
                                        color: colorScheme.shadow.withValues(alpha: 0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              'Sign In',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: !_isRegistering
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isRegistering = true),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: _isRegistering ? colorScheme.surface : Colors.transparent,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                              boxShadow: _isRegistering
                                  ? [
                                      BoxShadow(
                                        color: colorScheme.shadow.withValues(alpha: 0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              'Register',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _isRegistering
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Error message banner
                if (errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded, color: colorScheme.onErrorContainer),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            errorMessage,
                            style: TextStyle(
                              color: colorScheme.onErrorContainer,
                              fontSize: AppTypography.sm,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (_isRegistering && value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                if (!_isRegistering) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _showForgotPasswordSheet(context),
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          fontSize: AppTypography.sm,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Submit Button
                ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Text(
                          _isRegistering ? 'Create Account' : 'Sign In',
                          style: const TextStyle(fontSize: AppTypography.md, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Active server indicator
                FutureBuilder<String>(
                  future: ref.read(sessionControllerProvider.notifier).getServerUrl(),
                  builder: (context, snapshot) {
                    final serverUrl = snapshot.data ?? 'http://localhost:8080';
                    return Center(
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.onSurfaceVariant,
                        ),
                        icon: const Icon(Icons.link_rounded, size: 16),
                        label: Text(
                          'Server: $serverUrl',
                          style: const TextStyle(fontSize: AppTypography.xs),
                        ),
                        onPressed: () => _showServerConfigSheet(context),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // Guest escape button
                Center(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: Text(
                      'Continue as Guest (Offline)',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

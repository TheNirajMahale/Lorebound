import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/session_controller.dart';

/// Modal sheet facilitating forgot password and reset password workflows.
class ResetPasswordSheet extends StatefulWidget {
  final SessionController controller;
  final String? initialEmail;

  const ResetPasswordSheet({
    super.key,
    required this.controller,
    this.initialEmail,
  });

  static Future<void> show(
    BuildContext context,
    SessionController controller, {
    String? initialEmail,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (sheetContext) {
        return ResetPasswordSheet(
          controller: controller,
          initialEmail: initialEmail,
        );
      },
    );
  }

  @override
  State<ResetPasswordSheet> createState() => _ResetPasswordSheetState();
}

class _ResetPasswordSheetState extends State<ResetPasswordSheet> {
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _codeRequested = false;
  bool _isLoading = false;
  String? _statusInfo;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null) {
      _emailController.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _statusInfo = 'Please enter a valid email address.');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusInfo = null;
    });

    final token = await widget.controller.forgotPassword(email);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _codeRequested = true;
        if (token != null && token.isNotEmpty) {
          _tokenController.text = token;
          _statusInfo = 'Reset token received: $token';
        } else {
          _statusInfo = 'If registered, a reset code was generated on the server.';
        }
      });
    }
  }

  Future<void> _submitReset() async {
    final token = _tokenController.text.trim();
    final newPassword = _newPasswordController.text;

    if (token.isEmpty) {
      setState(() => _statusInfo = 'Please enter the reset code/token.');
      return;
    }

    if (newPassword.length < 6) {
      setState(() => _statusInfo = 'New password must be at least 6 characters.');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusInfo = null;
    });

    final success = await widget.controller.resetPassword(
      token: token,
      newPassword: newPassword,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successfully! You can now sign in.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() => _statusInfo = 'Failed to reset password. Check code or expiry.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.lock_reset_rounded, color: colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Reset Password',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _codeRequested
                ? 'Enter the reset code and your new password below.'
                : 'Enter your email to receive a password reset code.',
            style: TextStyle(
              fontSize: AppTypography.sm,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          if (_statusInfo != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Text(
                _statusInfo!,
                style: TextStyle(
                  fontSize: AppTypography.xs,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Step 1: Email
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            enabled: !_codeRequested,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          if (!_codeRequested) ...[
            ElevatedButton(
              onPressed: _isLoading ? null : _requestCode,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send Reset Code'),
            ),
          ] else ...[
            // Step 2: Token and New Password
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: 'Reset Code / Token',
                prefixIcon: Icon(Icons.pin_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _newPasswordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitReset,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Update Password'),
            ),
          ],
        ],
      ),
    );
  }
}

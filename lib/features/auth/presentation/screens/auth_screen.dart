import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true; // ← password visibility toggle

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email cannot be empty';
    final email = value.trim();
    final emailRegex = RegExp(
        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]{2,}");
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address (e.g. name@domain.com)';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password cannot be empty';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final authController = ref.read(authControllerProvider.notifier);

      bool success = false;
      if (_isLogin) {
        success = await authController.signInWithEmailAndPassword(
            _emailController.text.trim(), _passwordController.text.trim());
      } else {
        success = await authController.signUpWithEmailAndPassword(
            _emailController.text.trim(), _passwordController.text.trim());
      }

      if (!context.mounted) return;
      if (success) {
        navigator.pushReplacementNamed('/splash',
            arguments: {'isPostAuth': true});
      }
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (context.mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // LOGO
              ClipOval(
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: Image.asset('assets/images/logo.png',
                      fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'MelodyMind',
                style: theme.textTheme.displayLarge?.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 8),
              Text(
                'Train Your Ear. Master the Music.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 60),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // EMAIL FIELD
                    _buildInputLabel('Email', isDark),
                    const SizedBox(height: 8),
                    _buildCleanTextField(
                      controller: _emailController,
                      placeholder: 'Enter your email address',
                      isDark: isDark,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 24),

                    // PASSWORD FIELD
                    _buildInputLabel('Password', isDark),
                    const SizedBox(height: 8),
                    _buildPasswordTextField(isDark: isDark),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // FORGOT PASSWORD
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    'Forgot Password?',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color:
                          isDark ? const Color(0xFF22D3EE) : theme.primaryColor,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // LOG IN / SIGN UP BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleAuth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 3))
                      : Text(
                          _isLogin ? 'Log In' : 'Sign Up',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                ),
              ),

              const SizedBox(height: 32),

              // OR DIVIDER
              Row(
                children: [
                  Expanded(child: Divider(color: theme.dividerColor)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color:
                            isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: theme.dividerColor)),
                ],
              ),

              const SizedBox(height: 32),

              // GUEST BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () async {
                    setState(() => _isLoading = true);
                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    final success = await ref.read(authControllerProvider.notifier).signInAnonymously();
                    if (!context.mounted) return;
                    setState(() => _isLoading = false);
                    if (success) {
                      navigator.pushReplacementNamed('/splash', arguments: {'isPostAuth': true});
                    } else {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Failed to sign in as guest')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Continue as Guest',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: const Color(0xFF0F172A)),
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // SIGN UP / LOG IN TOGGLE
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: RichText(
                  text: TextSpan(
                    text: _isLogin
                        ? "Don't have an account? "
                        : "Already have an account? ",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                      fontSize: 15,
                    ),
                    children: [
                      TextSpan(
                        text: _isLogin ? 'Sign Up' : 'Log In',
                        style: TextStyle(
                          color: isDark
                              ? theme.colorScheme.secondary
                              : theme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label, bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: isDark ? Colors.white70 : const Color(0xFF0F172A),
            ),
      ),
    );
  }

  /// Password field with eye icon toggle
  Widget _buildPasswordTextField({required bool isDark}) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      validator: _validatePassword,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        hintText: '••••••••',
        hintStyle:
            TextStyle(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
        filled: true,
        fillColor: theme.cardColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: theme.colorScheme.secondary, width: 1.5),
        ),
        // Eye icon suffix
        suffixIcon: GestureDetector(
          onTap: () => setState(() => _obscurePassword = !_obscurePassword),
          child: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildCleanTextField({
    required TextEditingController controller,
    required String placeholder,
    required bool isDark,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle:
            TextStyle(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
        filled: true,
        fillColor: theme.cardColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: theme.colorScheme.secondary, width: 1.5),
        ),
      ),
    );
  }
}

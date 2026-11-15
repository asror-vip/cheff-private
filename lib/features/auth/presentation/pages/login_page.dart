import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../dashboard/presentation/pages/main_layout.dart';
import '../../data/repositories/auth_repository_impl.dart';

enum AuthTab { signIn, signUp, employee }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthRepositoryImpl _authRepository = AuthRepositoryImpl();

  AuthTab _selectedTab = AuthTab.signIn;

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _restaurantNameController = TextEditingController();
  final _employeeIdController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = _authRepository.onAuthStateChange.listen((data) {
      if (!mounted) return;
      final session = data.session;
      if (session != null && (data.event == AuthChangeEvent.signedIn || data.event == AuthChangeEvent.tokenRefreshed)) {
        final user = session.user;
        final fullName = user.userMetadata?['full_name'] as String? ?? 
                         user.userMetadata?['name'] as String? ?? 
                         user.email?.split('@').first;
        final restName = user.userMetadata?['restaurant_name'] as String?;
        SessionManager().updateBossProfile(
          name: fullName,
          restaurantName: restName,
        );
        SessionManager().switchToBoss();
        _goToHome();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _restaurantNameController.dispose();
    _employeeIdController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ToastUtils.showError(context, message);
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ToastUtils.showSuccess(context, message);
  }

  void _goToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainLayout()),
    );
  }

  Future<void> _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.contains('@') && password.isEmpty) {
      _showError('auth.fill_all_fields'.tr());
      return;
    } else if (email.isEmpty || password.isEmpty) {
      _showError('auth.fill_all_fields'.tr());
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await _authRepository.signInWithEmail(
        email: email,
        password: password,
      );

      if (res.user != null) {
        final fullName = res.user?.userMetadata?['full_name'] as String?;
        final restName = res.user?.userMetadata?['restaurant_name'] as String?;
        SessionManager().updateBossProfile(
          name: fullName ?? email.split('@').first,
          restaurantName: restName,
        );
        SessionManager().switchToBoss();
        _goToHome();
      } else {
        _showError('common.error'.tr());
        return;
      }
    } catch (e) {
      _showError('${'common.error'.tr()}: ${e.toString().replaceAll('Exception: ', '')}');
      return;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignUp() async {
    final name = _nameController.text.trim();
    final restName = _restaurantNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showError('auth.fill_all_fields'.tr());
      return;
    }

    if (password.length < 6) {
      _showError('auth.password_too_short'.tr());
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await _authRepository.signUpWithEmail(
        email: email,
        password: password,
        fullName: name,
        restaurantName: restName.isNotEmpty ? restName : null,
      );

      if (res.user != null) {
        SessionManager().updateBossProfile(
          name: name,
          restaurantName: restName.isNotEmpty ? restName : null,
        );
        SessionManager().switchToBoss();
        _showSuccess('auth.registration_success'.tr());
        _goToHome();
      } else {
        _showSuccess('auth.registration_success'.tr());
        setState(() => _selectedTab = AuthTab.signIn);
      }
    } catch (e) {
      _showError('${'common.error'.tr()}: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await _authRepository.signInWithGoogle();
      // Browser launched; user logs in and redirects back via deep link
    } catch (e) {
      _showError('${'common.error'.tr()}: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final success = await _authRepository.signInWithApple();
      if (success) {
        final user = _authRepository.currentUser;
        if (user != null) {
          final fullName = user.userMetadata?['full_name'] as String? ?? user.email?.split('@').first;
          SessionManager().updateBossProfile(name: fullName);
        }
        SessionManager().switchToBoss();
        _goToHome();
      }
    } catch (e) {
      _showError('${'common.error'.tr()}: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleEmployeeLogin() {
    final code = _employeeIdController.text.trim();
    if (code.isEmpty) {
      _showError('auth.employee_id_hint'.tr());
      return;
    }

    SessionManager().switchToEmployee(code);
    _goToHome();
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(text: _emailController.text);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'auth.reset_password_title'.tr(),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'auth.reset_password_desc'.tr(),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'admin@restaurant.uz',
                filled: true,
                fillColor: AppColors.background,
                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr(), style: const TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isNotEmpty) {
                Navigator.pop(ctx);
                try {
                  await _authRepository.sendPasswordReset(email);
                  _showSuccess('auth.reset_link_sent'.tr());
                } catch (e) {
                  _showError('${'common.error'.tr()}: $e');
                }
              }
            },
            child: Text('auth.send_link'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo & Header
                _buildHeader(),
                const SizedBox(height: 28),

                // Tab Selector (Kirish / Ro'yxatdan o'tish / Xodim)
                _buildTabSelector(),
                const SizedBox(height: 24),

                // Form Content based on selected tab
                if (_selectedTab == AuthTab.signIn)
                  _buildSignInForm()
                else if (_selectedTab == AuthTab.signUp)
                  _buildSignUpForm()
                else
                  _buildEmployeeForm(),

                const SizedBox(height: 24),

                // Social Logins (for Sign In and Sign Up tabs)
                if (_selectedTab != AuthTab.employee) ...[
                  _buildOrDivider(),
                  const SizedBox(height: 20),
                  _buildSocialButtons(),
                ],
                
                const SizedBox(height: 24),
                _buildTermsAndPrivacy(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTermsAndPrivacy() {
    return Column(
      children: [
        Text(
          'auth.cloud_terms_notice'.tr(),
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.4),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            GestureDetector(
              onTap: () {},
              child: Text(
                'auth.terms_of_use'.tr(),
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            Text(
              'common.and'.tr(),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            GestureDetector(
              onTap: () {},
              child: Text(
                'auth.privacy_policy'.tr(),
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
          ),
          child: const Icon(Icons.restaurant_menu, size: 42, color: AppColors.primary),
        ),
        const SizedBox(height: 12),
        const Text(
          'ChefControl AI',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'auth.admin_subtitle'.tr(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          _buildTabButton(
            title: 'auth.tab_login'.tr(),
            isSelected: _selectedTab == AuthTab.signIn,
            onTap: () => setState(() => _selectedTab = AuthTab.signIn),
          ),
          _buildTabButton(
            title: 'auth.tab_register'.tr(),
            isSelected: _selectedTab == AuthTab.signUp,
            onTap: () => setState(() => _selectedTab = AuthTab.signUp),
          ),
          _buildTabButton(
            title: 'auth.employee_login_tab'.tr(),
            isSelected: _selectedTab == AuthTab.employee,
            onTap: () => setState(() => _selectedTab = AuthTab.employee),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'auth.email_hint'.tr(),
            prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 14),

        // Password
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'auth.password_hint'.tr(),
            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: AppColors.textSecondary,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 8),

        // Forgot Password
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _showForgotPasswordDialog,
            child: Text(
              'auth.forgot_password'.tr(),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Login Button
        _buildActionButton(
          label: 'auth.login_btn'.tr(),
          onPressed: _handleSignIn,
        ),
      ],
    );
  }

  Widget _buildSignUpForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Full Name
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'auth.full_name_hint'.tr(),
            prefixIcon: const Icon(Icons.person_outline, color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 14),

        // Restaurant Name
        TextField(
          controller: _restaurantNameController,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'auth.restaurant_name_hint'.tr(),
            prefixIcon: const Icon(Icons.storefront_outlined, color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 14),

        // Email
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'auth.email_hint'.tr(),
            prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 14),

        // Password
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'auth.password_hint'.tr(),
            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: AppColors.textSecondary,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 20),

        // Sign Up Button
        _buildActionButton(
          label: 'auth.register_btn'.tr(),
          onPressed: _handleSignUp,
        ),
      ],
    );
  }

  Widget _buildEmployeeForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'auth.employee_id_label'.tr(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 6),
              Text(
                'auth.employee_id_hint'.tr(),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _employeeIdController,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
                decoration: InputDecoration(
                  hintText: 'EMP-101',
                  hintStyle: const TextStyle(color: Colors.white24),
                  prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.primary),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        _buildActionButton(
          label: 'auth.employee_login_btn'.tr(),
          onPressed: _handleEmployeeLogin,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
            )
          : Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: Colors.white12, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'auth.or_divider'.tr(),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        const Expanded(child: Divider(color: Colors.white12, thickness: 1)),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Column(
      children: [
        // Google Button
        _buildSocialButton(
          title: 'auth.google_sign_in'.tr(),
          icon: Icons.g_mobiledata,
          iconColor: Colors.redAccent,
          onTap: _handleGoogleSignIn,
        ),
        const SizedBox(height: 12),

        // Apple Button
        _buildSocialButton(
          title: 'auth.apple_sign_in'.tr(),
          icon: Icons.apple,
          iconColor: Colors.white,
          onTap: _handleAppleSignIn,
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required String title,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : onTap,
        icon: Icon(icon, color: iconColor, size: 24),
        label: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: AppColors.surface,
          side: const BorderSide(color: Colors.white12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

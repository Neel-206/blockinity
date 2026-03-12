import 'package:blockinity/Controller/auth_controller.dart';
import 'package:blockinity/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RagisterScreen extends StatefulWidget {
  const RagisterScreen({super.key});

  @override
  State<RagisterScreen> createState() => _RagisterScreenState();
}

class _RagisterScreenState extends State<RagisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  final AuthController _authController = Get.find<AuthController>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        title: Text('Create Account'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          Text(
                            'Join Blockinity',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Enter your details to get started with your new account and explore the world of Blockinity.',
                            style: TextStyle(height: 1.5, fontSize: 13),
                          ),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                _buildInputField(
                                  label: 'Full Name',
                                  hint: 'Enter Your Full Name',
                                  icon: Icons.person_outline_rounded,
                                  controller: _nameController,
                                  maxLength: 30,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your full name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                _buildInputField(
                                  label: 'Email Address',
                                  hint: 'Enter Your Email Address',
                                  icon: Icons.email_outlined,
                                  controller: _emailController,
                                  maxLength: 50,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    final emailRegex = RegExp(
                                      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                                    );
                                    if (!emailRegex.hasMatch(value)) {
                                      return 'Please enter a valid email address';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                _buildInputField(
                                  label: 'Password',
                                  hint: 'Enter Your Password',
                                  icon: Icons.lock_outline_rounded,
                                  isPassword: true,
                                  obscureText: _obscurePassword,
                                  controller: _passwordController,
                                  maxLength: 8,
                                  onToggleVisibility: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a password';
                                    }
                                    if (value.length < 8) {
                                      return 'Password must be at least 8 characters';
                                    }
                                    if (!value.contains(RegExp(r'[A-Z]'))) {
                                      return 'Add at least one uppercase letter';
                                    }
                                    if (!value.contains(RegExp(r'[a-z]'))) {
                                      return 'Add at least one lowercase letter';
                                    }
                                    if (!value.contains(RegExp(r'[0-9]'))) {
                                      return 'Add at least one number';
                                    }
                                    if (!value.contains(
                                      RegExp(r'[!@#$%^&*(),.?":{}|<>]'),
                                    )) {
                                      return 'Add at least one special character';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          SizedBox(
                            height: 60,
                            width: double.infinity,
                            child: Obx(() => ElevatedButton(
                              onPressed: _authController.isLoading.value
                                  ? null
                                  : () {
                                      if (_formKey.currentState!.validate()) {
                                        _authController.register(
                                          name: _nameController.text.trim(),
                                          email: _emailController.text.trim(),
                                          password: _passwordController.text.trim(),
                                        );
                                      }
                                    },
                              child: _authController.isLoading.value
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text(
                                      'CREATE ACCOUNT',
                                      style: TextStyle(fontSize: 16),
                                    ),
                            )),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const Expanded(
                                child: Divider(color: Colors.black12),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  'OR',
                                  style: TextStyle(
                                    color: AppColors.subtitle.withOpacity(0.7),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const Expanded(
                                child: Divider(color: Colors.black12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => _authController.signInWithGoogle(),
                                  child: _buildSocialButton(
                                    icon: Icons.g_mobiledata_rounded,
                                    label: 'Sign Up with Google',
                                    color: Colors.white,
                                    textColor: AppColors.navyTitle,
                                    isGoogle: true,
                                  ),
                                ),
                              ),
                              // const SizedBox(width: 16),
                              // Expanded(
                              //   child: _buildSocialButton(
                              //     icon: Icons.facebook,
                              //     label: 'Facebook',
                              //     color: Colors.white,
                              //     textColor: AppColors.navyTitle,
                              //   ),
                              // ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account?',
                                style: TextStyle(
                                  color: AppColors.subtitle.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Get.back();
                                },
                                child: const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Bottom Terms
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    color: AppColors.subtitle,
                    fontSize: 13,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(
                      text: 'By creating an account, you agree to Cuboria',
                    ),
                    TextSpan(
                      text: 'Terms of Service',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(text: ' & '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    String? Function(String?)? validator,
    bool isPassword = false,
    bool obscureText = false,
    int? maxLength,
    VoidCallback? onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          maxLength: maxLength,
          style: const TextStyle(fontWeight: FontWeight.w600),
          validator: validator,
          decoration: InputDecoration(
            counterText: "", // Hide the character counter for a cleaner look
            hintText: hint,
            prefixIcon: Icon(icon, size: 23),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 23,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    bool isGoogle = false,
  }) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.shade50),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isGoogle)
              const Text(
                'G',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.red,
                ),
              )
            else
              Icon(icon, color: AppColors.facebookBlue),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

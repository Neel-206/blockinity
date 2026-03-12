import 'package:blockinity/Controller/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _keepMeSignedIn = false;
  final AuthController _authController = Get.find<AuthController>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              // Main Card
              Expanded(
                child: Card(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // Tilting Cube Logo
                      _buildLogo(),
                      const SizedBox(height: 24),
                      // Title & Subtitle
                      Text(
                        'Blockinity',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'The Ultimate Puzzle Adventure',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 20),

                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildInputField(
                              label: 'Block Id',
                              hint: 'Your Blockinity Email Id',
                              icon: Icons.person_outline_rounded,
                              controller: _emailController,
                              maxLength: 50,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your Block Id';
                                }
                                final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
                                if (!emailRegex.hasMatch(value)) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            _buildInputField(
                              label: 'Secret Code',
                              hint: '........',
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
                                  return 'Please enter your Secret Code';
                                }
                                if (value.length < 8) {
                                  return 'Secret Code must be at least 8 characters';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Checkbox & Forgot
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _keepMeSignedIn,
                                  onChanged: (val) {
                                    setState(() {
                                      _keepMeSignedIn = val ?? false;
                                    });
                                  },
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  activeColor: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Keep me signed in',
                                style: TextStyle(
                                  color: AppColors.subtitle,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              Get.toNamed('/forgot-password'); 
                            },
                            child: const Text(
                              'Forgot?',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                     const SizedBox(height: 5),

                      // Buttons
                      SizedBox(
                        height: 60,
                        width: double.infinity,
                        child: Obx(() => ElevatedButton(
                          onPressed: _authController.isLoading.value 
                            ? null 
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  _authController.login(
                                    email: _emailController.text.trim(),
                                    password: _passwordController.text.trim(),
                                  );
                                }
                              },
                          child: _authController.isLoading.value 
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('LET\'S PLAY!', style: TextStyle(fontSize: 16)),
                        )),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 60,
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Get.toNamed('/register');
                          },
                          child: const Text('CREATE NEW ACCOUNT', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Social Login Divider
                      Row(
                        children: [
                          const Expanded(child: Divider(color: Colors.black12)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Or play with friends via',
                              style: TextStyle(
                                color: AppColors.subtitle.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider(color: Colors.black12)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Social Buttons
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _authController.signInWithGoogle(),
                              child: _buildSocialButton(
                                icon: Icons.g_mobiledata_rounded,
                                label: 'Google',
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
                    const TextSpan(text: 'By entering Blockinity, you agree to our '),
                    TextSpan(
                      text: 'Terms of Fun',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: ' & '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
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

  Widget _buildLogo() {
    return Transform.rotate(
      angle: 0.2,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.orangeGradientStart, AppColors.orangeGradientEnd],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: CustomPaint(
          size: const Size(60, 60),
          painter: CubeLogoPainter(
            color: Colors.white,
            strokeColor: AppColors.primary,
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
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          maxLength: maxLength,
          style: const TextStyle(fontWeight: FontWeight.w600),
          validator: validator,
          decoration: InputDecoration(
            counterText: "",
            hintText: hint,
            prefixIcon: Icon(icon, size: 23),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
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

class CubeLogoPainter extends CustomPainter {
  final Color color;
  final Color strokeColor;

  CubeLogoPainter({required this.color, required this.strokeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Silhouette of an isometric cube (hexagon)
    final w = size.width;
    final h = size.height;
    final hexPath = Path()
      ..moveTo(w * 0.5, h * 0.1)     // Top
      ..lineTo(w * 0.9, h * 0.3)     // Top Right
      ..lineTo(w * 0.9, h * 0.7)     // Bottom Right
      ..lineTo(w * 0.5, h * 0.9)     // Bottom
      ..lineTo(w * 0.1, h * 0.7)     // Bottom Left
      ..lineTo(w * 0.1, h * 0.3)     // Top Left
      ..close();

    canvas.drawPath(hexPath, paint);

    // Internal "Y" lines representing cube edges
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final yPath = Path()
      ..moveTo(w * 0.5, h * 0.5)
      ..lineTo(w * 0.5, h * 0.2)     // Gap from top
      ..moveTo(w * 0.5, h * 0.5)
      ..lineTo(w * 0.18, h * 0.65)   // Gap from bottom left
      ..moveTo(w * 0.5, h * 0.5)
      ..lineTo(w * 0.82, h * 0.65);  // Gap from bottom right

    canvas.drawPath(yPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
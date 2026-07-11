import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import '../services/firebase_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firebaseService = FirebaseService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isRegisterMode = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isRegisterMode) {
        await _firebaseService.registerAdmin(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        await _firebaseService.signInAdmin(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } on FirebaseException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst(RegExp(r'^Exception: '), '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 700;
    final isDemoMode = !FirebaseService.isInitialized;

    Widget buildLeftPanel({required bool compact}) {
      return Container(
        color: const Color(0xFF0D1117), // Dark Background
        padding: EdgeInsets.all(compact ? 16.0 : 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SignalPulseAnimation(size: compact ? 120 : 200),
            SizedBox(height: compact ? 16 : 32),
            Text(
              'Lyallpur Telecom',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: compact ? 24 : 32,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Broadband Admin Portal',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.tertiary,
                    fontSize: compact ? 14 : 16,
                  ),
            ),
          ],
        ),
      );
    }

    Widget buildRightPanel() {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              color: const Color(0xFF161B22), // Lighter card background for contrast
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(isWide ? 32.0 : 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _isRegisterMode ? 'Create Admin Account' : 'Admin Login',
                        style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isRegisterMode
                            ? 'Fill details to register a new administrator console.'
                            : 'Please verify your credentials to access the console.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[400],
                            ),
                      ),
                      const SizedBox(height: 24),

                      // Error Message Box
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: theme.colorScheme.error),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: theme.colorScheme.error),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: theme.colorScheme.error, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Email Text Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_isLoading,
                        decoration: const InputDecoration(
                          labelText: 'Admin Email',
                          prefixIcon: Icon(Icons.email_outlined),
                          hintText: 'admin@example.com',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Password Text Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),

                      // Confirm Password Field (Only shown in register mode)
                      if (_isRegisterMode) ...[
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          enabled: !_isLoading,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 32),

                      // Action Submit Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleAuth,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(_isRegisterMode ? 'Register' : 'Login'),
                      ),
                      const SizedBox(height: 16),

                      // Switch Form Mode Toggle
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                setState(() {
                                  _isRegisterMode = !_isRegisterMode;
                                  _errorMessage = null;
                                });
                              },
                        child: Text(
                          _isRegisterMode
                              ? 'Already have an account? Login'
                              : 'Don\'t have an account? Register here',
                          style: TextStyle(
                            color: theme.colorScheme.tertiary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Info Notice for Demo Mode
                      if (isDemoMode)
                        Card(
                          color: const Color(0xFF21262D),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.info_outline, size: 18, color: theme.colorScheme.tertiary),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Demo Mode Active',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.tertiary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Firebase is not yet configured on this device. You can log in using these offline test credentials:',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Email: admin@lyallpur.com\nPassword: admin123',
                                  style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: isWide
          ? Row(
              children: [
                Expanded(
                  flex: 5,
                  child: buildLeftPanel(compact: false),
                ),
                Expanded(
                  flex: 5,
                  child: buildRightPanel(),
                ),
              ],
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 260,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFF30363D), width: 1),
                      ),
                    ),
                    child: buildLeftPanel(compact: true),
                  ),
                  buildRightPanel(),
                ],
              ),
            ),
    );
  }
}

// Looping pulses animation widget using custom painter
class SignalPulseAnimation extends StatefulWidget {
  final double size;
  const SignalPulseAnimation({super.key, this.size = 200});

  @override
  State<SignalPulseAnimation> createState() => _SignalPulseAnimationState();
}

class _SignalPulseAnimationState extends State<SignalPulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: SignalPainter(
            animationValue: _controller.value,
            primaryColor: theme.colorScheme.secondary,
            highlightColor: theme.colorScheme.tertiary,
          ),
        );
      },
    );
  }
}

// Custom Painter to draw expanding signal waves radiating outward
class SignalPainter extends CustomPainter {
  final double animationValue;
  final Color primaryColor;
  final Color highlightColor;

  SignalPainter({
    required this.animationValue,
    required this.primaryColor,
    required this.highlightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Draw 3 concentric pulsing waves
    for (int i = 0; i < 3; i++) {
      double phase = (animationValue - (i * 0.33)) % 1.0;
      if (phase < 0) phase += 1.0;

      final radius = 24.0 + (maxRadius - 24.0) * phase;
      final opacity = 1.0 - phase;

      // Draw the wave outline ring
      final strokePaint = Paint()
        ..color = highlightColor.withValues(alpha: opacity * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      canvas.drawCircle(center, radius, strokePaint);

      // Draw a very soft wave fill
      final fillPaint = Paint()
        ..color = primaryColor.withValues(alpha: opacity * 0.04)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, radius, fillPaint);
    }

    // Draw central solid transmitter hub
    final corePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 20, corePaint);

    final borderPaint = Paint()
      ..color = highlightColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, 20, borderPaint);

    // Draw an antenna icon symbol inside the core using lines
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Vertical mast line
    canvas.drawLine(Offset(center.dx, center.dy + 8), Offset(center.dx, center.dy - 6), iconPaint);
    
    // Top dot
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx, center.dy - 8), 2.5, dotPaint);

    // Bottom base support line
    canvas.drawLine(Offset(center.dx - 6, center.dy + 8), Offset(center.dx + 6, center.dy + 8), iconPaint);
  }

  @override
  bool shouldRepaint(covariant SignalPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

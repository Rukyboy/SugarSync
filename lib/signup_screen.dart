import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tips_screen.dart'; // Import the TipsScreen instead of SearchScreen
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );
    _animationController.forward();

    // Add haptic feedback when screen loads
    HapticFeedback.mediumImpact();
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Add haptic feedback
        HapticFeedback.lightImpact();

        UserCredential userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'createdAt': Timestamp.now(),
        });

        print("Account created, proceeding to TipsScreen");

        // Success haptic feedback
        HapticFeedback.mediumImpact();

        // Show success animation before navigating
        await _showSuccessAnimation();

        // Navigate to TipsScreen
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => TipsScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              var begin = Offset(1.0, 0.0);
              var end = Offset.zero;
              var curve = Curves.easeInOutQuart;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(position: animation.drive(tween), child: child);
            },
            transitionDuration: Duration(milliseconds: 800),
          ),
        );
      } on FirebaseAuthException catch (e) {
        // Failure haptic feedback
        HapticFeedback.heavyImpact();

        String errorMessage = 'Sign-up failed. Please try again.';
        if (e.code == 'email-already-in-use') {
          errorMessage = 'The email address is already in use.';
        } else if (e.code == 'weak-password') {
          errorMessage = 'The password is too weak.';
        }
        _showErrorSnackBar(errorMessage);
        setState(() {
          _isLoading = false;
        });
      } catch (e) {
        _showErrorSnackBar('An unexpected error occurred. Please try again.');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showSuccessAnimation() {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: Container(
            height: 150,
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 800),
                builder: (context, value, child) {
                  return Container(
                    width: 100 * value,
                    height: 100 * value,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 60 * value,
                    ),
                  );
                },
                onEnd: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
    // Add light haptic feedback
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    // Get the current theme's brightness
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          SizedBox(height: 20),
                          // Enhanced logo with animation
                          TweenAnimationBuilder(
                            duration: Duration(seconds: 1),
                            tween: Tween<double>(begin: 0, end: 1),
                            builder: (context, double value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Center(
                                  child: Hero(
                                    tag: 'app_logo',
                                    child: Image.asset(
                                      'assets/SugarSync.png',
                                      width: 180,
                                      height: 180,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 30),
                          // Animated welcome text
                          TweenAnimationBuilder(
                            duration: Duration(milliseconds: 800),
                            tween: Tween<double>(begin: -30, end: 0),
                            curve: Curves.easeOutQuad,
                            builder: (context, double value, child) {
                              return Transform.translate(
                                offset: Offset(value, 0),
                                child: Text(
                                  'Hello Beautiful',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? Colors.white : Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 10),
                          TweenAnimationBuilder(
                            duration: Duration(milliseconds: 800),
                            tween: Tween<double>(begin: -20, end: 0),
                            curve: Curves.easeOutQuad,
                            builder: (context, double value, child) {
                              return Transform.translate(
                                offset: Offset(value, 0),
                                child: Text(
                                  'Sign Up to SugarSync',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                    letterSpacing: 0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 40),
                          // Enhanced input fields
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              hintText: 'Your full name',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: Icon(Icons.person),
                              suffixIcon: _nameController.text.isNotEmpty
                                  ? IconButton(
                                icon: Icon(Icons.clear),
                                onPressed: () {
                                  _nameController.clear();
                                  setState(() {});
                                },
                              )
                                  : null,
                              floatingLabelBehavior: FloatingLabelBehavior.auto,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your full name';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'your.email@example.com',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: Icon(Icons.email),
                              suffixIcon: _emailController.text.isNotEmpty
                                  ? IconButton(
                                icon: Icon(Icons.clear),
                                onPressed: () {
                                  _emailController.clear();
                                  setState(() {});
                                },
                              )
                                  : null,
                              floatingLabelBehavior: FloatingLabelBehavior.auto,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: '••••••••',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.grey,
                                ),
                                onPressed: _togglePasswordVisibility,
                              ),
                              floatingLabelBehavior: FloatingLabelBehavior.auto,
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
                          SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                // Handle forgot password
                              },
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 30),
                          // Enhanced sign-up button with gradient
                          SizedBox(
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signUp,
                              child: _isLoading
                                  ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward),
                                ],
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _getButtonColor(context),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.blue.withOpacity(0.4),
                                elevation: 5,
                                shadowColor: Colors.blue.withOpacity(0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 40),
                          // Enhanced login section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                height: 1,
                                width: 60,
                                color: Colors.grey.withOpacity(0.3),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                child: Text(
                                  'OR',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Container(
                                height: 1,
                                width: 60,
                                color: Colors.grey.withOpacity(0.3),
                              ),
                            ],
                          ),
                          SizedBox(height: 30),
                          // Social login options
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildSocialLoginButton(
                                icon: Icons.g_mobiledata,
                                color: Colors.red,
                                onPressed: () {
                                  // Handle Google login
                                  HapticFeedback.lightImpact();
                                },
                              ),
                              SizedBox(width: 20),
                              _buildSocialLoginButton(
                                icon: Icons.facebook,
                                color: Colors.blue[800]!,
                                onPressed: () {
                                  // Handle Facebook login
                                  HapticFeedback.lightImpact();
                                },
                              ),
                              SizedBox(width: 20),
                              _buildSocialLoginButton(
                                icon: Icons.apple,
                                color: Colors.black,
                                onPressed: () {
                                  // Handle Apple login
                                  HapticFeedback.lightImpact();
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 40),
                          Center(
                            child: TextButton(
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                // Navigate to login screen
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      var begin = Offset(0.0, 1.0);
                                      var end = Offset.zero;
                                      var curve = Curves.easeInOut;
                                      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                      return SlideTransition(position: animation.drive(tween), child: child);
                                    },
                                    transitionDuration: Duration(milliseconds: 500),
                                  ),
                                );
                              },
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(fontSize: 16),
                                  children: [
                                    TextSpan(
                                      text: 'Already have an account? ',
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Login',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSocialLoginButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    // Check if it's the Apple icon and adjust color based on theme
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final iconColor = (icon == Icons.apple && isDarkMode) ? Colors.white : color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(50),
        child: Ink(
          height: 55,
          width: 55,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Icon(
            icon,
            color: iconColor, // Use the adjusted color
            size: 30,
          ),
        ),
      ),
    );
  }

  // Helper method to determine button color
  Color _getButtonColor(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    if (brightness == Brightness.dark) {
      return Colors.blue[700]!; // Dark mode color
    } else if (theme.colorScheme.background == Colors.white) {
      return theme.primaryColor; // Default primary color for white background
    } else {
      return theme.colorScheme.secondary; // Use secondary color for other themes
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
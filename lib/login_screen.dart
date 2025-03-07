import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'search_screen.dart';
import 'signup_screen.dart'; // Make sure to create this import

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Google Sign-In instance
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );

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

  Future<void> _login(BuildContext context) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Enhanced validation
    if (email.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      _showErrorSnackBar('Please enter a valid email address');
      return;
    }

    if (password.isEmpty) {
      _showErrorSnackBar('Please enter your password');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Add haptic feedback
      HapticFeedback.lightImpact();

      // Sign in with Firebase Auth
      final UserCredential userCredential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // If login is successful, navigate to the SearchScreen
      if (userCredential.user != null && mounted) {
        // Success haptic feedback
        HapticFeedback.mediumImpact();

        // Show success animation before navigating
        await _showSuccessAnimation();

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => SearchScreen(),
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
      }
    } on FirebaseAuthException catch (e) {
      // Failure haptic feedback
      HapticFeedback.heavyImpact();

      // Enhanced error messages
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email. Need to create one?';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled. Please contact support.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Please try again later.';
          break;
        default:
          errorMessage = 'Login failed (${e.code}). Please try again.';
      }
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      _showErrorSnackBar('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Google Sign-In method
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Trigger the Google Sign-In process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Obtain the Google Sign-In authentication credentials
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credentials
      final UserCredential authResult =
      await FirebaseAuth.instance.signInWithCredential(credential);

      // If login is successful, navigate to the SearchScreen
      if (authResult.user != null && mounted) {
        // Success haptic feedback
        HapticFeedback.mediumImpact();

        // Show success animation before navigating
        await _showSuccessAnimation();

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => SearchScreen(),
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
      }
    } catch (error) {
      // Failure haptic feedback
      HapticFeedback.heavyImpact();

      // Show error message
      _showErrorSnackBar('Google Sign-In failed. Please try again.');

      print('Google Sign-In Error: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showSuccessAnimation() async {
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
                  Future.delayed(Duration(milliseconds: 700), () {
                    Navigator.of(context).pop();
                  });
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

  void _handleForgotPassword() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reset Password',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 15),
              Text(
                'Enter your email address and we\'ll send you a link to reset your password.',
                style: TextStyle(color: Colors.grey[700]),
              ),
              SizedBox(height: 20),
              TextField(
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Handle password reset
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Password reset link sent! Check your email.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: Text('Send Reset Link'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 15),
            ],
          ),
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
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: 500, // Limit max width for larger screens
                        ),
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
                                    'Welcome Back',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? Colors.white : Colors.black87,
                                    ),
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
                                    'Login to SugarSync',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: 40),
                            // Enhanced input fields with responsive design
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              onChanged: (value) {
                                setState(() {});  // Rebuild to update button state
                              },
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
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 12
                                ),
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.2,
                              ),
                            ),
                            SizedBox(height: 20),
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onChanged: (value) {
                                setState(() {});  // Rebuild to update button state
                              },
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: '••••••••',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.grey,
                                  ),
                                  onPressed: _togglePasswordVisibility,
                                ),
                                floatingLabelBehavior: FloatingLabelBehavior.auto,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 12
                                ),
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.2,
                              ),
                              onSubmitted: (_) => _login(context),
                            ),
                            SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _handleForgotPassword,
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
                            // Enhanced login button with gradient
                            SizedBox(
                              height: 55,
                              child: ElevatedButton(
                                onPressed: (_isLoading ||
                                    _emailController.text.isEmpty ||
                                    _passwordController.text.isEmpty)
                                    ? null
                                    : () => _login(context),
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
                                      'Login',
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
                                  backgroundColor: Colors.blue,
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
                            // Enhanced sign-up section
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
                                    _signInWithGoogle();
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
                                  // Navigate to sign-up screen
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation, secondaryAnimation) => SignUpScreen(),
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
                                        text: 'Don\'t have an account? ',
                                        style: TextStyle(
                                          color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'Sign Up',
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
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
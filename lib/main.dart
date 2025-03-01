import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'welcome_screen.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:intl/intl.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with error handling
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print("Error initializing Firebase: $e");
  }

  // Run the app
  runApp(MyApp());
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  MaterialColor _accentColor = Colors.blue;
  MaterialColor _previousAccentColor = Colors.blue; // Track previous color

  ThemeMode get themeMode => _themeMode;
  MaterialColor get accentColor => _accentColor;
  MaterialColor get previousAccentColor => _previousAccentColor;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setAccentColor(MaterialColor color) {
    _previousAccentColor = _accentColor;
    _accentColor = color;
    notifyListeners();
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ThemeProvider _themeProvider = ThemeProvider();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeProvider,
      builder: (context, _) {
        return MaterialApp(
          title: 'SugarSync',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            fontFamily: 'Quicksand',
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.grey[50],
            colorScheme: ColorScheme.fromSeed(
              seedColor: _themeProvider.accentColor,
              secondary: _themeProvider.accentColor,
              tertiary: _themeProvider.accentColor.shade200,
              // Removed deprecated 'background' property
              surface: Colors.white,
              onSurface: Colors.grey[900]!,
              // Added surfaceVariant as a replacement
              surfaceContainerHighest: Colors.grey[50]!,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.white,
              elevation: 1,
              foregroundColor: Colors.grey[900],
              iconTheme: IconThemeData(color: _themeProvider.accentColor),
            ),
            cardTheme: CardTheme(
              elevation: 2,
              margin: EdgeInsets.all(8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            buttonTheme: ButtonThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: _themeProvider.accentColor,
              elevation: 4,
            ),
            textTheme: TextTheme(
              titleLarge: TextStyle( // Replaces headline6
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[900],
              ),
              bodyLarge: TextStyle( // Replaces bodyText1
                fontSize: 16,
                color: Colors.grey[800],
              ),
              bodyMedium: TextStyle( // Replaces bodyText2
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            fontFamily: 'Quicksand',
            scaffoldBackgroundColor: Colors.black,
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            colorScheme: ColorScheme.dark(
              primary: _themeProvider.accentColor,
              secondary: _themeProvider.accentColor,
              tertiary: _themeProvider.accentColor.shade700,
              surface: Colors.black,
              onSurface: Colors.white,
            ),
          ),
          themeMode: _themeProvider.themeMode,
          home: MainScreen(themeProvider: _themeProvider),
        );
      },
    );
  }
}

// Create a new AnimatedThemeColor widget to animate between colors
class AnimatedThemeColor extends StatefulWidget {
  final MaterialColor startColor;
  final MaterialColor endColor;
  final Duration duration;
  final Widget Function(Color color) builder;

  AnimatedThemeColor({
    required this.startColor,
    required this.endColor,
    this.duration = const Duration(milliseconds: 300),
    required this.builder,
  });

  @override
  _AnimatedThemeColorState createState() => _AnimatedThemeColorState();
}

class _AnimatedThemeColorState extends State<AnimatedThemeColor> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _colorAnimation = ColorTween(
      begin: widget.startColor,
      end: widget.endColor,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedThemeColor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.endColor != oldWidget.endColor) {
      _colorAnimation = ColorTween(
        begin: oldWidget.endColor,
        end: widget.endColor,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ));
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return widget.builder(_colorAnimation.value ?? widget.endColor);
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  final ThemeProvider themeProvider;

  MainScreen({required this.themeProvider});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Timer _clockTimer;
  String _currentTime = '';

  @override
  void initState() {
    super.initState();

    // Initialize time
    _updateTime();

    // Update time every second
    _clockTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      _updateTime();
    });

    // Initialize animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Create fade animation
    _fadeAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // Create scale animation
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.2, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    // Start the animation
    _controller.forward();
  }

  void _updateTime() {
    setState(() {
      _currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _clockTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Define theme colors for light and dark modes
    final primaryGradientStart = isDarkMode ? Color(0xFF1A1A2E) : Color(0xFFF5F5F5);
    final primaryGradientEnd = isDarkMode ? Color(0xFF121212) : Color(0xFFE0E0E0);
    final accentColor = widget.themeProvider.accentColor;
    final previousAccentColor = widget.themeProvider.previousAccentColor;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text("SugarSync"),
            SizedBox(width: 16),
            AnimatedThemeColor(
              startColor: previousAccentColor,
              endColor: accentColor,
              builder: (color) => Text(
                _currentTime,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: color.withOpacity(0.8),
                ),
              ),
            ),
          ],
        ),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: AnimatedThemeColor(
              startColor: previousAccentColor,
              endColor: accentColor,
              builder: (color) => Icon(Icons.more_vert, color: color),
            ),
            onSelected: (value) {
              if (value == 'toggle_theme') {
                widget.themeProvider.toggleTheme();
              } else if (value == 'select_color') {
                _showColorPickerDialog();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle_theme',
                child: Row(
                  children: [
                    Icon(
                      isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    SizedBox(width: 8),
                    Text(isDarkMode ? 'Light Theme' : 'Dark Theme'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'select_color',
                child: Row(
                  children: [
                    AnimatedThemeColor(
                      startColor: previousAccentColor,
                      endColor: accentColor,
                      builder: (color) => Icon(
                        Icons.color_lens,
                        color: color,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text('Theme Colors'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryGradientStart, primaryGradientEnd],
          ),
        ),
        child: Stack(
          children: [
            // Background particles with animated color changes
            ...List.generate(12, (index) => _buildAnimatedParticle(
              index,
              screenSize,
              accentColor,
              previousAccentColor,
            )),

            // Add subtle wave effect to the background with theme color animation
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedThemeColor(
                startColor: previousAccentColor,
                endColor: accentColor,
                duration: Duration(milliseconds: 800),
                builder: (color) => _WaveAnimation(
                  height: 100,
                  color: color.withOpacity(0.05),
                ),
              ),
            ),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Modified logo section - FIXED
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: AnimatedThemeColor(
                            startColor: previousAccentColor,
                            endColor: accentColor,
                            builder: (color) => Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.2),
                                    blurRadius: 15,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/SugarSync.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 40),

                  // Animated welcome text with shadow and color transition
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: AnimatedBuilder(
                      animation: _scaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: AnimatedThemeColor(
                            startColor: previousAccentColor,
                            endColor: accentColor,
                            duration: Duration(milliseconds: 600),
                            builder: (color) => Text(
                              'SugarSync',
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                color: isDarkMode ? Colors.white : Colors.grey[900],
                                shadows: [
                                  Shadow(
                                    color: color.withOpacity(0.3),
                                    blurRadius: 5,
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  SizedBox(height: 10),

                  // Typewriter text effect with color animation
                  AnimatedThemeColor(
                    startColor: previousAccentColor,
                    endColor: accentColor,
                    builder: (color) => _TypewriterText(
                      text: 'Seamlessly sync your life',
                      startDelay: const Duration(milliseconds: 1000),
                      typingSpeed: const Duration(milliseconds: 60),
                      style: TextStyle(
                        fontSize: 18,
                        color: color.withOpacity(0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                  SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedThemeColor(
        startColor: previousAccentColor,
        endColor: accentColor,
        duration: Duration(milliseconds: 500),
        builder: (color) => _PulsingFloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => WelcomeScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  var begin = Offset(1.0, 0.0);
                  var end = Offset.zero;
                  var curve = Curves.easeInOut;
                  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                  var offsetAnimation = animation.drive(tween);

                  return SlideTransition(
                    position: offsetAnimation,
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                transitionDuration: const Duration(milliseconds: 600),
              ),
            );
          },
          icon: Icons.arrow_forward,
          backgroundColor: color.withOpacity(0.9),
          pulseIntensity: 0.1,
        ),
      ),
    );
  }

  // Update the _buildAnimatedParticle method to handle color transitions
  Widget _buildAnimatedParticle(int index, Size screenSize, MaterialColor baseColor, MaterialColor previousColor) {
    final random = math.Random(index);
    final size = random.nextDouble() * 10 + 3;
    final initialPosition = Offset(
      random.nextDouble() * screenSize.width,
      random.nextDouble() * screenSize.height,
    );

    // Use AnimatedThemeColor to transition particle colors
    return AnimatedThemeColor(
      startColor: previousColor,
      endColor: baseColor,
      duration: Duration(milliseconds: 800 + (random.nextInt(800))), // Staggered animations
      builder: (color) {
        final particleColor = color.withOpacity(random.nextDouble() * 0.2 + 0.05);

        return _FloatingParticle(
          size: size,
          initialPosition: initialPosition,
          duration: Duration(seconds: random.nextInt(8) + 8),
          opacity: random.nextDouble() * 0.2 + 0.05,
          moveDistance: 30.0,
          color: particleColor,
        );
      },
    );
  }

  void _showColorPickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose Theme Color'),
          content: Container(
            width: double.minPositive,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildColorOption(Colors.blue),
                _buildColorOption(Colors.purple),
                _buildColorOption(Colors.green),
                _buildColorOption(Colors.orange),
                _buildColorOption(Colors.red),
                _buildColorOption(Colors.teal),
                _buildColorOption(Colors.pink),
                _buildColorOption(Colors.indigo),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildColorOption(MaterialColor color) {
    final isSelected = widget.themeProvider.accentColor == color;

    return GestureDetector(
      onTap: () {
        widget.themeProvider.setAccentColor(color);
        Navigator.of(context).pop();
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? color.withOpacity(0.4) : Colors.black.withOpacity(0.2),
              blurRadius: isSelected ? 8 : 5,
              spreadRadius: isSelected ? 2 : 0,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: isSelected
            ? Center(
          child: Icon(
            Icons.check,
            color: Colors.white,
            size: 24,
          ),
        )
            : null,
      ),
    );
  }
}

class _WaveAnimation extends StatefulWidget {
  final double height;
  final Color color;

  _WaveAnimation({
    required this.height,
    required this.color,
  });

  @override
  _WaveAnimationState createState() => _WaveAnimationState();
}

class _WaveAnimationState extends State<_WaveAnimation> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _WavePainter(
            animationValue: _controller.value,
            color: widget.color,
          ),
          child: SizedBox(
            height: widget.height,
            width: MediaQuery.of(context).size.width,
          ),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  _WavePainter({
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final waveHeight = size.height * 0.2;
    final waveWidth = size.width * 0.5;

    path.moveTo(0, size.height);

    for (double i = 0; i < size.width; i++) {
      final x = i;
      final waveOffset = math.sin((i / waveWidth) + animationValue * math.pi * 2) * waveHeight;
      final secondaryWaveOffset = math.sin((i / (waveWidth * 0.8)) + animationValue * math.pi * 2.5) * (waveHeight * 0.5);
      final y = size.height - waveHeight + waveOffset + secondaryWaveOffset;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.color != color;
  }
}

class _PulsingContainer extends StatefulWidget {
  final Color color;
  final double size;

  _PulsingContainer({
    required this.color,
    required this.size,
  });

  @override
  _PulsingContainerState createState() => _PulsingContainerState();
}

class _PulsingContainerState extends State<_PulsingContainer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _animation = Tween<double>(begin: 0.8, end: 1.1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size * _animation.value,
          height: widget.size * _animation.value,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

class _FloatingParticle extends StatefulWidget {
  final double size;
  final Offset initialPosition;
  final Duration duration;
  final double opacity;
  final double moveDistance;
  final Color color;

  _FloatingParticle({
    required this.size,
    required this.initialPosition,
    required this.duration,
    required this.opacity,
    this.moveDistance = 50.0,
    required this.color,
  });

  @override
  _FloatingParticleState createState() => _FloatingParticleState();
}

class _FloatingParticleState extends State<_FloatingParticle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _sizeAnimation;

  @override
  void initState() {
    super.initState();

    final random = math.Random();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // Position animation
    _positionAnimation = Tween<Offset>(
      begin: widget.initialPosition,
      end: Offset(
        widget.initialPosition.dx + (random.nextDouble() * widget.moveDistance - widget.moveDistance/2),
        widget.initialPosition.dy + (random.nextDouble() * widget.moveDistance - widget.moveDistance/2),
      ),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Add subtle opacity pulse
    _opacityAnimation = Tween<double>(
      begin: widget.opacity,
      end: widget.opacity * 1.5,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Add subtle size animation
    _sizeAnimation = Tween<double>(
      begin: widget.size * 0.8,
      end: widget.size * 1.2,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: _positionAnimation.value.dx,
          top: _positionAnimation.value.dy,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              width: _sizeAnimation.value,
              height: _sizeAnimation.value,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.3),
                    blurRadius: 2,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PulsingFloatingActionButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final Color backgroundColor;
  final double pulseIntensity;

  _PulsingFloatingActionButton({
    required this.onPressed,
    required this.icon,
    required this.backgroundColor,
    this.pulseIntensity = 0.2,
  });

  @override
  _PulsingFloatingActionButtonState createState() => _PulsingFloatingActionButtonState();
}

class _PulsingFloatingActionButtonState extends State<_PulsingFloatingActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Scale animation
    double minScale = 1.0;
    double maxScale = 1.0 + widget.pulseIntensity;

    _scaleAnimation = Tween<double>(begin: minScale, end: maxScale).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Add subtle rotation
    _rotateAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotateAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: FloatingActionButton(
              onPressed: widget.onPressed,
              backgroundColor: widget.backgroundColor,
              child: Icon(widget.icon),
              elevation: 4,
            ),
          ),
        );
      },
    );
  }
}

class _TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration startDelay;
  final Duration typingSpeed;

  _TypewriterText({
    required this.text,
    required this.style,
    this.startDelay = const Duration(milliseconds: 0),
    this.typingSpeed = const Duration(milliseconds: 100),
  });

  @override
  _TypewriterTextState createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText> with SingleTickerProviderStateMixin {
  late String _displayText;
  late int _charCount;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _displayText = '';
    _charCount = 0;

    // Start typewriter effect after delay
    Future.delayed(widget.startDelay, () {
      if (mounted) {
        _timer = Timer.periodic(widget.typingSpeed, (timer) {
          if (_charCount < widget.text.length) {
            setState(() {
              _charCount++;
              _displayText = widget.text.substring(0, _charCount);
            });
          } else {
            _timer?.cancel();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayText,
      style: widget.style,
    );
  }
}
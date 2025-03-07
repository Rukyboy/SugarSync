import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Check if the screen is in landscape mode
          bool isLandscape = constraints.maxWidth > constraints.maxHeight;

          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/food.jpeg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.5),
                  BlendMode.darken,
                ),
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // Conditionally resize logo based on orientation
                    Image.asset(
                      'assets/SugarSync.png',
                      width: isLandscape ? 150 : 300,
                      height: isLandscape ? 150 : 300,
                    ),
                    SizedBox(height: isLandscape ? 10 : 20),
                    Text(
                      'Welcome to',
                      style: TextStyle(
                        fontSize: isLandscape ? 18 : 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                    SizedBox(height: isLandscape ? 5 : 10),
                    Text(
                      'SugarSync',
                      style: TextStyle(
                        fontSize: isLandscape ? 24 : 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: isLandscape ? 10 : 20),
                    Text(
                      'BY RUKSHAN PERERA',
                      style: TextStyle(
                        fontSize: isLandscape ? 12 : 16,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                    SizedBox(height: isLandscape ? 20 : 40),
                    Wrap(
                      spacing: 20,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            // Navigate to Sign Up screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => SignUpScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: isLandscape ? 30 : 50,
                              vertical: isLandscape ? 10 : 15,
                            ),
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          ),
                          child: Text('Sign Up'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // Navigate to Login screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => LoginScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: isLandscape ? 30 : 50,
                              vertical: isLandscape ? 10 : 15,
                            ),
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          ),
                          child: Text('Login'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
import 'package:carpool_flutter/authentication/forgot_password.dart';
import 'package:carpool_flutter/authentication/login_screen.dart';
import 'package:carpool_flutter/authentication/signup_screen.dart';
import 'package:carpool_flutter/authentication/splash_screen.dart';
import 'package:carpool_flutter/pages/cart_page.dart';
import 'package:carpool_flutter/pages/history_page.dart';
import 'package:carpool_flutter/pages/home_page.dart';
import 'package:carpool_flutter/pages/profile_page.dart';
import 'package:carpool_flutter/pages/search_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'authentication/verifyEmail_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Permission.locationWhenInUse.isDenied.then((value){
    if(value){
      Permission.locationWhenInUse.request();
    }
  });

  runApp(const MyApp());

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomePage(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/forgotPassword': (context) => const ForgotPasswordScreen(),
        '/verifyEmail': (context) => const VerifyEmail(),
        '/cartPage': (context) => const CartPage(),
        '/history': (context) => const HistoryPage(),
        '/search': (context) => const SearchPage(),
        '/profile': (context) => const ProfilePage(),
      },
      initialRoute: '/',
    );
  }
}

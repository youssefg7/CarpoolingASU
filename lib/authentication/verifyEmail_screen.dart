import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../Utilities/utils.dart';

class VerifyEmail extends StatefulWidget {
  const VerifyEmail({super.key});

  @override
  State<VerifyEmail> createState() => _VerifyEmailState();
}

class _VerifyEmailState extends State<VerifyEmail> {
  bool isEmailVerified = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.currentUser?.sendEmailVerification();
    timer = Timer.periodic(const Duration(seconds: 3), (_) => checkEmailVerified());
  }

  checkEmailVerified() async {
    await FirebaseAuth.instance.currentUser?.reload();

    setState(() {
      isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;
    });

    if (isEmailVerified) {
      Utils.displayToast("Email Verified Successfully, Login now!", context);
      Navigator.pushReplacementNamed(context, "/login");
      timer?.cancel();
    }
  }
  resendEmail(){
    FirebaseAuth.instance.currentUser?.sendEmailVerification();
    Utils.displayToast("Email resent, Check your inbox and spam.", context);
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        body: ListView(children: [
          Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(40),
                child: Image(
                  image: AssetImage("assets/images/logo.png"),
                ),
              ),
              const Text(
                "ASU FE Carpooling Community",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                "Check Your Email",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                    children: [
                      const Text(
                        "We have sent a verification link to your email, please verify your email to continue."
                            "\n\n If you didn't receive the email, please check your spam folder."
                            "\n\n If you want us to resend the email, click the button below.",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                          onPressed: () {
                            Utils.checkInternetConnection(context);
                            resendEmail();
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(32)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 42, vertical: 20)),
                          child: const Text("Resend Verification Link",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              )))
                    ],
                  ),
                ),
            ],
          ),
        ]),
      ),
    );
  }
}

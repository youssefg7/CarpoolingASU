import 'package:carpool_flutter/Utilities/global_var.dart';
import 'package:carpool_flutter/Utilities/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/loading_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _passwordVisible = false;
  bool _submitted = false;

  loginUser() async {
    setState(() => _submitted = true);
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) =>
            LoadingDialog(messageText: "Logging in.."),
      );

      final User? userFirebase = (await FirebaseAuth.instance
              .signInWithEmailAndPassword(
        email: "${emailTextEditingController.text.trim()}@eng.asu.edu.eg",
        password: passwordTextEditingController.text.trim(),
      )
              .catchError((error) {
        Navigator.pop(context);
        Utils.displaySnack(error.toString(), context);
      }))
          .user;

      if (!context.mounted) return;
      Navigator.pop(context);

      if (userFirebase != null) {
        DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(userFirebase.uid);

        try {
          DocumentSnapshot snapshot = await userRef.get();

          if(snapshot.exists) {
            username = snapshot.get("username");
            if (!FirebaseAuth.instance.currentUser!.emailVerified) {
              Utils.displayToast("Email not verified, please verify first.", context);
              Navigator.pushReplacementNamed(context, "/verifyEmail");
            } else {
              Navigator.pushReplacementNamed(context, "/home");
            }
          } else {
            FirebaseAuth.instance.signOut();
            Utils.displaySnack(
                "Email not registered. Please create an account!", context);
          }
        }catch(e) {
          FirebaseAuth.instance.signOut();
          Utils.displaySnack(
              "Email not registered. Please create an account!", context);
        }
      }
    }
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
                "Login as a User",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: emailTextEditingController,
                                keyboardType: TextInputType.text,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(7),
                                ],
                                decoration: InputDecoration(
                                  labelText: "FE ASU ID",
                                  labelStyle: const TextStyle(fontSize: 16),
                                  prefixIcon: const Icon(Icons.alternate_email),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(40),
                                    borderSide: const BorderSide(
                                      width: 2,
                                      color: Colors.purple,
                                    ),
                                  ),
                                ),
                                style: const TextStyle(color: Colors.grey),
                                autovalidateMode: _submitted
                                    ? AutovalidateMode.onUserInteraction
                                    : AutovalidateMode.disabled,
                                validator: (value) {
                                  RegExp idPattern = RegExp(
                                      r"^[1-9][0-9][0PQTWEX][0-9]{4}",
                                      caseSensitive: false);
                                  if (value!.trim().isEmpty) {
                                    return "Please enter your FE ASU ID.";
                                  } else if (!idPattern
                                      .hasMatch(value.trim())) {
                                    return "Please enter a valid FE ASU ID.";
                                  }
                                },
                              ),
                            ),
                            const Text(
                              "@eng.asu.edu.eg",
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                          ]),
                      const SizedBox(
                        height: 10,
                      ),
                      TextFormField(
                          controller: passwordTextEditingController,
                          obscureText: !_passwordVisible,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            labelText: "Password",
                            labelStyle: const TextStyle(fontSize: 16),
                            prefixIcon: const Icon(Icons.password),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _passwordVisible = !_passwordVisible;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide: const BorderSide(
                                width: 2,
                                color: Colors.purple,
                              ),
                            ),
                          ),
                          style: const TextStyle(color: Colors.grey),
                          autovalidateMode: _submitted
                              ? AutovalidateMode.onUserInteraction
                              : AutovalidateMode.disabled,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return "Please enter a password.";
                            } else if (value.trim().length < 6) {
                              return "Password must be at least 6 characters.";
                            } else if (value.trim().length > 32) {
                              return "Password cannot be more than 32 characters.";
                            }
                          }),
                      const SizedBox(
                        height: 32,
                      ),
                      ElevatedButton(
                          onPressed: () {
                            Utils.checkInternetConnection(context);
                            loginUser();
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(32)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 146, vertical: 20)),
                          child: const Text("Login",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              )))
                    ],
                  ),
                ),
              ),
              TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/forgotPassword');
                  },
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  )),
              TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/signup');
                  },
                  child: const Text(
                    "Don't have an account? Sign Up Here!",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ))
            ],
          ),
        ]),
      ),
    );
  }
}

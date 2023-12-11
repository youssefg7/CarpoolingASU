import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Utilities/utils.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {

  TextEditingController emailTextEditingController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitted = false;

  submitRequest(){
    setState(() => _submitted = true);
    if (_formKey.currentState!.validate()) {
      FirebaseAuth.instance
          .sendPasswordResetEmail(email: "${emailTextEditingController.text.trim()}@eng.asu.edu.eg")
          .then((value) {
              Utils.displaySnack("Email sent, Check your inbox or spam for password reset link.", context);
            
      }).onError((error, stackTrace) {
        Utils.displaySnack("Error occured: \n ${error.toString()}", context);
      });
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
              const SizedBox(
                  height: 15
              ),
              const Text(
                "Forgot Password?",
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
                                  RegExp idPattern = RegExp(r"^[1-9][0-9][0PQTWEX][0-9]{4}", caseSensitive: false);
                                  if(value!.trim().isEmpty){
                                    return "Please enter your FE ASU ID.";
                                  } else if(!idPattern.hasMatch(value.trim())){
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
                      ElevatedButton(
                          onPressed: () {
                            Utils.checkInternetConnection(context);
                            submitRequest();
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(32)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 42, vertical: 20)),
                          child: const Text(
                              "Send Reset Password Link",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              )
                          )
                      )
                    ],
                  ),
                ),
              ),
              TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: const Text(
                    "Successfully reset your password? Login Here!",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  )),
              TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/signup');
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
